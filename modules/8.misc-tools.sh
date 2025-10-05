#!/usr/bin/env bash
# misc-tools.sh - Installs g3kzzz's Misc Tools (g3ktools) repository
# Author: g3kzzz
# Description: Clones and installs /tools from https://github.com/g3kzzz/tools,
#              copies binaries to /usr/bin, and runs setup scripts.

set -euo pipefail

REPO_URL="https://github.com/g3kzzz/tools"
DEST_DIR="/tools"

echo "[*] Installing g3kzzz Misc Tools (g3ktools)..."

# --- Remove existing /tools if exists ---
if [[ -d "$DEST_DIR" ]]; then
    echo "[*] Removing existing $DEST_DIR..."
    sudo rm -rf "$DEST_DIR"
fi

# --- Clone repo ---
echo "[*] Cloning repository from $REPO_URL..."
sudo git clone --quiet "$REPO_URL" "$DEST_DIR"
echo "[✓] Repository cloned at $DEST_DIR."

# --- Fix permissions ---
sudo chown -R "$USER:$USER" "$DEST_DIR"
sudo chmod -R 755 "$DEST_DIR"

# --- Copy /tools/bin binaries into /usr/bin ---
if [[ -d "$DEST_DIR/bin" ]]; then
    echo "[*] Copying binaries from $DEST_DIR/bin to /usr/bin..."
    sudo cp -a "$DEST_DIR/bin/"* /usr/bin/ 2>/dev/null || true
    sudo rm -rf "$DEST_DIR/bin"
    echo "[✓] Binaries installed in /usr/bin."
fi

# --- Run Linux & Windows setup scripts ---
if [[ -x "$DEST_DIR/linux/install_linux_tools.sh" ]]; then
    echo "[*] Running Linux tools installer..."
    sudo bash "$DEST_DIR/linux/install_linux_tools.sh"
fi

if [[ -x "$DEST_DIR/windows/install_windows_tools.sh" ]]; then
    echo "[*] Running Windows tools installer..."
    sudo bash "$DEST_DIR/windows/install_windows_tools.sh"
fi

# --- Clean up setup scripts ---
sudo rm -f "$DEST_DIR/linux/install_linux_tools.sh" 2>/dev/null || true
sudo rm -f "$DEST_DIR/windows/install_windows_tools.sh" 2>/dev/null || true

echo "[✓] g3kzzz Misc Tools installed successfully."

