#!/usr/bin/env bash
# =============================================================================
# sinkhole.sh — DNS sinkhole for a target domain on Ubuntu 24.04
# Uses dnsmasq to redirect all queries for the target (and subdomains) to a
# configurable sink IP. Logs all hits. Fully reversible.
#
# Usage:
#   sudo ./sinkhole.sh install   [--domain <domain>] [--sink-ip <ip>]
#   sudo ./sinkhole.sh remove
#   sudo ./sinkhole.sh status
#   sudo ./sinkhole.sh test
#
# Defaults:
#   --domain  yahoo.com
#   --sink-ip 127.0.0.1
# =============================================================================

set -euo pipefail

# --------------------------------------------------------------------------- #
# Defaults
# --------------------------------------------------------------------------- #
TARGET_DOMAIN="github.com"
SINK_IP="104.21.68.234"
DNSMASQ_CONF_DIR="/etc/dnsmasq.d"
SINKHOLE_CONF="${DNSMASQ_CONF_DIR}/sinkhole-${TARGET_DOMAIN//./-}.conf"
LOG_FILE="/var/log/dnsmasq-sinkhole.log"
BACKUP_RESOLV="/etc/resolv.conf.sinkhole.bak"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[-]${NC} $*" >&2; }
die()     { error "$*"; exit 1; }

require_root() {
    [[ $EUID -eq 0 ]] || die "Must be run as root (sudo $0 $*)"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --domain)   TARGET_DOMAIN="$2"; shift 2 ;;
            --sink-ip)  SINK_IP="$2";       shift 2 ;;
            *)          shift ;;
        esac
    done
    # Recompute conf path after parsing
    SINKHOLE_CONF="${DNSMASQ_CONF_DIR}/sinkhole-${TARGET_DOMAIN//./-}.conf"
}

# --------------------------------------------------------------------------- #
# install — set up the sinkhole
# --------------------------------------------------------------------------- #
cmd_install() {
    require_root

    info "Target domain : ${TARGET_DOMAIN} (+ all subdomains)"
    info "Sink IP       : ${SINK_IP}"
    info "Config file   : ${SINKHOLE_CONF}"
    info "Query log     : ${LOG_FILE}"

    # 1. Install dnsmasq if missing
    if ! command -v dnsmasq &>/dev/null; then
        info "Installing dnsmasq..."
        apt-get update -qq
        apt-get install -y dnsmasq
    else
        info "dnsmasq already installed: $(dnsmasq --version | head -1)"
    fi

    # 2. Disable systemd-resolved stub listener if active (port 53 conflict)
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        warn "systemd-resolved is running — disabling stub listener to free port 53"
        mkdir -p /etc/systemd/resolved.conf.d
        cat > /etc/systemd/resolved.conf.d/no-stub.conf <<'EOF'
[Resolve]
DNSStubListener=no
EOF
        systemctl restart systemd-resolved
        # Point resolv.conf at dnsmasq
        if [[ ! -e "$BACKUP_RESOLV" ]]; then
            cp /etc/resolv.conf "$BACKUP_RESOLV"
            info "Backed up /etc/resolv.conf → ${BACKUP_RESOLV}"
        fi
        echo "nameserver 127.0.0.1" > /etc/resolv.conf
        info "resolv.conf now points to 127.0.0.1"
    fi

    # 3. Enable dnsmasq.d includes in main conf (idempotent)
    if ! grep -q "^conf-dir=${DNSMASQ_CONF_DIR}" /etc/dnsmasq.conf 2>/dev/null; then
        echo "conf-dir=${DNSMASQ_CONF_DIR},*.conf" >> /etc/dnsmasq.conf
    fi

    # 4. Write the sinkhole drop-in
    mkdir -p "$DNSMASQ_CONF_DIR"
    cat > "${SINKHOLE_CONF}" <<EOF
# ----------------------------------------------------
# DNS Sinkhole: ${TARGET_DOMAIN}
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Sink IP: ${SINK_IP}
# ----------------------------------------------------

# Redirect apex + every subdomain to sink IP
address=/${TARGET_DOMAIN}/${SINK_IP}

# Log all queries that match to the sinkhole log
log-queries
log-facility=${LOG_FILE}
EOF

    info "Wrote sinkhole config: ${SINKHOLE_CONF}"

    # 5. Touch log file with correct perms
    touch "${LOG_FILE}"
    chmod 640 "${LOG_FILE}"

    # 6. Restart / enable dnsmasq
    # If no unit in the system paths (apt would use /lib/systemd/system/),
    # write our own to /etc/systemd/system/. Always overwrite so a stale unit
    # from a previous broken install doesn't linger.
    if ! systemctl cat dnsmasq.service &>/dev/null \
       || [[ -f /etc/systemd/system/dnsmasq.service ]]; then
        warn "Writing/updating dnsmasq.service unit"
        cat > /etc/systemd/system/dnsmasq.service <<'UNIT'
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/dnsmasq -k --conf-file=/etc/dnsmasq.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
        systemctl daemon-reload
    fi
    systemctl enable dnsmasq --quiet
    systemctl restart dnsmasq
    info "dnsmasq restarted"

    # 7. Verify
    sleep 1
    cmd_test

    echo
    info "Sinkhole ACTIVE. Monitor with:"
    echo "    tail -f ${LOG_FILE} | grep ${TARGET_DOMAIN}"
}

