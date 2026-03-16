#!/usr/bin/env bash
# random_touch.sh — wanders the filesystem and touches random files

ROOT="${1:-/}"          # starting root (default: /)
DELAY="${2:-0.1}"       # seconds between touches (default: 0.1)
MAX_DEPTH="${3:-5}"     # max directory depth to descend

touched=0
skipped=0

echo "[*] Starting random filesystem walk"
echo "    Root     : $ROOT"
echo "    Delay    : ${DELAY}s"
echo "    Max depth: $MAX_DEPTH"
echo "    Press Ctrl+C to stop"
echo ""

trap 'echo -e "\n[!] Interrupted. Touched: $touched, Skipped: $skipped"; exit 0' INT TERM

while true; do
    # Build a random path by walking directories one level at a time
    current="$ROOT"
    depth=0

    while [[ $depth -lt $MAX_DEPTH ]]; do
        # List subdirectories we can read
        mapfile -t subdirs < <(find "$current" -maxdepth 1 -mindepth 1 -type d \
            -readable -not -name "proc" -not -name "sys" \
            -not -name "dev" 2>/dev/null)

        [[ ${#subdirs[@]} -eq 0 ]] && break

        # Pick a random subdir
        current="${subdirs[$((RANDOM % ${#subdirs[@]}))]}"
        (( depth++ ))

        # Randomly decide to stop descending
        [[ $(( RANDOM % 3 )) -eq 0 ]] && break
    done

    # Pick a random file in the chosen directory
    mapfile -t files < <(find "$current" -maxdepth 1 -mindepth 1 -type f \
        -writable 2>/dev/null)

    if [[ ${#files[@]} -gt 0 ]]; then
        target="${files[$((RANDOM % ${#files[@]}))]}"
        touch "$target" 2>/dev/null && {
            echo "[+] touched: $target"
            (( touched++ ))
        } || (( skipped++ ))
    else
        (( skipped++ ))
    fi

    sleep "$DELAY"
done
