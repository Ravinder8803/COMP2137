#!/bin/bash

TARGET_IP="192.168.16.21"
HOSTNAME="server1"
USER_LIST=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

print_msg() {
  echo "[INFO] $1"
}

print_msg "Checking network configuration..."
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
if ! grep -q "$TARGET_IP" "$NETPLAN_FILE"; then
    print_msg "Updating IP to $TARGET_IP in netplan..."
    sed -i "s|address:.*|address: $TARGET_IP/24|" "$NETPLAN_FILE"
    netplan apply
    print_msg "Network updated."
else
    print_msg "Network already configured correctly."
fi

print_msg "Updating /etc/hosts..."
if ! grep -q "$TARGET_IP" /etc/hosts; then
    echo "$TARGET_IP $HOSTNAME" >> /etc/hosts
    print_msg "/etc/hosts updated."
else
    print_msg "/etc/hosts already correct."
fi

print_msg "Checking if Apache2 and Squid are installed..."
if ! dpkg -l | grep -q apache2; then
    apt-get update && apt-get install -y apache2
    systemctl enable --now apache2
    print_msg "Apache2 installed and started."
else
    print_msg "Apache2 already installed."
fi

if ! dpkg -l | grep -q squid; then
    apt-get install -y squid
    systemctl enable --now squid
    print_msg "Squid installed and started."
else
    print_msg "Squid already installed."
fi

for USER in "${USER_LIST[@]}"; do
    print_msg "Checking user $USER..."
    if ! id "$USER" &>/dev/null; then
        useradd -m -s /bin/bash "$USER"
        print_msg "User $USER created."
    else
        print_msg "User $USER already exists."
    fi

    if [ ! -d "/home/$USER/.ssh" ]; then
        mkdir -m 700 "/home/$USER/.ssh"
    fi
    if [ ! -f "/home/$USER/.ssh/authorized_keys" ]; then
        echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" > "/home/$USER/.ssh/authorized_keys"
    fi

    chown -R "$USER:$USER" "/home/$USER/.ssh"
    chmod 600 "/home/$USER/.ssh/authorized_keys"
    chmod 700 "/home/$USER/.ssh"
done

if ! groups dennis | grep -q "sudo"; then
    usermod -aG sudo dennis
    print_msg "Added 'dennis' to sudo group."
else
    print_msg "'dennis' already has sudo access."
fi

print_msg "Script completed successfully."
