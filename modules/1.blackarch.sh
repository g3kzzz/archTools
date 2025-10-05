#!/usr/bin/env bash
# blackarch.sh - BlackArch repository installer for ArchTools
# Author: g3kzzz
# Description: Installs and updates the BlackArch repository on Arch Linux.

set -euo pipefail

echo "[*] Checking BlackArch repository..."

if grep -q "^\[blackarch\]" /etc/pacman.conf 2>/dev/null; then
    echo "[✓] BlackArch repository already present."
else
    echo "[*] Installing BlackArch repository..."
    cd /tmp || exit 1
    curl -s -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh >/dev/null 2>&1 || {
        echo "[✖] Failed to install BlackArch."
        exit 1
    }
    echo "[✓] BlackArch repository installed."
fi

echo "[*] Updating package databases..."
sudo pacman -Syy --noconfirm >/dev/null 2>&1
echo "[✓] Repositories updated."

echo "[*] Upgrading system packages..."
sudo pacman -Su --noconfirm >/dev/null 2>&1
echo "[✓] System upgraded."

echo "[✓] BlackArch setup completed."

