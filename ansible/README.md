# Ansible — Red Team Deployment Automation

## Structure

```
ansible/
├── ansible.cfg              # SSH config, jump host, timeouts
├── inventory.ini            # Target groups — fill IPs at comp time
├── group_vars/
│   └── all.yml              # lhost, lport, staging dir
├── site.yml                 # Master play — imports all phases
└── playbooks/
    ├── 00_recon_setup.yml   # Start reconboard-v5 on operator machine
    ├── 01_ping.yml          # Connectivity check against all targets
    └── 02_disrupt.yml       # Disruption scripts in correct order
```

## Pre-comp checklist

1. Fill in `inventory.ini` — add IPs to each `FILL_ME` host
2. Fill in `group_vars/all.yml` — set `lhost` to your operator IP
3. Confirm jump host access: `ssh sshjump@ssh.cyberrange.rit.edu`
4. Confirm target SSH access: `ansible-playbook site.yml --tags ping -l linux`

## Phase order

```
Phase 0 — Reconboard up (before touching targets)
Phase 1 — Connectivity check
Phase 2 — Initial access (MANUAL — exploit the vuln per box)
Phase 3 — Persistence (MANUAL — run persist/ scripts per box)
Phase 4 — Disruption (light)
Phase 5 — Disruption (heavy — run last, noisy)
```

**Do not run disruption until persistence is confirmed.**
If you disrupt before you have a stable backdoor you lock yourself out too.

## Commands

```bash
# Phase 0 — start reconboard locally
ansible-playbook site.yml --tags recon_setup -c local -i localhost,

# Phase 1 — ping all targets
ansible-playbook site.yml --tags ping -l linux

# Phase 4 — light disruption on all linux boxes
ansible-playbook site.yml --tags disrupt -l linux

# Phase 4 — light disruption on one box only
ansible-playbook site.yml --tags disrupt -l svc-ftp-01

# Phase 5 — heavy disruption (log flood + timestamp corruption + busybox lock)
ansible-playbook site.yml --tags heavy -l linux

# Both phases together on all linux
ansible-playbook site.yml --tags disrupt,heavy -l linux

# Dry run — see what would run without running it
ansible-playbook site.yml --tags disrupt -l linux --check
```

## Disruption script order (why)

| Step | Script | Reason for position |
|------|--------|---------------------|
| 1 | `no-apt.sh` | First — stops blue team from installing tools to fight back |
| 2 | `break-net-tools.sh` | Second — blocks curl/wget/git before they notice apt is broken |
| 3 | `no-audit.sh` | Third — blind audit before later steps make more noise |
| 4 | `no-selinux.sh` | Fourth — disable MAC enforcement before injecting files |
| 5 | `alias-bashrc.sh` | Injects sudo() fw flush into all .bashrc files |
| 6 | `vim-persist.sh` | Injects vimrc fw flush before blue team opens editors |
| 7 | `compromise-w-who.sh` | Fake session data — do before they start running w/who |
| 8 | `shadow-crond.sh` | Must come before lock-busybox (lock-busybox chowns its path) |
| H1 | `flood-journal.sh` | Heavy — very noisy, daemonized, run late |
| H2 | `the-toucher.sh` | Background timestamp corruption |
| H3 | `lock-busybox.sh` | Last — gates busybox after shadow-crond path exists |

## Busybox token

After `lock-busybox.sh` runs:
```bash
RT_TOK=rt2025!delta busybox <cmd>
# or use the real binary directly:
/var/cache/.syspkg/busybox.real <cmd>
```
