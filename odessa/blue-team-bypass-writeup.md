# Blue Team Defense Bypass Writeup
## Target: hkspark/named (Blue Team Toolkit)
## Attacker: Odessa Red Team Toolkit

---

## Executive Summary

The blue team (hkspark/named) has a structured but predictable defense playbook covering password rotation, firewall hardening, cron lockdown, process killing, SSH session termination, reverse shell detection, file integrity monitoring, and service-specific hardening (Redis, FTP, Nginx/ModSecurity, AD). Their scripts are deployed via Ansible to all hosts, with a standardized installation at `/opt/cdt-blue-team/`.

This writeup maps each blue team defense to the specific odessa tools that bypass, evade, or neutralize it — and recommends engagement order.

---

## 1. Credential Rotation (`changeUserPass.sh` / `changeUserPass.py`)

### What They Do
- Rotate passwords for all users with UID 1000-65534
- Exclude: GREYTEAM, scoring, ansible, deliveryDriver
- Use `openssl rand -base64 12` for generation
- Apply via `chpasswd`

### How We Bypass

| Tool | Method |
|------|--------|
| **pam-backdoor** | Injects `pam_audit_log.so` as `auth sufficient` in `/etc/pam.d/common-auth`. The magic password `rt2025!delta` works for **any user regardless of password rotation**. Their password changes become irrelevant. |
| **infinite-users** | Converts all nologin service accounts (www-data, mysql, redis, nobody, etc.) to shell users with our password. These accounts are **outside the UID 1000-65534 range** so their rotation script never touches them. |
| **sudo-biNOry** | Creates a `sudoer` backdoor account on first sudo invocation. Since the blue team runs sudo constantly for their own hardening, this triggers automatically. The account persists across password rotations. |

### Priority
Deploy **pam-backdoor first** — it makes all their credential work pointless in one shot. Their PAM configs in `scripts/` show they use standard `common-auth`, which is exactly what we inject into.

---

## 2. Firewall Rules (`closeUnecessaryPorts.sh` / `ufw_setup.sh`)

### What They Do
- Reset UFW, default deny inbound/outbound
- Allow only: SSH (22), FTP (20-21), HTTPS (443)
- Service-specific scripts add Samba ports (139, 445) or DNS (53) per host

### How We Bypass

| Tool | Method |
|------|--------|
| **shadow-crond** | Hidden cron daemon runs `nft flush ruleset && iptables -F` every cycle. Disguised as `systemd-timesyncd-helper` — looks like NTP, not a firewall flusher. |
| **evil-timer** | User-level systemd timer (no root needed!) runs firewall flush every 10 minutes. Disguised as `python2-certbot.timer`. Even if they revoke our sudo, this keeps firing. |
| **poison-timer** | Injects `ExecStartPost` into their own legitimate timers (logrotate, man-db, fstrim). Every time Ubuntu's built-in maintenance runs, our firewall flush piggybacks on it. |
| **alias-bashrc** | Overrides the `sudo` function — every time a blue teamer runs sudo for anything, firewall gets flushed as a side effect. |
| **path-hijack** | Wraps common commands (python3, git, curl, etc.) — every invocation silently flushes firewall in the background. |

### Priority
Layer all of these. The blue team will notice the firewall is down and re-apply. We need redundancy — shadow-crond + evil-timer + poison-timer ensures at least one mechanism survives. The path-hijack and alias-bashrc are bonus: the blue team's own activity becomes our firewall-flush trigger.

### Key Insight
Their UFW scripts don't check for or clean systemd drop-ins, user-level timers, or PATH manipulation. They only configure UFW rules — they never verify those rules persist.

---

## 3. Cron Lockdown (`blockCron.sh`)

### What They Do
- Remove all user and system cron jobs
- `chmod 000` on cron directories (`/etc/cron.d`, `/etc/cron.daily`, etc.)
- Stop cron service

### How We Bypass

| Tool | Method |
|------|--------|
| **shadow-crond** | Runs a **completely separate crond binary** (busybox crond) from `/var/cache/.syspkg/crond` with its own crontab at `/var/cache/.syspkg/tabs/root`. Their `blockCron.sh` only touches the system cron — our shadow cron is invisible to it. |
| **evil-timer** | Uses **systemd timers**, not cron at all. Their cron lockdown is completely irrelevant. |
| **poison-timer** | Injects into existing systemd timers via drop-ins. Cron lockdown doesn't affect systemd timers. |
| **ureadahead-persist** | Systemd service persistence — runs on boot and every 15 minutes via systemd, not cron. |

