#!/usr/bin/env bash
set -euo pipefail

# create output directory and timestamp for this run
OUTPUT_DIR="./scan_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$OUTPUT_DIR"

# define output file paths
LIVE_CSV="$OUTPUT_DIR/live_hosts_$TIMESTAMP.csv"
PORTS_CSV="$OUTPUT_DIR/open_ports_$TIMESTAMP.csv"

# list of approved Blue Team hosts (no grey infra)
BLUE_HOSTS=(
  10.10.10.21
  10.10.10.22
  10.10.10.23
  10.10.10.24
  10.10.10.25
  10.10.10.26
  10.10.10.27
  10.10.10.28
  10.10.10.29
  10.10.10.30
  10.10.10.101
  10.10.10.102
  10.10.10.103
  10.10.10.104
  10.10.10.105
  10.10.10.106
  10.10.10.107
  10.10.10.108
  10.10.10.109
)

# common ports to check (low noise but useful coverage)
PORTS="21,22,53,80,88,135,139,389,443,445,464,593,636,3268,3269,3389,5985,6379,8080,8443"

# helper function to join array into comma-separated string
join_by() {
  local d="$1"; shift
  local first=1
  for x in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf "%s" "$x"
      first=0
    else
      printf "%s%s" "$d" "$x"
    fi
  done
}

# build target string for nmap
TARGETS="$(join_by , "${BLUE_HOSTS[@]}")"

# write CSV headers
echo "ip,status,last_seen" > "$LIVE_CSV"
echo "ip,port,state,service,last_seen" > "$PORTS_CSV"

# capture current time for this scan
NOW=$(date +"%Y-%m-%d %H:%M:%S")

echo "[*] running host discovery"

# find which hosts are alive
LIVE_HOSTS=$(nmap -sn -n -T2 --max-retries 2 $TARGETS | awk '/Nmap scan report/{print $NF}')

# mark each host as up or down
for host in "${BLUE_HOSTS[@]}"; do
  if echo "$LIVE_HOSTS" | grep -qx "$host"; then
    echo "$host,up,$NOW" >> "$LIVE_CSV"
  else
    echo "$host,down,$NOW" >> "$LIVE_CSV"
  fi
done

# stop if nothing is alive
if [[ -z "${LIVE_HOSTS:-}" ]]; then
  echo "[!] no live hosts found"
  echo "[+] wrote:"
  echo "  $LIVE_CSV"
  echo "  $PORTS_CSV"
  exit 0
fi

echo "[*] scanning ports on live hosts"

# scan each live host for open ports
for host in $LIVE_HOSTS; do
  nmap -sS -Pn -n -T2 --max-retries 2 --open -p "$PORTS" -oG - "$host" \
  | awk -v ip="$host" -v now="$NOW" '
    /Ports:/ {
      split($0, a, "Ports: ")
      split(a[2], ports, ",")
      for (i in ports) {
        gsub(/^ +| +$/, "", ports[i])
        split(ports[i], p, "/")
        if (p[2] == "open") {
          printf "%s,%s,%s,%s,%s\n", ip, p[1], p[2], p[5], now
        }
      }
    }' >> "$PORTS_CSV"
done

echo
echo "[+] export complete"
echo "  $LIVE_CSV"
echo "  $PORTS_CSV"