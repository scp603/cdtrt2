#!/bin/bash
#
# Simple HTTP Beacon Setup Script
# Usage: ./quick-deploy.sh
#

echo "========================================"
echo "  HTTP Beacon Quick Deploy"
echo "========================================"
echo ""

# Step 1: Install dependencies
echo "[1/3] Installing dependencies..."
sudo apt update -qq
sudo apt install -y python3 python3-pip ansible sshpass > /dev/null 2>&1
pip3 install requests flask --break-system-packages > /dev/null 2>&1
echo "✓ Dependencies installed"
echo ""

# Step 2: Setup directories
echo "[2/3] Creating directories..."
mkdir -p ansible exfiltrated_files payloads tests docs examples
echo "✓ Directories created"
echo ""

# Step 3: Deploy
echo "[3/3] Deploying beacon..."
cd ansible
ansible-playbook -i inventory.ini deploy-beacon.yml
cd ..

echo ""
echo "========================================"
echo "  Deployment Complete!"
echo "========================================"
echo ""
echo "Start C2 server with:"
echo "  python3 c2_server.py"
echo ""