#!/usr/bin/env bash
# 8.music.sh - Install a music player and copy music into ~/.config/music
# Style: minimal, non-interactive

set -euo pipefail

echo "[*] Installing music player and copying tracks..."

# Determine repo root (parent of modules/)
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSIC_SRC="$BASEDIR/music"
MUSIC_DEST="$HOME/.config/music"

# Install mpv if possible
if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm mpv >/dev/null 2>&1 || true
elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm mpv >/dev/null 2>&1 || true
fi

# Create destination and copy files if source exists
if [ -d "$MUSIC_SRC" ]; then
    mkdir -p "$MUSIC_DEST"
    # copy and overwrite, preserve attributes
    cp -a "$MUSIC_SRC"/. "$MUSIC_DEST"/ 2>/dev/null || true
    # ensure ownership is the user
    chown -R "$USER:$USER" "$MUSIC_DEST" 2>/dev/null || true
    echo "[✓] Music installed to $MUSIC_DEST."
else
    echo "[✖] Music source not found: $MUSIC_SRC"
    echo "[✓] Music player installation attempted."
    exit 0
fi

echo "[✓] Music setup completed."

