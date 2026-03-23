#!/usr/bin/env bash
set -euo pipefail
# exit on error, unset vars, and pipeline failures

# local_flag_finder.sh
# search local readable files for common flag formats

# use one user-supplied directory, otherwise use defaults
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  TARGET_DIRS=("$1")
else
  TARGET_DIRS=(
    "$HOME"
    "/home"
    "/var/www"
    "/opt"
    "/etc"
    "/tmp"
    "/var/tmp"
  )
fi

# allow custom regex as second arg
FLAG_REGEX="${2:-FLAGS\{[^}]+\}|FLAG\{[^}]+\}|flag\{[^}]+\}|HTB\{[^}]+\}|THM\{[^}]+\}|picoCTF\{[^}]+\}|CTF\{[^}]+\}}"

# get host ip for output naming
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

# fallback ip lookup
if [[ -z "${HOST_IP:-}" ]]; then
  HOST_IP="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1)"
fi

# final fallback
HOST_IP="${HOST_IP:-unknownip}"
SAFE_IP="${HOST_IP//./_}"

# setup output
OUT_DIR="./flag_results"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$OUT_DIR/flags_${SAFE_IP}_$TS.txt"
mkdir -p "$OUT_DIR"

echo "[*] Host IP: $HOST_IP"
echo "[*] Targets: ${TARGET_DIRS[*]}"
echo "[*] Regex: $FLAG_REGEX"
echo "[*] Output: $OUT_FILE"
echo

# skip noisy or useless paths
PRUNE_DIRS=(
  "/proc"
  "/sys"
  "/dev"
  "/run"
  "/snap"
  "/mnt"
  "/media"
  "/lost+found"
  "/usr/share"
  "/usr/src"
  "/lib"
  "/lib64"
  "/var/cache"
)

# build prune rules for find
PRUNE_EXPR=()
for d in "${PRUNE_DIRS[@]}"; do
  [[ ${#PRUNE_EXPR[@]} -gt 0 ]] && PRUNE_EXPR+=(-o)
  PRUNE_EXPR+=(-path "$d")
done

echo "[*] Starting content search..." | tee "$OUT_FILE"

for dir in "${TARGET_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue

  echo "[*] Searching: $dir" | tee -a "$OUT_FILE"

  find "$dir" \
    \( "${PRUNE_EXPR[@]}" \) -prune -o \
    -type f -readable -size -5M -print0 2>/dev/null |
  while IFS= read -r -d '' file; do
    while IFS= read -r match; do
      [[ -n "$match" ]] || continue
      echo "[FOUND] $file :: $match" | tee -a "$OUT_FILE"
    done < <(grep -I -Eo "$FLAG_REGEX" "$file" 2>/dev/null || true)
  done

  echo | tee -a "$OUT_FILE"
done

echo "[*] Done. Results saved to $OUT_FILE"