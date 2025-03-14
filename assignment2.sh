#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Define variables
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
HOSTS_FILE="/etc/hosts"
TARGET_IP="192.168.16.21"
TARGET_HOSTNAME="server1"
USERS=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
PUBLIC_KEY_DENNIS="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Ensure correct network configuration
echo "Checking network configuration..."
if ! grep -q "$TARGET_IP" "$NETPLAN_FILE"; then
    echo "Updating netplan configuration..."
    sed -i "/addresses:/c\            addresses: [$TARGET_IP/24]" "$NETPLAN_FILE"
    netplan apply
fi

# Ensure /etc/hosts is updated
echo "Checking hosts file..."
sed -i "/$TARGET_HOSTNAME/d" "$HOSTS_FILE"
echo "$TARGET_IP $TARGET_HOSTNAME" >> "$HOSTS_FILE"

# Ensure necessary packages are installed
echo "Ensuring required packages are installed..."
apt update
apt install -y apache2 squid
systemctl enable --now apache2 squid

# Ensure users exist and have correct configurations
echo "Checking user accounts..."
for USER in "${USERS[@]}"; do
    if ! id "$USER" &>/dev/null; then
        echo "Creating user: $USER"
        useradd -m -s /bin/bash "$USER"
    fi
    mkdir -p "/home/$USER/.ssh"
    chmod 700 "/home/$USER/.ssh"
    touch "/home/$USER/.ssh/authorized_keys"
    chmod 600 "/home/$USER/.ssh/authorized_keys"
    chown -R "$USER:$USER" "/home/$USER/.ssh"

done

# Ensure Dennis has sudo access and public key
echo "Configuring sudo access for dennis..."
usermod -aG sudo dennis
if ! grep -q "$PUBLIC_KEY_DENNIS" "/home/dennis/.ssh/authorized_keys"; then
    echo "$PUBLIC_KEY_DENNIS" >> "/home/dennis/.ssh/authorized_keys"
fi

# Confirm completion
echo "Configuration complete."
