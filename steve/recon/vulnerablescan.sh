#!/usr/bin/env bash
set -euo pipefail

# output setup
OUTPUT_DIR="./vuln_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NOW=$(date +"%Y-%m-%d %H:%M:%S")
mkdir -p "$OUTPUT_DIR"

HOSTS_CSV="$OUTPUT_DIR/vuln_hosts_$TIMESTAMP.csv"
SERVICES_CSV="$OUTPUT_DIR/vuln_services_$TIMESTAMP.csv"
FINDINGS_CSV="$OUTPUT_DIR/vuln_findings_$TIMESTAMP.csv"
RAW_DIR="$OUTPUT_DIR/raw_$TIMESTAMP"
mkdir -p "$RAW_DIR"

# approved Blue Team hosts only
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

# selected ports tied to likely competition services
PORTS="21,22,53,80,88,135,139,389,443,445,464,593,636,3268,3269,3389,5985,6379,8080,8443"

# scan tuning
DISCOVERY_TIMING="${DISCOVERY_TIMING:-T2}"
SERVICE_TIMING="${SERVICE_TIMING:-T3}"
MAX_RETRIES="${MAX_RETRIES:-2}"

# temp state
PORTMAP_FILE="$RAW_DIR/portmap.csv"
FINDING_KEYS_FILE="$RAW_DIR/finding_keys.txt"
touch "$PORTMAP_FILE" "$FINDING_KEYS_FILE"

# check dependencies
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[!] missing dependency: $1"
    exit 1
  }
}

require_cmd nmap
require_cmd awk
require_cmd grep
require_cmd sed
require_cmd tr

# join array with delimiter
join_by() {
  local d="$1"
  shift
  local first=1
  local x
  for x in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf "%s" "$x"
      first=0
    else
      printf "%s%s" "$d" "$x"
    fi
  done
}