# --------------------------------------------------------------------------- #
# remove — tear down the sinkhole cleanly
# --------------------------------------------------------------------------- #
cmd_remove() {
    require_root

    if [[ -f "${SINKHOLE_CONF}" ]]; then
        rm -f "${SINKHOLE_CONF}"
        info "Removed ${SINKHOLE_CONF}"
    else
        warn "No sinkhole config found at ${SINKHOLE_CONF}"
    fi

    # Stop dnsmasq and remove our custom unit if we created it
    systemctl stop dnsmasq 2>/dev/null || true
    if [[ -f /etc/systemd/system/dnsmasq.service ]]; then
        systemctl disable dnsmasq --quiet 2>/dev/null || true
        rm -f /etc/systemd/system/dnsmasq.service
        systemctl daemon-reload
        info "Removed custom dnsmasq.service unit"
    fi

    # Restore stub listener if we disabled it
    if [[ -f /etc/systemd/resolved.conf.d/no-stub.conf ]]; then
        rm -f /etc/systemd/resolved.conf.d/no-stub.conf
        systemctl restart systemd-resolved
        info "Re-enabled systemd-resolved stub listener"
    fi

    # Restore resolv.conf if we backed it up
    if [[ -f "$BACKUP_RESOLV" ]]; then
        cp "$BACKUP_RESOLV" /etc/resolv.conf
        rm -f "$BACKUP_RESOLV"
        info "Restored /etc/resolv.conf"
    fi

    systemctl restart dnsmasq 2>/dev/null || true
    info "Sinkhole removed and DNS restored"
}

# --------------------------------------------------------------------------- #
# status — show current state
# --------------------------------------------------------------------------- #
cmd_status() {
    echo
    info "=== dnsmasq service ==="
    systemctl status dnsmasq --no-pager -l || true

    echo
    info "=== Active sinkhole configs ==="
    ls -1 "${DNSMASQ_CONF_DIR}"/sinkhole-*.conf 2>/dev/null \
        && grep "^address=" "${DNSMASQ_CONF_DIR}"/sinkhole-*.conf \
        || warn "No sinkhole configs found"

    echo
    info "=== Recent sinkhole hits (last 20 lines) ==="
    if [[ -f "${LOG_FILE}" ]]; then
        tail -20 "${LOG_FILE}" | grep "${TARGET_DOMAIN}" || echo "(no hits yet)"
    else
        warn "${LOG_FILE} does not exist yet"
    fi
}

# --------------------------------------------------------------------------- #
# test — verify resolution is landing on the sink IP
# --------------------------------------------------------------------------- #
cmd_test() {
    info "=== Resolution test ==="

    local tests=("${TARGET_DOMAIN}" "www.${TARGET_DOMAIN}" "mail.${TARGET_DOMAIN}" "api.${TARGET_DOMAIN}")

    for fqdn in "${tests[@]}"; do
        local result
        result=$(dig +short @127.0.0.1 "${fqdn}" A 2>/dev/null | head -1)
        if [[ "$result" == "$SINK_IP" ]]; then
            echo -e "  ${GREEN}✔${NC}  ${fqdn} → ${result}"
        else
            echo -e "  ${RED}✘${NC}  ${fqdn} → ${result:-<no answer>}  (expected ${SINK_IP})"
        fi
    done
}

# --------------------------------------------------------------------------- #
# Entry point
# --------------------------------------------------------------------------- #
CMD="${1:-help}"
shift || true
parse_args "$@"

case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    test)    cmd_test    ;;
    *)
        echo "Usage: sudo $0 {install|remove|status|test} [--domain <domain>] [--sink-ip <ip>]"
        echo
        echo "  install   Set up sinkhole (default: yahoo.com → 127.0.0.1)"
        echo "  remove    Tear down sinkhole and restore DNS"
        echo "  status    Show service state and recent hits"
        echo "  test      Verify resolution lands on sink IP"
        echo
        echo "Examples:"
        echo "  sudo $0 install"
        echo "  sudo $0 install --domain yahoo.com --sink-ip 10.0.0.1"
        echo "  sudo $0 remove"
        ;;
esac
