# Red Team Persistence Toolkit

## 1. Tool Overview

### What the Tool Does
This tool is an Ansible-based automated persistence deployment framework targeting Ubuntu Linux systems. Once initial access is gained on a target machine, the toolkit deploys five independent persistence mechanisms simultaneously, ensuring that access is maintained even if one or more mechanisms are discovered and removed by the blue team.

### Why It's Useful for Red Team
In a red team vs. blue team competition, maintaining access after initial compromise is critical. Manually setting up persistence on each machine is slow under time pressure. This tool deploys all mechanisms in a single command across multiple targets simultaneously, freeing the red team to focus on lateral movement and objectives rather than re-exploitation.

### Category
- **Category:** Post-Exploitation / Persistence
- **MITRE ATT&CK Techniques Covered:**
  - T1053.003 — Scheduled Task/Job: Cron
  - T1543.002 — Create or Modify System Process: Systemd Service
  - T1546.004 — Event Triggered Execution: Unix Shell Configuration Modification
  - T1098 — Account Manipulation
  - T1556 — Modify Authentication Process

### High-Level Technical Approach
The toolkit uses Ansible playbooks to connect to target machines over SSH and deploy persistence scripts, modified configuration files, and backdoor accounts. All payloads are designed to blend in with normal system activity. A master playbook deploys all mechanisms in sequence, and a separate verify playbook confirms successful deployment.

---

## 2. Requirements & Dependencies

### Target Operating System
- Ubuntu Linux (tested on Ubuntu 22.04 / 24.04)
- Should work on most Debian-based distributions

### Attacker Machine Requirements
| Requirement | Version | Install Command |
|---|---|---|
| Ansible | 2.14+ | `sudo apt install ansible` |
| sshpass | Any | `sudo apt install sshpass` |
| Python3 | 3.8+ | Pre-installed on Kali |
| OpenSSH client | Any | Pre-installed on Kali |

Install all at once:
```bash
sudo apt update && sudo apt install ansible sshpass -y
```

### Required Privileges
- **Attacker machine:** Standard user with Ansible installed
- **Target machine:** A user account with `sudo` privileges (required for writing to system directories, modifying sshd_config, and managing systemd units)

### Prerequisites
- SSH access to target machines (password or key-based)
- Target machines must have Python3 installed (required by Ansible)
- Your listener IP and port must be reachable from target machines
- Ansible control node must have network access to all targets on port 22

---

## 3. Installation Instructions

### Step 1 — Clone or set up the project structure

### Step 2 — Configure inventory.ini
Update IPs with the targets.

### Step 3 — Configure group_vars/targets.yml
Update the callback IP with your attacker IP.

## 4. Usage Instructions

### Basic Usage — Deploy Everything
```bash
cd ~/redteam
ansible-playbook playbooks/deploy_all.yml
```

### Deploy Individual Mechanisms
```bash
ansible-playbook playbooks/cron_persistence.yml
ansible-playbook playbooks/systemd_timer_persistence.yml
ansible-playbook playbooks/systemd_service_persistence.yml
ansible-playbook playbooks/shell_profile_persistence.yml
ansible-playbook playbooks/service_misconfig.yml
```

### Verify Deployment
```bash
ansible-playbook playbooks/verify.yml
```

### Catch Callbacks
Start a listener on your attacker machine before deploying or before the persistence mechanisms fire:
```bash
nc -lvnp 4444
```

### Access Backdoor Account
```bash
ssh backup@<target_ip>
# password: backup123
sudo su -        # instant root shell
```

---

## 5. Operational Notes

### Competition Workflow
```
1. Update inventory.ini with target IPs and credentials
2. Update callback_ip in group_vars/targets.yml to your machine's IP
3. Open listener:         nc -lvnp 4444
4. Deploy:                ansible-playbook playbooks/deploy_all.yml
5. Verify:                ansible-playbook playbooks/verify.yml
6. Wait for callbacks or SSH in directly: ssh backup@<target_ip>
```

### Persistence Mechanism Summary
| Mechanism | Trigger | Reconnect Time | Survives Reboot |
|---|---|---|---|
| Cron job | Time-based | Every 1 minute | Yes |
| Systemd timer | Time-based + boot | 30s after boot, every 5 min | Yes |
| Systemd service | Always running | Within 30 seconds | Yes |
| Shell profile | User opens terminal | Immediate | Yes |
| SSH backdoor | Manual access | Instant | Yes |

