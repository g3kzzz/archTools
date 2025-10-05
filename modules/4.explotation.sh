#!/usr/bin/env bash
# explotation.sh - Exploitation tools installer

set -euo pipefail

echo "[*] Installing exploitation tools..."

sudo pacman -S --needed --noconfirm metasploit sqlmap hydra medusa john hashcat exploitdb searchsploit python-pip >/dev/null 2>&1 || true

if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm crackmapexec netexec burpsuite >/dev/null 2>&1 || true
else
    echo "[*] yay not found, skipping AUR exploitation tools."
fi

echo "[✓] Exploitation tools installed."

