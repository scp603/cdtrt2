#!/bin/bash
# Autonomous hidden network namespace deployment

echo "[*] Initializing Phantom Network setup..."

PHYSICAL_IFACE="ens3"

NAMESPACE="phantom01"
VIRTUAL_IFACE="macvlan0"
SUBNET_PREFIX="10.10.10" # CHANGE THIS

# Generate a random, locally administered MAC address
RANDOM_MAC=$(printf "02:%02x:%02x:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

# Generate a random IP suffix between 150 and 250
IP_SUFFIX=$(( (RANDOM % 100) + 150 ))
STATIC_IP="${SUBNET_PREFIX}.${IP_SUFFIX}/24"

echo "[*] Target Interface: $PHYSICAL_IFACE"
echo "[*] Assigned MAC: $RANDOM_MAC"
echo "[*] Assigned IP: $STATIC_IP"

# Create the hidden network namespace (ignore error if it already exists)
ip netns add $NAMESPACE 2>/dev/null

# Create the native macvlan interface
ip link add $VIRTUAL_IFACE link $PHYSICAL_IFACE type macvlan mode bridge

# Move the virtual interface into the hidden namespace
ip link set $VIRTUAL_IFACE netns $NAMESPACE

# Configure the namespace interface with our generated MAC and IP, then bring it up
ip netns exec $NAMESPACE ip link set dev $VIRTUAL_IFACE address $RANDOM_MAC
ip netns exec $NAMESPACE ip addr add $STATIC_IP dev $VIRTUAL_IFACE
ip netns exec $NAMESPACE ip link set dev $VIRTUAL_IFACE up

# Bring up the loopback interface inside the namespace (required for some tools)
ip netns exec $NAMESPACE ip link set dev lo up

# Launch a decoy service INSIDE the hidden namespace
# (This spawns a netcat listener on port 22 that the host OS cannot see)
nohup ip netns exec $NAMESPACE nc -l -p 22 > /dev/null 2>&1 &

echo "[+] Phantom network deployed successfully. Hiding in the shadows."
