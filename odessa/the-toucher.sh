#!/usr/bin/env bash
# the-toucher.sh — wanders the filesystem and touches random files (messes with mtimes)
#
# Usage:
#   sudo ./the-toucher.sh install   [root] [delay] [max_depth]
#   sudo ./the-toucher.sh remove
#   sudo ./the-toucher.sh status

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }

STATE_FILE="/var/cache/.syspkg/toucher.pid"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"

_run_loop() {
    local ROOT="${1:-/}"
    local DELAY="${2:-0.1}"
    local MAX_DEPTH="${3:-5}"
    local touched=0 skipped=0
    # resolve greyteam/ansible/scoring home dirs to skip
    local _skip_dirs=()
    for _u in greyteam ansible scoring; do
        local _h; _h=$(getent passwd "$_u" 2>/dev/null | cut -d: -f6) || true
        [[ -n "${_h:-}" ]] && _skip_dirs+=("-not" "-path" "${_h}/*")
    done

    trap 'exit 0' INT TERM

    while true; do
        local current="$ROOT"
        local depth=0
        while [[ $depth -lt $MAX_DEPTH ]]; do
            mapfile -t subdirs < <(find "$current" -maxdepth 1 -mindepth 1 -type d \
                -readable -not -name "proc" -not -name "sys" -not -name "dev" "${_skip_dirs[@]}" 2>/dev/null)
            [[ ${#subdirs[@]} -eq 0 ]] && break
            current="${subdirs[$((RANDOM % ${#subdirs[@]}))]}"
            (( depth++ ))
            [[ $(( RANDOM % 3 )) -eq 0 ]] && break
        done
        mapfile -t files < <(find "$current" -maxdepth 1 -mindepth 1 -type f -writable 2>/dev/null)
        if [[ ${#files[@]} -gt 0 ]]; then
            local target="${files[$((RANDOM % ${#files[@]}))]}"
            touch "$target" 2>/dev/null && (( touched++ )) || (( skipped++ ))
        else
            (( skipped++ ))
        fi
        sleep "$DELAY"
    done
}

cmd_install() {
    local ROOT="${1:-/}" DELAY="${2:-0.1}" MAX_DEPTH="${3:-5}"

    if [[ -f "$STATE_FILE" ]]; then
        local old_pid; old_pid=$(cat "$STATE_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            warn "Already running (PID $old_pid)"
            exit 0
        fi
    fi

    mkdir -p "$(dirname "$STATE_FILE")"
    hdr "Starting toucher"
    # Re-exec this script in _loop mode as a background process
    nohup bash "$SELF" _loop "$ROOT" "$DELAY" "$MAX_DEPTH" >/dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$STATE_FILE"
    info "Started (PID $pid) — touching files under $ROOT every ${DELAY}s"
}

cmd_remove() {
    hdr "Stopping toucher"
    if [[ -f "$STATE_FILE" ]]; then
        local pid; pid=$(cat "$STATE_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && info "Killed PID $pid" || warn "Failed to kill $pid"
        else
            warn "PID $pid not running"
        fi
        rm -f "$STATE_FILE"
    else
        warn "No state file — trying pkill fallback"
        pkill -f "the-toucher.sh _loop" 2>/dev/null || warn "No matching process found"
    fi
}

cmd_status() {
    hdr "Toucher status"
    if [[ -f "$STATE_FILE" ]]; then
        local pid; pid=$(cat "$STATE_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            info "RUNNING   PID $pid"
            ps -p "$pid" -o pid,etime,cmd --no-headers 2>/dev/null || true
        else
            warn "STOPPED   PID $pid (stale state file)"
        fi
    else
        warn "NOT RUNNING  (no state file)"
    fi
}

case "${1:-install}" in
    install) cmd_install "${@:2}" ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    _loop)   _run_loop "${@:2}" ;;   # internal — called by nohup
    *) echo "Usage: sudo $0 install|remove|status [root] [delay] [max_depth]" ;;
esac
