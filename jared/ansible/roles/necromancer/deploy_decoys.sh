#!/bin/bash
# deploy_decoys.sh - Floods the target with believable decoy accounts

echo "[*] Spawning decoy users..."

# 1. "Human" Accounts (gets a /home dir and a bash shell)
HUMANS=("jsmith" "mscott" "dshrute" "tflenderson" "pbeesly" "abernard" "dev_admin" "sys_backup")

for u in "${HUMANS[@]}"; do
    # -m creates the home directory, -s sets the shell
    useradd -m -s /bin/bash "$u" 2>/dev/null
    
    # Optional: Set a garbage password so they show up in /etc/shadow
    echo "$u:SuperSecurePassword123!" | chpasswd 2>/dev/null
done

# 2. "Service" Accounts (no /home dir, locked shell)
SERVICES=("redis_exporter" "prom_monitor" "node_telemetry" "db_sync_svc" "docker_helper")

for s in "${SERVICES[@]}"; do
    # -M forces NO home directory, -s sets a locked shell
    useradd -M -s /usr/sbin/nologin "$s" 2>/dev/null
done

echo "[+] Decoy users successfully deployed."