### Key Insight
Their cron lockdown is comprehensive for **cron**, but they have **zero protection against systemd-based persistence**. Their `check_units.sh` script compares systemd units against a baseline, but only if someone runs it manually and only if the baseline was captured before we deployed. Deploy persistence tools **before** they capture baselines.

---

## 4. Process Killing (`killProcesses.sh` / `killProcess.py`)

### What They Do
- Maintain a whitelist of essential processes (including Apache, PHP-FPM, MySQL, Samba daemons)
- SIGKILL everything not on the whitelist
- Stop/disable CUPS unconditionally

### How We Bypass

| Tool | Method |
|------|--------|
| **shadow-crond** | Our crond runs under the name `systemd-timesyncd-helper` — if they whitelist systemd services (which they must for the system to function), our process survives. |
| **poison-timer** | No separate process — payloads run as `ExecStartPost` within **their own whitelisted services**. logrotate, man-db, fstrim are all standard Ubuntu processes they won't kill. |
| **path-hijack** | No persistent process — triggers only when a whitelisted command (python3, git, etc.) is invoked. By the time `killProcesses.sh` runs, the payload already executed and exited. |
| **vim-persist** | Fires on `VimEnter` autocmd — executes when someone opens vim, then the firewall flush runs in background and exits quickly. No persistent process to kill. |
| **pam-backdoor** | Not a process — it's a shared library loaded by PAM. There's nothing to kill. |

### Key Insight
Their process killer is a point-in-time sweep. Our tools are either disguised as system processes, event-triggered (no persistent process), or library-based. They need continuous monitoring, not one-shot kills.

---

## 5. SSH Session Termination (`killSSH.sh` / `killOtherSSHSessions.sh`)

### What They Do
- Whitelist specific IPs (10.10.10.5-106)
- Kill SSH sessions from non-whitelisted IPs
- SIGTERM then SIGKILL on sshd processes
- Option to lock accounts of unauthorized SSH users

### How We Bypass

| Tool | Method |
|------|--------|
| **infinite-users** | We SSH as service accounts (www-data, mysql, etc.). Their kill script checks IPs, not usernames for the standard version. If they lock accounts, we use pam-backdoor to authenticate anyway. |
| **pam-backdoor** | Even if they lock an account, PAM `sufficient` module fires first — magic password `rt2025!delta` bypasses account lock checks. |
| **webshells** | Don't need SSH at all. `shell.php` on LAMP targets gives command execution over HTTP (port 443, which their own firewall allows). |
| **persistence mechanisms** | Even if every SSH session is killed, our persistence (shadow-crond, evil-timer, poison-timer, path-hijack) keeps running autonomously. We don't need to stay connected. |

### Key Insight
Their IP whitelist (10.10.10.5-106) covers the competition subnet. If we pivot from a compromised host within that range, our SSH sessions appear whitelisted. Use compromised blue-ubnt boxes as jump hosts.

---

## 6. Reverse Shell Detection (`reverseShellDetection.sh`)

### What They Do
- Search for suspicious processes: nc, netcat, ncat, socat, bash -i, python -c, perl -e, ruby, php -r, lua
- Monitor established connections
- Log to `/var/log/reverse_shell_detection.log`
- Display active listeners

### How We Bypass

| Tool | Method |
|------|--------|
| **nuke-journal** | Wipe all logging first — even if detection fires, the log file gets nuked. Set `Storage=none` in journald so no new logs persist. |
| **no-audit** | Disable auditd, shadow auditctl with no-op. Their detection relies on process listing, but audit trail is gone. |
| **webshells** | PHP webshell runs as Apache child process — it's not `nc` or `socat`, it's `php-fpm` or `apache2`. Their detection regex doesn't match web server child processes executing commands. |
| **pam-backdoor** | We don't need reverse shells. We SSH in directly with the magic password. Normal SSH sessions don't trigger reverse shell detection. |
| **compromise-w-who** | Even if they check `w` or `who` for active sessions, they see our fake output — not our real sessions. |

### Key Insight
Their detection is signature-based (known process names). We avoid the signatures entirely by using SSH access (pam-backdoor) or web-based access (webshells) instead of reverse shells.

---

## 7. File Integrity Monitoring (`folderMonitor.sh` / `hashingSnapshot.py`)

### What They Do
- SHA256 checksums of monitored directories
- Compare snapshots to detect added/modified/removed files
- Must be run manually (no automated scheduling mentioned)

### How We Bypass

