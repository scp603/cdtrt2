#!/usr/bin/env bash
# mass-deploy.sh — Deploy any rt-ssh.sh tool to all Linux targets in parallel
#
# Wraps rt-ssh.sh and fans out one invocation per host concurrently.
# Per-host output is captured and printed sequentially after all jobs finish.
#
# Usage:
#   ./mass-deploy.sh [MASS-OPTS] <tool> [tool-args...]
#
# Mass options:
#   -u, --user USER      SSH username for all hosts (default: root)
#   -P, --port PORT      SSH port (default: 22)
#       --no-sudo        Pass --no-sudo to rt-ssh.sh (use when SSH'd in as root)
#   -j, --jobs N         Max parallel jobs (default: 9, one per Linux host)
#       --hosts FILE     Plain-text file of IPs to target (one per line).
#                        Overrides the built-in host list.
#       --dry-run        Print the rt-ssh.sh command for each host; don't run
#   -v, --verbose        Pass -v to rt-ssh.sh (show remote command on each host)
#   -h, --help           Show this help and exit
#
# Authentication:
#   You will be prompted to type the SSH/sudo password interactively.
#
# Examples:
#   # Shadow cron on all hosts
#   ./mass-deploy.sh --no-sudo shadow-crond install
#
#   # Ureadahead on all hosts
#   ./mass-deploy.sh -u ubuntu ureadahead-persist install
#
#   # Path-hijack system level, 4 at a time
#   ./mass-deploy.sh --no-sudo -j 4 path-hijack install --level system
#
#   # Dry-run to preview commands
#   ./mass-deploy.sh --dry-run -u root shadow-crond install
#
# ── built-in Linux target list (internal IPs) ──────────────────────────────
#   svc-ftp-01      10.10.10.101
#   svc-redis-01    10.10.10.102
#   svc-database-01 10.10.10.103
#   svc-amazin-01   10.10.10.104
#   svc-samba-01    10.10.10.105
#   blue-ubnt-01    10.10.10.106
#   blue-ubnt-02    10.10.10.107
#   blue-ubnt-03    10.10.10.108
#   blue-ubnt-04    10.10.10.109
# ───────────────────────────────────────────────────────────────────────────

set -uo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RT_SSH="${RT_DIR}/rt-ssh.sh"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()     { echo -e "\n${CYAN}${BOLD}── $* ──${NC}"; }

# ── built-in Linux host list: hostname → internal IP ─────────────────────────
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
    [testvm1]=100.69.82.61
)

# ── defaults ─────────────────────────────────────────────────────────────────
SSH_USER="root"
SSH_PASS=""
SSH_PORT="22"
SUDO_PASS=""
NO_SUDO=0
MAX_JOBS=9
HOSTS_FILE=""
DRY_RUN=0
VERBOSE=0

usage() {
    sed -n '/^# Usage:/,/^[^#]/{/^#/{s/^# \?//;p};/^[^#]/q}' "$0"
    exit "${1:-0}"
}

