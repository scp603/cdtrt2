#!/usr/bin/env bash
# root-ssh.sh — Enable direct root SSH login on a target host
#
# Patches /etc/ssh/sshd_config to set PermitRootLogin yes, optionally injects
# an SSH public key and/or sets a root password, then restarts sshd.
# A backup of the original sshd_config is kept at /etc/ssh/sshd_config.rt-bak.
#
# Usage:
#   sudo ./root-ssh.sh install [--key "ssh-ed25519 AAAA..."] [--pass PASSWORD]
#   sudo ./root-ssh.sh remove
#   sudo ./root-ssh.sh status

set -euo pipefail

SSHD_CONF="/etc/ssh/sshd_config"
SSHD_BACKUP="${SSHD_CONF}.rt-bak"
ROOT_AK="/root/.ssh/authorized_keys"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

_restart_sshd() {
    if command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null; then
        # prefer the socket unit name if it exists (Ubuntu 22.04+)
        if systemctl list-units --type=service --all 2>/dev/null | grep -q 'ssh\.service'; then
            systemctl restart ssh
        else
            systemctl restart sshd
        fi
    elif command -v service &>/dev/null; then
        service ssh restart 2>/dev/null || service sshd restart
    else
        kill -HUP "$(cat /var/run/sshd.pid 2>/dev/null)" 2>/dev/null \
            || err "Could not restart sshd — restart manually"
        return
    fi
    info "sshd restarted"
}

# ── install ───────────────────────────────────────────────────────────────────

cmd_install() {
    require_root

    SSH_KEY=""
    ROOT_PASS=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --key)  SSH_KEY="$2";   shift 2 ;;
            --pass) ROOT_PASS="$2"; shift 2 ;;
            *)      shift ;;
        esac
    done

    # ── 1. backup sshd_config ─────────────────────────────────────────────────
    hdr "1/4  Backing up sshd_config"
    if [[ ! -f "$SSHD_BACKUP" ]]; then
        cp "$SSHD_CONF" "$SSHD_BACKUP"
        info "Backup saved → ${SSHD_BACKUP}"
    else
        warn "Backup already exists at ${SSHD_BACKUP}, skipping overwrite"
    fi

    # ── 2. patch PermitRootLogin ──────────────────────────────────────────────
    hdr "2/4  Patching PermitRootLogin"
    # Remove any existing PermitRootLogin lines (commented or not), then append
    sed -i '/^[[:space:]]*#*[[:space:]]*PermitRootLogin/d' "$SSHD_CONF"
    echo "PermitRootLogin yes" >> "$SSHD_CONF"
    info "PermitRootLogin yes set in ${SSHD_CONF}"

    # Also ensure PasswordAuthentication is not blocking us if using password
    if [[ -n "$ROOT_PASS" ]]; then
        sed -i '/^[[:space:]]*#*[[:space:]]*PasswordAuthentication/d' "$SSHD_CONF"
        echo "PasswordAuthentication yes" >> "$SSHD_CONF"
        info "PasswordAuthentication yes set"
    fi

    _restart_sshd

    # ── 3. optional: set root password ───────────────────────────────────────
    if [[ -n "$ROOT_PASS" ]]; then
        hdr "3/4  Setting root password"
        echo "root:${ROOT_PASS}" | chpasswd
        info "Root password updated"
    else
        hdr "3/4  Root password — skipped (no --pass given)"
    fi

    # ── 4. optional: inject SSH public key ────────────────────────────────────
    if [[ -n "$SSH_KEY" ]]; then
        hdr "4/4  Injecting SSH public key"
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        touch "$ROOT_AK"
        chmod 600 "$ROOT_AK"
        if grep -qF "$SSH_KEY" "$ROOT_AK" 2>/dev/null; then
            warn "Key already present in ${ROOT_AK}"
        else
            echo "$SSH_KEY" >> "$ROOT_AK"
            info "Key injected → ${ROOT_AK}"
        fi
    else
        hdr "4/4  SSH key injection — skipped (no --key given)"
    fi

    echo
    info "=== root-ssh installed ==="
    info "PermitRootLogin yes is active"
    [[ -n "$ROOT_PASS" ]] && info "Root password:  set"
    [[ -n "$SSH_KEY"   ]] && info "SSH key:        injected into ${ROOT_AK}"
    warn "Run 'remove' to restore original sshd_config from backup"
}

# ── remove ────────────────────────────────────────────────────────────────────

cmd_remove() {
    require_root

    hdr "Restoring sshd_config from backup"
    if [[ -f "$SSHD_BACKUP" ]]; then
        cp "$SSHD_BACKUP" "$SSHD_CONF"
        rm -f "$SSHD_BACKUP"
        info "Restored ${SSHD_CONF} from backup"
    else
        warn "No backup found at ${SSHD_BACKUP} — reverting PermitRootLogin manually"
        sed -i '/^[[:space:]]*PermitRootLogin yes/d' "$SSHD_CONF"
        echo "PermitRootLogin prohibit-password" >> "$SSHD_CONF"
        info "PermitRootLogin reset to prohibit-password"
    fi

    _restart_sshd
    info "=== root-ssh removed ==="
}

# ── status ────────────────────────────────────────────────────────────────────

cmd_status() {
    hdr "sshd_config — PermitRootLogin"
    grep -i 'PermitRootLogin' "$SSHD_CONF" \
        && true || echo "  (no PermitRootLogin directive found — default applies)"

    hdr "sshd_config — PasswordAuthentication"
    grep -i 'PasswordAuthentication' "$SSHD_CONF" \
        && true || echo "  (no PasswordAuthentication directive found — default applies)"

    hdr "Backup"
    [[ -f "$SSHD_BACKUP" ]] \
        && echo "  PRESENT  ${SSHD_BACKUP}" \
        || echo "  MISSING  ${SSHD_BACKUP} (not installed or already removed)"

    hdr "Root authorized_keys"
    if [[ -f "$ROOT_AK" ]]; then
        echo "  ${ROOT_AK}:"
        sed 's/^/    /' "$ROOT_AK"
    else
        echo "  MISSING  ${ROOT_AK}"
    fi

    hdr "sshd service"
    if command -v systemctl &>/dev/null; then
        systemctl status ssh 2>/dev/null || systemctl status sshd 2>/dev/null || true
    fi
}

# ── dispatch ──────────────────────────────────────────────────────────────────

CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install "$@" ;;
    remove)  cmd_remove       ;;
    status)  cmd_status       ;;
    *)
        echo "Usage: sudo $0 {install|remove|status}"
        echo
        echo "  install [--key 'ssh-ed25519 ...'] [--pass PASSWORD]"
        echo "            enable PermitRootLogin yes, optionally inject key / set password"
        echo "  remove    restore original sshd_config from backup"
        echo "  status    show current PermitRootLogin, authorized_keys, sshd state"
        ;;
esac
