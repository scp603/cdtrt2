#!/usr/bin/env bash
# lock-busybox.sh — gates system busybox behind a secret token
# red team: set RT_TOK=<token> before invoking, or use the hidden binary directly
# blue team: gets a fake segfault — looks like busybox is corrupt/broken
#
# Usage:
#   sudo ./lock-busybox.sh install
#   sudo ./lock-busybox.sh remove
#   sudo ./lock-busybox.sh status

set -euo pipefail

SECRET="rt2025\!delta"
BACKUP_DIR="/var/cache/.syspkg"
HIDDEN_BIN="${BACKUP_DIR}/busybox.real"   # the real binary, for our own use

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

cmd_install() {
    require_root
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    # ── find every busybox binary on the system ───────────────────────────────
    hdr "1/3  Locating busybox installations"

    mapfile -t BB_LOCS < <(
        find /bin /usr/bin /sbin /usr/sbin /usr/local/bin -maxdepth 1 \
            -name "busybox" -o -name "busybox-static" 2>/dev/null
        command -v busybox 2>/dev/null || true
    )
    # deduplicate
    mapfile -t BB_LOCS < <(printf '%s\n' "${BB_LOCS[@]}" | sort -u)

    if [[ ${#BB_LOCS[@]} -eq 0 ]]; then
        warn "No busybox binary found — nothing to lock"
        exit 0
    fi

    info "Found: ${BB_LOCS[*]}"

    # back up the first real binary (all locs are usually the same binary)
    if [[ ! -f "$HIDDEN_BIN" ]]; then
        cp "${BB_LOCS[0]}" "$HIDDEN_BIN"
        chmod 700 "$HIDDEN_BIN"   # only root can call the real one directly
        info "Real binary saved to $HIDDEN_BIN (chmod 700)"
    else
        info "Backup already exists at $HIDDEN_BIN"
    fi

    # ── also update shadow-crond's copy if it exists ─────────────────────────
    # shadow-crond copies busybox to /usr/local/lib/.sysd — that copy is already
    # our private binary, chmod 700, so blue team can't call it directly
    SHADOW_CROND_BIN="/usr/local/lib/.sysd"
    if [[ -f "$SHADOW_CROND_BIN" ]]; then
        chmod 700 "$SHADOW_CROND_BIN"
        info "Locked down $SHADOW_CROND_BIN (chmod 700)"
    fi

    # ── drop the gated wrapper over every busybox location ───────────────────
    hdr "2/3  Installing gated wrapper"

    WRAPPER=$(cat <<EOF
#!/bin/bash
if [[ "\$RT_TOK" == "${SECRET}" ]]; then
    exec ${HIDDEN_BIN} "\$@"
fi
echo "Segmentation fault (core dumped)" >&2
exit 139
EOF
)

    for loc in "${BB_LOCS[@]}"; do
        # record original path for removal
        echo "$loc" >> "${BACKUP_DIR}/busybox-locs.txt"
        printf '%s\n' "$WRAPPER" > "$loc"
        chmod 755 "$loc"
        info "Wrapper installed at $loc"
    done

    # ── lock down applet symlinks ─────────────────────────────────────────────
    # busybox applets (e.g. /bin/ash, /bin/wget via busybox) are symlinks back
    # to the busybox binary — they already go through the wrapper now since the
    # binary they point to is the wrapper. no extra work needed.
    info "Applet symlinks go through the wrapper automatically"

    # ── show usage ────────────────────────────────────────────────────────────
    hdr "3/3  Done"
    info "Red team usage:"
    info "  RT_TOK=${SECRET} busybox <applet> [args]"
    info "  -- or use hidden binary directly: ${HIDDEN_BIN} <applet> [args]"
    echo
    warn "Blue team sees: Segmentation fault (core dumped)"
}

cmd_remove() {
    require_root

    [[ ! -f "$HIDDEN_BIN" ]] && { warn "No backup found at $HIDDEN_BIN"; exit 1; }

    hdr "Restoring busybox binaries"
    while IFS= read -r loc; do
        [[ -f "$loc" ]] || continue
        cp "$HIDDEN_BIN" "$loc"
        chmod 755 "$loc"
        info "Restored $loc"
    done < "${BACKUP_DIR}/busybox-locs.txt" 2>/dev/null || true

    chmod 755 "$HIDDEN_BIN"   # un-restrict the backup too
    rm -f "${BACKUP_DIR}/busybox-locs.txt"

    SHADOW_CROND_BIN="/usr/local/lib/.sysd"
    [[ -f "$SHADOW_CROND_BIN" ]] && chmod 755 "$SHADOW_CROND_BIN"

    info "Done"
}

cmd_status() {
    hdr "Wrapper check"
    BB=$(command -v busybox 2>/dev/null || echo "(not in PATH)")
    if [[ -f "$BB" ]]; then
        head -1 "$BB"
        grep -q "RT_TOK" "$BB" && info "Wrapper is in place at $BB" \
                               || warn "Wrapper NOT in place at $BB"
    fi

    hdr "Hidden binary"
    [[ -f "$HIDDEN_BIN" ]] && ls -la "$HIDDEN_BIN" || warn "Not found: $HIDDEN_BIN"

    hdr "Red team test (with token)"
    RT_TOK="${SECRET}" busybox echo "busybox works" 2>/dev/null \
        && info "Token auth OK" || warn "Token auth failed"

    hdr "Blue team test (no token)"
    out=$(busybox echo "test" 2>&1 || true)
    echo "  Output: $out"
    [[ "$out" =~ "Segmentation fault" ]] && info "Gate is working" || warn "Gate not active"
}

CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)
        echo "Usage: sudo $0 {install|remove|status}"
        ;;
esac