# ── argument parsing ──────────────────────────────────────────────────────────
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user)       SSH_USER="$2";   shift 2 ;;
        -P|--port)       SSH_PORT="$2";   shift 2 ;;
        --no-sudo)       NO_SUDO=1;       shift   ;;
        -j|--jobs)       MAX_JOBS="$2";   shift 2 ;;
        --hosts)         HOSTS_FILE="$2"; shift 2 ;;
        --dry-run)       DRY_RUN=1;       shift   ;;
        -v|--verbose)    VERBOSE=1;       shift   ;;
        -h|--help)       usage 0                  ;;
        --)              shift; POSITIONAL+=("$@"); break ;;
        -*)
            # If we already have a tool name, forward unknown flags to rt-ssh.sh
            [[ ${#POSITIONAL[@]} -gt 0 ]] \
                && POSITIONAL+=("$1") \
                || { err "Unknown option: $1"; usage 1; }
            shift ;;
        *)  POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

[[ $# -lt 1 ]] && { err "No tool specified."; usage 1; }

# ── build target list ─────────────────────────────────────────────────────────
declare -A TARGETS=()   # hostname → IP

if [[ -n "$HOSTS_FILE" ]]; then
    [[ -f "$HOSTS_FILE" ]] || { err "Hosts file not found: $HOSTS_FILE"; exit 1; }
    i=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"   # strip comments
        line="${line// /}"   # strip spaces
        [[ -z "$line" ]] && continue
        TARGETS["host-${i}"]="$line"
        (( i++ )) || true
    done < "$HOSTS_FILE"
else
    for h in "${!LINUX_HOSTS[@]}"; do
        TARGETS["$h"]="${LINUX_HOSTS[$h]}"
    done
fi

[[ ${#TARGETS[@]} -eq 0 ]] && { err "Target list is empty."; exit 1; }

# ── prompt for password (or inherit from parent via env) ──────────────────────
if [[ -n "${RT_SSH_PASS:-}" ]]; then
    SSH_PASS="$RT_SSH_PASS"
else
    read -rsp $'\033[0;36m[?]\033[0m SSH/sudo password: ' SSH_PASS
    echo
fi
SUDO_PASS="${RT_SUDO_PASS:-$SSH_PASS}"
export RT_SSH_PASS="$SSH_PASS"
export RT_SUDO_PASS="$SUDO_PASS"

# ── build the rt-ssh.sh options array (shared across all hosts) ───────────────
RT_OPTS=()
[[ -n "$SSH_PORT"   ]] && RT_OPTS+=(-P "$SSH_PORT")
[[ $NO_SUDO  -eq 1  ]] && RT_OPTS+=(--no-sudo)
[[ $VERBOSE  -eq 1  ]] && RT_OPTS+=(-v)
# "$@" now holds: <tool> [tool-args...]
TOOL_CMD=("$@")

# ── sanity: rt-ssh.sh must exist ─────────────────────────────────────────────
[[ -x "$RT_SSH" ]] || { err "rt-ssh.sh not found or not executable: $RT_SSH"; exit 1; }

# ── temp dir for per-host log capture ────────────────────────────────────────
TMPDIR_BASE="$(mktemp -d /dev/shm/.mass-XXXXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ── print header ─────────────────────────────────────────────────────────────
hdr "mass-deploy  →  ${TOOL_CMD[*]}"
info "SSH user   : $SSH_USER"
info "Auth       : password (interactive)"
info "Sudo       : $([ $NO_SUDO -eq 1 ] && echo "no (root SSH)" || echo "yes")"
info "Parallelism: ${MAX_JOBS} jobs"
info "Targets    : ${#TARGETS[@]} Linux hosts"
echo

[[ $DRY_RUN -eq 1 ]] && warn "DRY-RUN — no commands will be executed" && echo

# ── job runner ────────────────────────────────────────────────────────────────
declare -A JOB_PIDS=()      # hostname → pid
declare -A JOB_LOGS=()      # hostname → log file
declare -A JOB_IPS=()       # hostname → ip

running_jobs() {
    local count=0
    for h in "${!JOB_PIDS[@]}"; do
        kill -0 "${JOB_PIDS[$h]}" 2>/dev/null && (( count++ )) || true
    done
    echo "$count"
}

launch_job() {
    local hostname="$1" ip="$2"
    local logfile="${TMPDIR_BASE}/${hostname}.log"
    local target="${SSH_USER}@${ip}"

    JOB_IPS["$hostname"]="$ip"
    JOB_LOGS["$hostname"]="$logfile"

    local cmd=("$RT_SSH" "${RT_OPTS[@]}" -t "$target" "${TOOL_CMD[@]}")

    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "  ${CYAN}${hostname}${NC} (${ip})  →  ${cmd[*]}"
        JOB_PIDS["$hostname"]=0
        return
    fi

    # Run in background; capture both stdout and stderr to log
    {
        echo "=== ${hostname} (${ip}) ==="
        "${cmd[@]}" 2>&1
        echo "EXIT:$?"
    } > "$logfile" 2>&1 &
    JOB_PIDS["$hostname"]=$!
}

# ── dispatch jobs (respecting max parallelism) ────────────────────────────────
for hostname in $(printf '%s\n' "${!TARGETS[@]}" | sort); do
    ip="${TARGETS[$hostname]}"

    # throttle
    while (( $(running_jobs) >= MAX_JOBS )); do
        sleep 0.3
    done

    info "Launching  → ${hostname} (${ip})"
    launch_job "$hostname" "$ip"
done

[[ $DRY_RUN -eq 1 ]] && echo && exit 0

# ── wait for all jobs then print results ─────────────────────────────────────
hdr "Waiting for all jobs to complete"

declare -A RESULTS=()   # hostname → PASS|FAIL

for hostname in $(printf '%s\n' "${!JOB_PIDS[@]}" | sort); do
    pid="${JOB_PIDS[$hostname]}"
    wait "$pid" 2>/dev/null || true

    logfile="${JOB_LOGS[$hostname]}"
    ip="${JOB_IPS[$hostname]}"

    # pull exit code from log tail
    exit_code=$(grep -oP 'EXIT:\K[0-9]+' "$logfile" 2>/dev/null | tail -1 || echo "?")

    if [[ "$exit_code" == "0" ]]; then
        RESULTS["$hostname"]="PASS"
    else
        RESULTS["$hostname"]="FAIL(${exit_code})"
    fi

    # Print host output under a header
    hdr "${hostname} (${ip})"
    # Strip trailing EXIT: line from display
    grep -v '^EXIT:' "$logfile" || true
done

# ── summary table ─────────────────────────────────────────────────────────────
hdr "Summary"
PASS_COUNT=0
FAIL_COUNT=0

printf "  %-20s  %-16s  %s\n" "HOSTNAME" "IP" "STATUS"
printf "  %-20s  %-16s  %s\n" "--------" "--" "------"

for hostname in $(printf '%s\n' "${!RESULTS[@]}" | sort); do
    ip="${JOB_IPS[$hostname]}"
    result="${RESULTS[$hostname]}"
    if [[ "$result" == "PASS" ]]; then
        printf "  %-20s  %-16s  ${GREEN}%s${NC}\n" "$hostname" "$ip" "$result"
        (( PASS_COUNT++ )) || true
    else
        printf "  %-20s  %-16s  ${RED}%s${NC}\n" "$hostname" "$ip" "$result"
        (( FAIL_COUNT++ )) || true
    fi
done

echo
info "Done: ${PASS_COUNT} passed, ${FAIL_COUNT} failed (of ${#RESULTS[@]} hosts)"
[[ $FAIL_COUNT -gt 0 ]] && exit 1 || exit 0
