#!/usr/bin/env bash
# teardown.sh — remove ALL installed tools from all Linux hosts
#
# Runs remove on every tool in safe order (sabotage first so restored tools
# don't interfere, persistence last). Continues even if individual removes fail.
#
# Usage:
#   ./teardown.sh [OPTIONS]
#
# Options:
#   -u, --user USER      SSH username (default: root)
#   -P, --port PORT      SSH port (default: 22)
#       --no-sudo        Don't use sudo (already root)
#   -j, --jobs N         Parallel jobs (default: 9)
#       --dry-run        Preview commands without running
#   -h, --help           Show this help

set -uo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASS="${RT_DIR}/mass-deploy.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}━━  $*  ━━${NC}\n"; }

SSH_USER="root"
SSH_PASS=""
SSH_PORT="22"
NO_SUDO=0
MAX_JOBS=9
DRY_RUN=0

usage() {
    sed -n '/^# Usage:/,/^[^#]/{/^#/{s/^# \?//;p};/^[^#]/q}' "$0"
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user)      SSH_USER="$2";  shift 2 ;;
        -P|--port)      SSH_PORT="$2";  shift 2 ;;
        --no-sudo)      NO_SUDO=1;      shift   ;;
        -j|--jobs)      MAX_JOBS="$2";  shift 2 ;;
        --dry-run)      DRY_RUN=1;      shift   ;;
        -h|--help)      usage 0                  ;;
        *) err "Unknown option: $1"; usage 1     ;;
    esac
done

read -rsp $'\033[0;36m[?]\033[0m SSH password: ' SSH_PASS
echo
export RT_SSH_PASS="$SSH_PASS"
export RT_SUDO_PASS="$SSH_PASS"

MASS_OPTS=(-u "$SSH_USER" -j "$MAX_JOBS")
[[ "$SSH_PORT" != "22" ]] && MASS_OPTS+=(-P "$SSH_PORT")
[[ $NO_SUDO -eq 1 ]] && MASS_OPTS+=(--no-sudo)
[[ $DRY_RUN -eq 1 ]] && MASS_OPTS+=(--dry-run)

WAVE_LABELS=()
WAVE_STATUS=()

wave() {
    local tool="$1" action="${2:-remove}"
    hdr "Removing: ${tool}"
    local rc=0
    "$MASS" "${MASS_OPTS[@]}" "$tool" "$action" || rc=$?
    WAVE_LABELS+=("$tool")
    [[ $rc -eq 0 ]] && WAVE_STATUS+=("OK") || WAVE_STATUS+=("FAIL")
}

# ── confirm ───────────────────────────────────────────────────────────────────
echo -e "${RED}${BOLD}"
echo "  ████████╗███████╗ █████╗ ██████╗ ██████╗  ██████╗ ██╗    ██╗███╗   ██╗"
echo "  ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║    ██║████╗  ██║"
echo "     ██║   █████╗  ███████║██████╔╝██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║"
echo "     ██║   ██╔══╝  ██╔══██║██╔══██╗██║  ██║██║   ██║██║███╗██║██║╚██╗██║"
echo "     ██║   ███████╗██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║"
echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝"
echo -e "${NC}"
warn "This will run REMOVE on every tool across ALL Linux hosts."
warn "Ctrl-C within 5 seconds to abort."
echo
for i in 5 4 3 2 1; do
    printf "\r  ${YELLOW}[!]${NC} Starting in %d..." "$i"
    sleep 1
done
echo -e "\r  ${GREEN}[+]${NC} Starting teardown...   "
echo

# ── removal order ─────────────────────────────────────────────────────────────
# Sabotage first — restore networking tools so subsequent removes can reach out,
# and restore sudo so privileged removes work. Then chaos, then persistence.

# 1. Restore networking (break-net-tools last installed, first removed)
wave break-net-tools   remove
wave no-apt            remove

# 2. Restore audit/selinux visibility
wave no-audit          remove
wave no-selinux        remove

# 3. Remove sabotage
wave sudo-binary       remove
wave lock-busybox      remove

# 4. Remove network tricks
wave sinkhole          remove
wave pihole-sinkhole   remove   # best-effort; pihole-sinkhole has no remove but won't error

# 5. Remove chaos
wave the-toucher       remove
wave vandalize-bashrc  remove
wave alias-bashrc      remove
wave compromise-who    remove

# 6. Remove auth backdoors
wave pam-backdoor      remove
wave infinite-users    remove

# 7. Remove persistence
wave path-hijack       remove
wave poison-timer      remove
wave evil-timer        remove
wave ureadahead-persist remove
wave shadow-crond      remove
wave vim-persist       remove
wave nuke-journal      remove

# ── receipt ───────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}  TEARDOWN RECEIPT${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
ok=0; fail=0
for i in "${!WAVE_LABELS[@]}"; do
    if [[ "${WAVE_STATUS[$i]}" == "OK" ]]; then
        echo -e "  ${GREEN}[OK  ]${NC}  ${WAVE_LABELS[$i]}"
        (( ok++ ))   || true
    else
        echo -e "  ${RED}[FAIL]${NC}  ${WAVE_LABELS[$i]}"
        (( fail++ )) || true
    fi
done
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${ok} removed${NC}   ${RED}${fail} failed${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
