#!/bin/bash
# Install fish shell on Ubuntu 24.04, create fish-user, set fish as their shell

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root."
    exit 1
fi

# Install fish
apt-get update
apt-get install -y fish

# Create fish-user if it doesn't exist
if ! id "fish-user" &>/dev/null; then
    useradd -m -s "$(which fish)" fish-user
    echo "Created fish-user with fish shell."
else
    chsh -s "$(which fish)" fish-user
    echo "fish-user already exists. Shell changed to fish."
fi

echo "Done. fish-user shell: $(getent passwd fish-user | cut -d: -f7)"
