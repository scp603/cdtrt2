#!/usr/bin/env bash
# test-all-on-vm1.sh — install → status → remove each tool on a single target
#
# Usage:
#   ./test-all-on-vm1.sh [OPTIONS]
#
# Options:
#   -t, --target USER@HOST   SSH target (default: rootuser@100.69.82.61)
#   -P, --port PORT          SSH port (default: 22)
#       --no-sudo            Don't use sudo
#   -h, --help               Show this help
#
# Authentication:
#   You will be prompted to type the SSH/sudo password interactively.

set -uo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_TOOL="${RT_DIR}/rt-ssh.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}━━  $*  ━━${NC}\n"; }

TARGET="rootuser@100.69.82.61"
SSH_PORT="22"
NO_SUDO=0

usage() {
    sed -n '/^# Usage:/,/^[^#]/{/^#/{s/^# \?//;p};/^[^#]/q}' "$0"
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)   TARGET="$2";   shift 2 ;;
        -P|--port)     SSH_PORT="$2"; shift 2 ;;
        --no-sudo)     NO_SUDO=1;     shift   ;;
        -h|--help)     usage 0                ;;
        *) err "Unknown option: $1"; usage 1  ;;
    esac
done

# build shared rt-ssh args
RTOPTS=(-t "$TARGET" -P "$SSH_PORT")
[[ $NO_SUDO -eq 1 ]] && RTOPTS+=(--no-sudo)

rt() { "$SSH_TOOL" "${RTOPTS[@]}" "$@"; }

# ── receipt tracking ──────────────────────────────────────────────────────────
LABELS=()
RESULTS=()   # "PASS", "FAIL", "WARN"
REASONS=()

record() {
    local label="$1" result="$2" reason="${3:-}"
    LABELS+=("$label")
    RESULTS+=("$result")
    REASONS+=("$reason")
}

# ── test harness ──────────────────────────────────────────────────────────────
# test_tool <display-name> <tool-name> [has_status: yes|no]
# Runs: install → status (if applicable) → remove
# Each phase must exit 0 to count as PASS.
test_tool() {
    local name="$1" tool="$2" has_status="${3:-yes}"
    hdr "Testing: $tool"

    local install_ok=1 status_ok=1 remove_ok=1
    local reason=""

    # pre-clean (ignore failures — tool may not be installed)
    echo -e "${CYAN}  → pre-clean (remove any leftover state)${NC}"
    rt "$tool" remove &>/dev/null || true

    # install
    echo -e "${CYAN}  → install${NC}"
    if rt "$tool" install; then
        info "install: OK"
    else
        err "install: FAILED (exit $?)"
        install_ok=0
        reason="install failed"
    fi

    # status (optional)
    if [[ "$has_status" == "yes" && $install_ok -eq 1 ]]; then
        echo -e "\n${CYAN}  → status${NC}"
        if rt "$tool" status; then
            info "status: OK"
        else
            warn "status: non-zero exit"
            status_ok=0
            reason="status non-zero"
        fi
    fi

    # remove
    echo -e "\n${CYAN}  → remove${NC}"
    if rt "$tool" remove; then
        info "remove: OK"
    else
        err "remove: FAILED (exit $?)"
        remove_ok=0
        [[ -z "$reason" ]] && reason="remove failed"
    fi

    if [[ $install_ok -eq 1 && $remove_ok -eq 1 ]]; then
        if [[ $status_ok -eq 1 ]]; then
            record "$name" "PASS" ""
        else
            record "$name" "WARN" "status non-zero"
        fi
    else
        record "$name" "FAIL" "$reason"
    fi
}

# ── prompt for password ────────────────────────────────────────────────────────
read -rsp $'\033[0;36m[?]\033[0m SSH/sudo password: ' SSH_PASS
echo
export RT_SSH_PASS="$SSH_PASS"
export RT_SUDO_PASS="$SSH_PASS"

info "Target: $TARGET"
echo

# ── run tests ─────────────────────────────────────────────────────────────────
# Args: display-name  tool-name  has_status(yes/no)

# ── madness-begin tools (run on every target) ─────────────────────────────────
test_tool "compromise-who"     compromise-who      no
test_tool "nuke-journal"       nuke-journal        yes
test_tool "sinkhole"           sinkhole            yes
test_tool "infinite-users"     infinite-users      yes
test_tool "pam-backdoor"       pam-backdoor        yes
test_tool "break-net-tools"    break-net-tools     yes

# ── persistence ───────────────────────────────────────────────────────────────
test_tool "shadow-crond"       shadow-crond        yes
test_tool "ureadahead-persist" ureadahead-persist  yes
test_tool "poison-timer"       poison-timer        yes
test_tool "evil-timer"         evil-timer          yes
test_tool "path-hijack"        path-hijack         yes
test_tool "vim-persist"        vim-persist         no
test_tool "alias-bashrc"       alias-bashrc        no

# ── sabotage / denial ─────────────────────────────────────────────────────────
test_tool "lock-busybox"       lock-busybox        yes
test_tool "no-apt"             no-apt              yes
test_tool "no-audit"           no-audit            yes
test_tool "no-selinux"         no-selinux          yes

# ── one-shot / stealth ────────────────────────────────────────────────────────
test_tool "sudo-binary"        sudo-binary         yes
test_tool "vandalize-bashrc"   vandalize-bashrc    yes
test_tool "the-toucher"        the-toucher         yes

# ── receipt ───────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}  TEST RESULTS${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
pass=0; warn_count=0; fail=0
for i in "${!LABELS[@]}"; do
    label="${LABELS[$i]}"
    result="${RESULTS[$i]}"
    reason="${REASONS[$i]}"
    case "$result" in
        PASS) echo -e "  ${GREEN}[PASS]${NC}  ${BOLD}${label}${NC}"; (( pass++ )) || true ;;
        WARN) echo -e "  ${YELLOW}[WARN]${NC}  ${BOLD}${label}${NC}  ${YELLOW}(${reason})${NC}"; (( warn_count++ )) || true ;;
        FAIL) echo -e "  ${RED}[FAIL]${NC}  ${BOLD}${label}${NC}  ${RED}(${reason})${NC}"; (( fail++ )) || true ;;
    esac
done
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${pass} passed${NC}   ${YELLOW}${warn_count} warned${NC}   ${RED}${fail} failed${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