# csv-safe field cleanup
csv_escape() {
  local value="$1"
  value=$(printf "%s" "$value" | tr '\n' ' ' | tr '\r' ' ')
  value=${value//\"/\'}
  printf "%s" "$value"
}

# write finding once only
add_finding() {
  local ip="$1"
  local port="$2"
  local service="$3"
  local severity="$4"
  local check_name="$5"
  local details="$6"

  local key="${ip}|${port}|${service}|${severity}|${check_name}"
  if grep -Fxq "$key" "$FINDING_KEYS_FILE"; then
    return 0
  fi

  printf "%s\n" "$key" >> "$FINDING_KEYS_FILE"
  details="$(csv_escape "$details")"
  printf '%s,%s,%s,%s,%s,"%s",%s\n' \
    "$ip" "$port" "$service" "$severity" "$check_name" "$details" "$NOW" >> "$FINDINGS_CSV"
}

# run command and save output without killing script on scan errors
run_and_save() {
  local outfile="$1"
  shift
  "$@" > "$outfile" 2>&1 || true
}

# check if a host/port pair exists in port map
port_is_open() {
  local host="$1"
  local port="$2"
  grep -qE "^${host},${port}," "$PORTMAP_FILE"
}

# get service name from port map
get_service_name() {
  local host="$1"
  local port="$2"
  awk -F',' -v h="$host" -v p="$port" '$1 == h && $2 == p {print $3; exit}' "$PORTMAP_FILE"
}

# csv headers
echo "ip,status,last_seen" > "$HOSTS_CSV"
echo "ip,port,service,last_seen" > "$SERVICES_CSV"
echo "ip,port,service,severity,check_name,details,last_seen" > "$FINDINGS_CSV"

echo "[*] running host discovery"
TARGETS="$(join_by , "${BLUE_HOSTS[@]}")"

mapfile -t LIVE_HOSTS < <(
  nmap -sn -n "-$DISCOVERY_TIMING" --max-retries "$MAX_RETRIES" "$TARGETS" \
  | awk '/Nmap scan report for/{print $NF}' \
  | sed 's/[()]//g'
)

declare -A LIVE_MAP=()
for host in "${LIVE_HOSTS[@]:-}"; do
  LIVE_MAP["$host"]=1
done

for host in "${BLUE_HOSTS[@]}"; do
  if [[ -n "${LIVE_MAP[$host]:-}" ]]; then
    echo "$host,up,$NOW" >> "$HOSTS_CSV"
  else
    echo "$host,down,$NOW" >> "$HOSTS_CSV"
  fi
done

if [[ ${#LIVE_HOSTS[@]} -eq 0 ]]; then
  echo "[!] no live Blue hosts found"
  echo "[+] wrote:"
  echo "  $HOSTS_CSV"
  echo "  $SERVICES_CSV"
  echo "  $FINDINGS_CSV"
  exit 0
fi

echo "[*] collecting service inventory for ${#LIVE_HOSTS[@]} live hosts"
for host in "${LIVE_HOSTS[@]}"; do
  GNMAP_OUT="$RAW_DIR/${host}_services.gnmap"
  TXT_OUT="$RAW_DIR/${host}_services.txt"

  nmap -sS -sV -Pn -n "-$SERVICE_TIMING" --max-retries "$MAX_RETRIES" --open -p "$PORTS" \
    -oG "$GNMAP_OUT" "$host" > "$TXT_OUT" 2>&1 || true

  awk -v ip="$host" '
    /Ports:/ {
      split($0, a, "Ports: ")
      split(a[2], ports, ",")
      for (i in ports) {
        gsub(/^ +| +$/, "", ports[i])
        split(ports[i], p, "/")
        if (p[2] == "open") {
          svc = (p[5] == "" ? "unknown" : p[5])
          printf "%s,%s,%s\n", ip, p[1], svc
        }
      }
    }' "$GNMAP_OUT" | sort -u >> "$PORTMAP_FILE"
done

sort -u "$PORTMAP_FILE" | while IFS=, read -r ip port service; do
  echo "$ip,$port,$service,$NOW" >> "$SERVICES_CSV"
done

echo "[*] running targeted checks"

for host in "${LIVE_HOSTS[@]}"; do
  echo "[*] checking $host"

  # ftp checks
  if port_is_open "$host" 21; then
    OUTFILE="$RAW_DIR/${host}_ftp.txt"
    run_and_save "$OUTFILE" nmap -Pn -n -p 21 --script ftp-anon,ftp-syst "$host"

    grep -qi "Anonymous FTP login allowed" "$OUTFILE" && \
      add_finding "$host" "21" "ftp" "high" "ftp-anon" "Anonymous FTP login allowed"

    grep -Eiq "220|vsftpd|ftp server status" "$OUTFILE" && \
      add_finding "$host" "21" "ftp" "info" "ftp-review" "FTP service responds; review banner and access controls"
  fi

  # http and https checks
  for web_port in 80 443 8080 8443; do
    if port_is_open "$host" "$web_port"; then
      OUTFILE="$RAW_DIR/${host}_http_${web_port}.txt"
      run_and_save "$OUTFILE" nmap -Pn -n -p "$web_port" --script http-title,http-headers "$host"

      grep -Eiq "WordPress|wp-content|wp-includes" "$OUTFILE" && \
        add_finding "$host" "$web_port" "http" "medium" "wordpress-detected" "WordPress indicators found"

      if [[ "$web_port" == "443" || "$web_port" == "8443" ]]; then
        TLS_OUT="$RAW_DIR/${host}_tls_${web_port}.txt"
        run_and_save "$TLS_OUT" nmap -Pn -n -p "$web_port" --script ssl-enum-ciphers "$host"

        grep -Eiq "TLSv1\.0|TLSv1\.1" "$TLS_OUT" && \
          add_finding "$host" "$web_port" "https" "medium" "legacy-tls" "Supports TLS 1.0 or 1.1"

        grep -Eiq "3des|rc4|cbc" "$TLS_OUT" && \
          add_finding "$host" "$web_port" "https" "medium" "weak-ciphers" "Potentially weak TLS cipher support detected"
      fi
    fi
  done

  # smb checks
  if port_is_open "$host" 445; then
    OUTFILE="$RAW_DIR/${host}_smb.txt"
    run_and_save "$OUTFILE" nmap -Pn -n -p 445 \
      --script smb-protocols,smb-security-mode,smb-vuln-ms17-010 "$host"

    grep -qi "SMBv1" "$OUTFILE" && \
      add_finding "$host" "445" "smb" "high" "smbv1" "SMBv1 appears enabled"

    grep -Eiq "message_signing: disabled|signing: disabled|not required" "$OUTFILE" && \
      add_finding "$host" "445" "smb" "medium" "smb-signing" "SMB signing not required or disabled"

    grep -qi "VULNERABLE" "$OUTFILE" && \
      add_finding "$host" "445" "smb" "critical" "ms17-010" "Nmap reported a possible SMB vulnerability; verify manually"
  fi

  # redis checks
  if port_is_open "$host" 6379; then
    OUTFILE="$RAW_DIR/${host}_redis.txt"
    run_and_save "$OUTFILE" nmap -Pn -n -p 6379 --script redis-info "$host"

    grep -qi "redis_version" "$OUTFILE" && \
      add_finding "$host" "6379" "redis" "medium" "redis-exposure" "Redis responded to info query; review authentication and exposure"
  fi

  # winrm exposure
  if port_is_open "$host" 5985; then
    add_finding "$host" "5985" "winrm" "info" "winrm-exposed" "WinRM exposed; review access restrictions"
  fi

  # rdp exposure
  if port_is_open "$host" 3389; then
    add_finding "$host" "3389" "rdp" "info" "rdp-exposed" "RDP exposed; review NLA and access restrictions"
  fi
done

echo
echo "[+] scan complete"
echo "  hosts:    $HOSTS_CSV"
echo "  services: $SERVICES_CSV"
echo "  findings: $FINDINGS_CSV"
echo "  raw:      $RAW_DIR"