#!/usr/bin/env bash
# gathering.sh - Information gathering tools installer

set -euo pipefail

echo "[*] Installing gathering tools..."

sudo pacman -S --needed --noconfirm nmap whois tree dnsutils traceroute curl wget git unzip >/dev/null 2>&1 || true

# AUR tools (if yay exists)
if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm theharvester amass subfinder assetfinder httprobe masscan >/dev/null 2>&1 || true
else
    echo "[*] yay not found, skipping AUR gathering tools."
fi

echo "[✓] Gathering tools installed."

