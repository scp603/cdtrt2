#!/usr/bin/env bash
# vandalize-bashrc.sh — appends RT ASCII art to every .bashrc on the system
#
# Usage:
#   sudo ./vandalize-bashrc.sh install
#   sudo ./vandalize-bashrc.sh remove
#   sudo ./vandalize-bashrc.sh status

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }

WHITELIST="greyteam|ansible|scoring"
MARKER="# rt-vandalize"

cmd_install() {
    local count=0
    hdr "Vandalizing .bashrc files"
    while IFS= read -r bashrc; do
        [[ -n "$WHITELIST" && "$bashrc" =~ $WHITELIST ]] && continue
        grep -qF "$MARKER" "$bashrc" 2>/dev/null && continue   # already done
        cat >> "$bashrc" <<'BLOCK'
# rt-vandalize
echo '
    ____
  _|___ \
 (_) __) |
    |__ <
  _ ___) |
 (_)____/
'
BLOCK
        (( count++ )) || true
        info "Vandalized: $bashrc"
    done < <(find / -name ".bashrc" 2>/dev/null)
    info "Done — $count file(s) vandalized"
}

cmd_remove() {
    local count=0
    hdr "Restoring .bashrc files"
    while IFS= read -r bashrc; do
        grep -qF "$MARKER" "$bashrc" 2>/dev/null || continue
        # strip from marker line through the closing ' of the echo block
        sed -i "/^${MARKER}$/,/^'$/{/^${MARKER}$/,/^'$/d}" "$bashrc"
        (( count++ )) || true
        info "Cleaned: $bashrc"
    done < <(find / -name ".bashrc" 2>/dev/null)
    info "Done — $count file(s) cleaned"
}

cmd_status() {
    hdr "Vandalized .bashrc files"
    local count=0
    while IFS= read -r bashrc; do
        grep -qF "$MARKER" "$bashrc" 2>/dev/null || continue
        info "VANDALIZED  $bashrc"
        (( count++ )) || true
    done < <(find / -name ".bashrc" 2>/dev/null)
    [[ $count -eq 0 ]] && warn "No vandalized .bashrc files found" || info "Total: $count"
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: $0 install|remove|status" ;;
esac
