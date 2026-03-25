#!/usr/bin/env bash
# check-hosts.sh — verify SSH connectivity + sudo access to all Linux hosts
#
# Usage:
#   ./check-hosts.sh [OPTIONS]
#
# Options:
#   -u, --user USER      SSH username (default: root)
#   -P, --port PORT      SSH port (default: 22)
#       --sudo           Also test sudo -S id (confirm sudo with password)
#   -h, --help           Show this help
#
# Authentication:
#   You will be prompted to type the SSH password interactively.

set -uo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}── $* ──${NC}"; }

# ── host list (mirrors mass-deploy.sh) ────────────────────────────────────────
declare -A LINUX_HOSTS=(
    [svc-ftp-01]=10.10.10.101
    [svc-redis-01]=10.10.10.102
    [svc-database-01]=10.10.10.103
    [svc-amazin-01]=10.10.10.104
    [svc-samba-01]=10.10.10.105
    [blue-ubnt-01]=10.10.10.106
    [blue-ubnt-02]=10.10.10.107
    [blue-ubnt-03]=10.10.10.108
    [blue-ubnt-04]=10.10.10.109
)

SSH_USER="root"
SSH_PASS=""
SSH_PORT="22"
CHECK_SUDO=0

usage() {
    sed -n '/^# Usage:/,/^[^#]/{/^#/{s/^# \?//;p};/^[^#]/q}' "$0"
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user)      SSH_USER="$2"; shift 2 ;;
        -P|--port)      SSH_PORT="$2"; shift 2 ;;
        --sudo)         CHECK_SUDO=1;  shift   ;;
        -h|--help)      usage 0                ;;
        *) err "Unknown option: $1"; usage 1   ;;
    esac
done

# ── prompt for password ────────────────────────────────────────────────────────
read -rsp $'\033[0;36m[?]\033[0m SSH password: ' SSH_PASS
echo

# ── build shared SSH options ──────────────────────────────────────────────────
SSH_OPTS=(
    -o StrictHostKeyChecking=no
    -o ConnectTimeout=5
    -o PreferredAuthentications=password
    -o PubkeyAuthentication=no
    -o BatchMode=no
    -p "$SSH_PORT"
)

# ── helper: run a command on a target ─────────────────────────────────────────
ssh_run() {
    local target="$1" cmd="$2"
    if [[ -n "$SSH_PASS" ]]; then
        sshpass -p "$SSH_PASS" ssh "${SSH_OPTS[@]}" "$target" "$cmd" 2>/dev/null
    else
        ssh "${SSH_OPTS[@]}" "$target" "$cmd" 2>/dev/null
    fi
}

# ── check each host in parallel, collect results ──────────────────────────────
hdr "Connectivity check — ${#LINUX_HOSTS[@]} hosts"
echo

declare -A RES_SSH=()
declare -A RES_SUDO=()
declare -A RES_USER=()
declare -A RES_KERNEL=()
declare -A JOB_PIDS=()
TMPDIR_BASE="$(mktemp -d /dev/shm/.chk-XXXXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

for hostname in $(printf '%s\n' "${!LINUX_HOSTS[@]}" | sort); do
    ip="${LINUX_HOSTS[$hostname]}"
    target="${SSH_USER}@${ip}"
    outfile="${TMPDIR_BASE}/${hostname}"
    (
        ssh_ok="FAIL"
        sudo_ok="-"
        whoami_str="-"
        kernel_str="-"

        if out=$(ssh_run "$target" 'echo OK; id; uname -r' 2>/dev/null); then
            ssh_ok="OK"
            whoami_str=$(printf '%s' "$out" | grep -oP '(?<=uid=\d{1,6}\()[^)]+' | head -1 || echo "?")
            kernel_str=$(printf '%s' "$out" | tail -1)

            if [[ $CHECK_SUDO -eq 1 ]]; then
                if [[ -n "$SSH_PASS" ]]; then
                    sudo_out=$(ssh_run "$target" "printf '%s\n' '$(printf '%q' "$SSH_PASS")' | sudo -S id 2>/dev/null") || true
                else
                    sudo_out=$(ssh_run "$target" "sudo -n id 2>/dev/null") || true
                fi
                printf '%s' "$sudo_out" | grep -q "uid=0" && sudo_ok="OK" || sudo_ok="FAIL"
            fi
        fi
        printf '%s\t%s\t%s\t%s\n' "$ssh_ok" "$sudo_ok" "$whoami_str" "$kernel_str" > "$outfile"
    ) &
    JOB_PIDS["$hostname"]=$!
done

# Wait for all checks
for hostname in "${!JOB_PIDS[@]}"; do
    wait "${JOB_PIDS[$hostname]}" 2>/dev/null || true
done

# ── print results ─────────────────────────────────────────────────────────────
if [[ $CHECK_SUDO -eq 1 ]]; then
    printf "  ${BOLD}%-20s  %-16s  %-6s  %-6s  %-10s  %s${NC}\n" \
        "HOST" "IP" "SSH" "SUDO" "USER" "KERNEL"
    printf "  %-20s  %-16s  %-6s  %-6s  %-10s  %s\n" \
        "----" "--" "---" "----" "----" "------"
else
    printf "  ${BOLD}%-20s  %-16s  %-6s  %-10s  %s${NC}\n" \
        "HOST" "IP" "SSH" "USER" "KERNEL"
    printf "  %-20s  %-16s  %-6s  %-10s  %s\n" \
        "----" "--" "---" "----" "------"
fi

PASS=0; FAIL=0
for hostname in $(printf '%s\n' "${!LINUX_HOSTS[@]}" | sort); do
    ip="${LINUX_HOSTS[$hostname]}"
    outfile="${TMPDIR_BASE}/${hostname}"
    IFS=$'\t' read -r ssh_ok sudo_ok whoami_str kernel_str < "$outfile" 2>/dev/null \
        || { ssh_ok="FAIL"; sudo_ok="-"; whoami_str="-"; kernel_str="-"; }

    if [[ "$ssh_ok" == "OK" ]]; then
        col="${GREEN}"
        (( PASS++ )) || true
    else
        col="${RED}"
        (( FAIL++ )) || true
    fi

    if [[ $CHECK_SUDO -eq 1 ]]; then
        sudo_col="$( [[ "$sudo_ok" == "OK" ]] && echo "${GREEN}" || echo "${RED}" )"
        printf "  ${col}%-20s${NC}  %-16s  ${col}%-6s${NC}  ${sudo_col}%-6s${NC}  %-10s  %s\n" \
            "$hostname" "$ip" "$ssh_ok" "$sudo_ok" "$whoami_str" "$kernel_str"
    else
        printf "  ${col}%-20s${NC}  %-16s  ${col}%-6s${NC}  %-10s  %s\n" \
            "$hostname" "$ip" "$ssh_ok" "$whoami_str" "$kernel_str"
    fi
done

echo
info "${PASS} reachable,  ${FAIL} unreachable  (of ${#LINUX_HOSTS[@]} hosts)"
[[ $FAIL -gt 0 ]] && exit 1 || exit 0
