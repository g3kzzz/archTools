#!/usr/bin/env bash
# 10.lxdm.sh - Minimalist LXDM BlackArch installer

set -euo pipefail

echo "[*] Configuring LXDM for BlackArch..."

# Check if blackarch-config-lxdm is installed
if ! pacman -Qi blackarch-config-lxdm >/dev/null 2>&1; then
    echo "[*] blackarch-config-lxdm not found, installing..."
    sudo pacman -S --needed --noconfirm blackarch-config-lxdm
fi

# Validate directories exist
for dir in /etc/lxdm-blackarch /usr/share/lxdm-blackarch /usr/share/xsessions-blackarch; do
    if [ ! -d "$dir" ]; then
        echo "[!] Required directory $dir not found. Aborting."
        exit 1
    fi
done

# Copy configuration files
sudo cp -a /etc/lxdm-blackarch/* /etc/lxdm/ || true
sudo cp -a /usr/share/lxdm-blackarch/* /usr/share/lxdm/ || true
sudo cp -a /usr/share/xsessions-blackarch/* /usr/share/xsessions/ || true

# Enable and start LXDM
sudo systemctl enable lxdm.service
sudo systemctl start lxdm.service

echo "[✓] LXDM BlackArch configured successfully."
