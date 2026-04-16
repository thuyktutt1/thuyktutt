#!/bin/bash

echo "🚀 Setup VPS..."

apt update && apt upgrade -y

# XFCE + XRDP
apt install xfce4 xfce4-goodies xrdp dbus-x11 x11-xserver-utils -y

echo "startxfce4" > ~/.xsession
chmod 644 ~/.xsession

systemctl enable xrdp
systemctl restart xrdp

# Open port
ufw allow 3389 || true

# Swap
fallocate -l 2G /swapfile || true
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Download ARO
wget https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb

# Install ARO
apt install ./ARO_Desktop_latest_debian.deb -y || apt --fix-broken install -y

echo "✅ DONE"
