#!/usr/bin/env bash
# reporting.sh - Reporting and documentation tools installer

set -euo pipefail

echo "[*] Installing reporting tools..."

sudo pacman -S --needed --noconfirm zip unzip jq graphviz >/dev/null 2>&1 || true

if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm libreoffice-fresh cherrytree >/dev/null 2>&1 || true
else
    echo "[*] yay not found, skipping AUR reporting tools."
fi

echo "[✓] Reporting tools installed."

