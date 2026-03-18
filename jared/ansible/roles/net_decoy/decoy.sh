#!/bin/bash
# decoy.sh - The Ghost Scanner

# The target subnet (You will need to change this to match the competition network!)
SUBNET="10.0.0" 

while true; do
    # 1. Pick a random IP on the subnet (1-254)
    TARGET="$SUBNET.$((RANDOM % 254 + 1))"
    
    # 2. Pick a highly suspicious port
    # 22 (SSH), 445 (SMB), 3389 (RDP), 4444 (Metasploit Default), 8080 (Web C2)
    PORTS=(22 445 3389 4444 8080)
    PORT=${PORTS[$RANDOM % ${#PORTS[@]}]}
    
    # 3. Use netcat to send a quick, noisy connection attempt
    # -z means scan only (don't send data), -w 1 means timeout after 1 second
    nc -z -w 1 $TARGET $PORT > /dev/null 2>&1
    
    # 4. Sleep for a very short, random time (1 to 3 seconds) for a high-speed sprint
    sleep $((RANDOM % 3 + 1))
done