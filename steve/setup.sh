#!/usr/bin/env bash
set -e

echo "[*] Updating system..."
sudo apt update -y

echo "[*] Installing core dependencies..."
sudo apt install -y \
  python3 \
  python3-pip \
  nmap \
  hydra \
  enum4linux \
  evil-winrm \
  smbclient \
  crackmapexec \
  netcat-traditional \
  seclists

echo "[*] Verifying installs..."

check_tool () {
  if command -v "$1" &> /dev/null; then
    echo "[+] $1 installed"
  else
    echo "[!] $1 missing"
  fi
}

check_tool python3
check_tool nmap
check_tool hydra
check_tool enum4linux
check_tool evil-winrm
check_tool smbclient
check_tool crackmapexec
check_tool nc

echo
echo "[+] Setup complete."
echo "[+] You're ready for SMB/AD + brute force workflow."