| Tool | Method |
|------|--------|
| **the-toucher** | Continuously touches random files across the filesystem, randomizing mtimes. This creates massive noise — their comparison will show hundreds of "modified" files, making real changes invisible in the flood. |
| **pam-backdoor** | Compiles in `/dev/shm` (RAM tmpfs), installs to `/lib/security/`. Their monitoring likely focuses on `/etc`, `/usr/bin`, `/home` — not PAM module directories. |
| **poison-timer** | Uses systemd drop-in directories (`/etc/systemd/system/<unit>.d/`). These are separate files, not modifications to existing units. If they baseline the unit files, drop-ins won't show as modifications. |
| **shadow-crond** | Installs to `/var/cache/.syspkg/` — an unusual location unlikely to be in their monitoring baseline. |
| **vim-persist** | Modifies `.vimrc` files — potentially caught, but buried in the-toucher noise. |

### Key Insight
Their FIM requires manual execution and baseline comparison. Deploy persistence tools **immediately** on first access — before they run the initial baseline. If we're already installed when they snapshot, we're part of the "clean" baseline.

---

## 8. User Creation Lockdown (`disableUserCreation.sh`)

### What They Do
- `chmod 000` on useradd, adduser, usermod, groupadd, groupmod
- Prevents standard account creation

### How We Bypass

| Tool | Method |
|------|--------|
| **infinite-users** | Doesn't create users — converts existing nologin service accounts. Symlinks `/usr/sbin/nologin` → `/bin/bash` and sets passwords directly via `/etc/shadow`. No need for useradd. |
| **pam-backdoor** | No user creation needed. Magic password works for **all existing accounts** including root. |
| **sudo-biNOry** | Creates the `sudoer` account by writing directly to `/etc/passwd` and `/etc/shadow` — bypasses the chmod'd binaries entirely. |

### Key Insight
chmod 000 on user management binaries is trivially bypassed by writing to `/etc/passwd` and `/etc/shadow` directly. As root, we can `echo` new entries.

---

## 9. Service-Specific Defenses

### 9a. Redis Hardening (`secure_redis.sh`)

**Their defenses**: Bind localhost, protected mode, requirepass, disable dangerous Lua commands

**Our bypass**: **redis_persist.sh** — if we get the password (check their Ansible inventory: `Cyberrange123!` is hardcoded in `hosts.ini`), we can write SSH keys or cron jobs via Redis `CONFIG SET dir/dbfilename` before they harden. Deploy **before** they run secure_redis.sh. Their Flask app (`app.py`) also has hardcoded Redis credentials.

### 9b. Nginx/ModSecurity WAF (`modsecurity_install.sh`)

**Their defenses**: ModSecurity with OWASP CRS in blocking mode

**Our bypass**: Our webshells use simple parameter-based execution (`?p=PASSWORD&c=COMMAND`). ModSecurity CRS may catch common payloads, but:
- Base64-encode commands to bypass pattern matching
- Use POST body instead of GET parameters
- If ModSecurity is installed after our webshell, the shell is already in place

### 9c. SSH Sandboxing (`sandbox_ssh.sh`)

**Their defenses**: Chroot jail with only bash, ls, cat, echo available

**Our bypass**: PAM backdoor fires **before** the chroot. The `sufficient` line in common-auth means authentication succeeds before sandbox restrictions apply. Also, their sandbox only applies to non-cyberrange users — compromise the cyberrange account (password likely `Cyberrange123!` per their Ansible inventory) for full access.

### 9d. AD/Domain Controller (`ADwombocombo.ps1`)

**Their defenses**: Password rotation (including krbtgt), Kerberos hardening, LSA RunAsPPL, NTLMv2 enforcement, SMB signing, audit logging

**Our bypass**: **ad_persist.sh** — DCSync for hash extraction before they rotate, golden ticket generation (they rotate krbtgt but we can re-extract after), AdminSDHolder abuse for persistent DA access. Key: **we have mbrown domain admin creds already** (per project memory). Act fast before they rotate.

---

## 10. Logging & Audit Neutralization

### What They Do
- Expanded Windows event logs
- Enhanced audit policies
- `ad_monitor.ps1` watching for Event 4625 (failed logins), 4720 (account creation), 4728/4732/4756 (group changes)
- `linux_monitor.sh` tracking SUID binaries, ports, users, cron jobs, failed SSH

### How We Neutralize

