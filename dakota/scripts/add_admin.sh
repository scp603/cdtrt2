#!/bin/bash
# Usage: sudo ./add_admin.sh <username> <password>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

NEW_USER=$1
NEW_PASS=$2

# -M: Do not create home directory
# -G sudo: Add to the administrative group (use 'wheel' on RHEL/CentOS)
# -s /bin/bash: Set the default shell
useradd -M -G sudo -s /bin/bash "$NEW_USER"

# Update the password silently
echo "$NEW_USER:$NEW_PASS" | chpasswd

echo "User $NEW_USER created without home directory and added to sudoers."