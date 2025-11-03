#!/usr/bin/env bash
# enumeration.sh - Enumeration tools installer

set -euo pipefail

echo "[*] Installing enumeration tools..."

sudo pacman -S --needed --noconfirm smbclient wfuzz enum4linux smbmap netcat whatweb kerbrute nmap net-tools onesixtyone hashid hash-identifier  >/dev/null 2>&1 || true

if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm gobuster ffuf feroxbuster subfinder enum4linux-ng >/dev/null 2>&1 || true
else
    echo "[*] yay not found, skipping AUR enumeration tools."
fi

echo "[✓] Enumeration tools installed."