| Tool | Method |
|------|--------|
| **nuke-journal** | `Storage=none` in journald.conf + vacuum + delete. Their linux_monitor.sh can't read what doesn't exist. |
| **no-audit** | Disable auditd, shadow auditctl with no-op wrapper. Audit daemon appears running but logs to /dev/null. |
| **no-selinux** | Disable SELinux while `getenforce` reports "Enforcing". |
| **compromise-w-who** | Fake `w`/`who` output. Blue team can't see active sessions. |
| **nuke-journal** LogLevelMax drop-ins | Specifically targets ssh, sshd, cron, systemd-logind — the exact services their monitor watches. |

---

## 11. Ansible Deployment (`deploy-blue-team-scripts.yml`)

### What They Do
- Deploy all scripts via Ansible to `/opt/cdt-blue-team/`
- Target hosts from `hosts.ini`

### How We Exploit

Their `hosts.ini` contains:
```
ansible_user=cyberrange
ansible_password=Cyberrange123!
ansible_become_password=Cyberrange123!
```

**This is a goldmine.** The `cyberrange` account has sudo access on ALL hosts with password `Cyberrange123!`. If they don't rotate this immediately, we have instant root on every box.

Additionally, their Ansible deploys to a **known, fixed path** (`/opt/cdt-blue-team/`). We can:
1. Monitor this directory for new scripts
2. Modify deployed scripts to include our payloads (they become self-sabotaging)
3. Use `the-toucher` to mess with timestamps so they can't tell what we modified

---

## Recommended Engagement Order

### Wave 0 — Immediately on First Access (Race the Blue Team)
1. **pam-backdoor** — Guaranteed persistent access regardless of password changes
2. **nuke-journal** — Blind them before they can log our activity
3. **no-audit** — Kill the audit trail
4. **infinite-users** — Service account backdoors (outside their rotation scope)

### Wave 1 — Establish Persistence (Within First 5 Minutes)
5. **shadow-crond** — Hidden cron daemon for recurring payloads
6. **evil-timer** — User-level backup (survives sudo revocation)
7. **poison-timer** — Piggyback on their own system timers
8. **ureadahead-persist** — Boot persistence disguised as legacy service
9. **path-hijack** — Their own command usage triggers our payloads

### Wave 2 — Disrupt Blue Team Operations
10. **break-net-tools** — Kill curl/wget/git so they can't download tools or pull repo updates
11. **pihole-github-sinkhole** — Block GitHub entirely (their repo becomes unreachable)
12. **no-apt** — Cripple package management
13. **sinkhole-scripts** — DNS sinkhole for any other critical domains

### Wave 3 — Anti-Forensics & Deception
14. **compromise-w-who** — Hide our sessions
15. **no-selinux** — Disable enforcement while reporting "Enforcing"
16. **the-toucher** — Flood filesystem with mtime noise
17. **vim-persist** — Bonus: every vim open flushes their firewall

### Wave 4 — Establish Alternative Access
18. **webshells** — Deploy to LAMP (svc-samba-01) and Flask/Nginx (svc-redis-01)
19. **sudo-biNOry** — Sudo wrapper backdoor for persistent NOPASSWD access
20. **ad_persist** — Domain-level persistence using mbrown DA creds

### Wave 5 — Psychological Warfare
21. **alias-bashrc** — Every sudo they run taunts them and flushes their firewall
22. **vandalize-bashrc** — RT branding on every login

### Automation
Use **let-the-madness-begin.sh** or **mass-deploy.sh** to push waves in parallel across all 9 targets. Deploy via **rt-ssh.sh** which executes from `/dev/shm` (RAM) and self-deletes — no artifacts on disk for their file integrity monitor to catch.

---

## Critical Blue Team Weaknesses Summary

| Weakness | Exploit |
|----------|---------|
| Hardcoded Ansible creds (`Cyberrange123!`) in public repo | Instant root on all hosts |
| No systemd timer/unit monitoring (only cron lockdown) | shadow-crond, evil-timer, poison-timer all invisible |
| FIM requires manual execution, no auto-scheduling | Deploy before baseline captured |
| Process killer is point-in-time, not continuous | Event-triggered persistence survives sweeps |
| Reverse shell detection is signature-based | SSH via pam-backdoor + webshells avoid all signatures |
| No PAM module auditing | pam-backdoor completely undetected |
| No PATH integrity verification | path-hijack turns their own tools against them |
| User rotation only covers UID 1000-65534 | Service accounts (UID < 1000) are untouched |
| chmod-based lockdowns (trivially bypassed as root) | Direct /etc/passwd writes bypass useradd chmod |
| Scripts deployed to known fixed path | Can be tampered with or monitored |
| No `.vimrc` / profile.d monitoring | vim-persist and alias-bashrc go unnoticed |

---

*Generated by Odessa Red Team — CDTRT2*