### OpSec Considerations
**Logs created by this toolkit:**

| Mechanism | Log Location | What It Shows |
|---|---|---|
| Cron | `/var/log/syslog` | Cron job execution entries |
| Systemd timer/service | `journalctl -u sys-network-check` | Service start/stop events |
| Shell profile | None | Silent — uses setsid to detach |
| SSH backdoor | `/var/log/auth.log` | SSH login as `backup` user |
| sshd_config change | None | Config file modification only |

**Mitigations built in:**
- All service and script names use generic system-sounding names (`sys-network-check`, `sys-net-daemon`, `system_update_check`)
- Shell profile payload is stored in a hidden script file (`/usr/local/lib/.sys-diag.sh`) and calls it with a short innocuous line in profile files
- Systemd service output is redirected to null so nothing appears in journalctl
- The `backup` account is an existing system account — blue team checking for new accounts won't find anything suspicious
- The sudoers backdoor is buried in `/etc/sudoers.d/` with a name and content that looks like a legitimate hardening file

### Detection Risks
| Risk | Likelihood | Notes |
|---|---|---|
| Cron job spotted | Medium | Visible in `crontab -l` and `/etc/cron.d/` |
| Systemd units found | Medium | Visible in `systemctl list-units` |
| Shell profile injection found | Low | Short line calls a hidden script |
| backup account found | Low | Existing account, easy to overlook |
| sudoers file found | Low | Buried in `/etc/sudoers.d/` among other files |
| Network connection spotted | Medium | Outbound TCP on port 4444 visible in `netstat` |

### Cleanup / Removal Process
Run the following on each target to fully remove all persistence mechanisms:
```bash
# Remove cron
sudo crontab -r
sudo rm /etc/cron_helper.sh /etc/cron.d/system_update_check

# Remove systemd units
sudo systemctl stop sys-network-check.timer sys-net-daemon.service
sudo systemctl disable sys-network-check.timer sys-net-daemon.service
sudo rm /etc/systemd/system/sys-network-check.{timer,service}
sudo rm /etc/systemd/system/sys-net-daemon.service
sudo systemctl daemon-reload

# Remove shell profile injections
sudo sed -i '/sys-diag/d' /etc/bash.bashrc /etc/profile
sudo rm /etc/profile.d/sys-diag.sh /usr/local/lib/.sys-diag.sh

# Remove SSH backdoor
sudo sed -i 's/AuthorizedKeysFile .ssh\/authorized_keys .ssh\/.cache/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
sudo rm /home/backup/.ssh/.cache
sudo usermod -s /usr/sbin/nologin backup
sudo systemctl restart ssh

# Remove sudoers backdoor
sudo rm /etc/sudoers.d/99-sys-defaults
```

---

## 6. Limitations

### What the Tool Cannot Do
- Cannot gain initial access — requires existing SSH credentials or foothold
- Cannot bypass 2FA or certificate-based SSH authentication
- Does not exfiltrate data — callbacks only provide a reverse shell
- Does not work on non-systemd Linux distributions
- Cannot persist through full OS reinstallation

### Known Issues
- Shell profile mechanism may not fire on non-interactive SSH sessions (e.g., `ssh user@host command`)
- If blue team changes the `backup` account password, SSH backdoor access is lost
- Cron callbacks may flood your listener if multiple targets fire simultaneously — use a multi-handler tool like Metasploit's `exploit/multi/handler` for competitions with many targets
- The `pgrep` alive check uses the IP:port string which could fail if the process name doesn't contain it on some systems

### Future Improvement Ideas
- Add a multi-handler (Metasploit) integration to catch multiple shells simultaneously
- Add a `cleanup.yml` playbook to automate full removal
- Add encrypted/obfuscated payloads to evade basic signature detection
- Add a `--tags` system so individual mechanisms can be deployed or skipped selectively
- Support for additional callback methods (Python, Perl, curl) as fallbacks if bash TCP is blocked
- Add persistence via `~/.ssh/authorized_keys` injection across all user accounts

---

## 7. Credits & References
Had help from Claude for some of the coding.

### Notes
All techniques in this toolkit are based on publicly documented Linux administration features and well-known red team methodologies. No proprietary or unlicensed code was used.