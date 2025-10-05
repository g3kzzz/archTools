#!/usr/bin/env bash
# 7.wordlists.sh - Wordlists installer for ArchTools
# Author: g3kzzz
# Description: Installs common wordlists for pentesting under /usr/share/wordlists.

set -euo pipefail

WORDLISTS_DIR="/usr/share/wordlists"
SECLISTS_DIR="/usr/share/SecLists"
SECLISTS_REPO="https://github.com/danielmiessler/SecLists.git"
WORDLISTS_REPO="https://github.com/g333k/wordlists.git"

echo "[*] Preparing wordlists..."
sudo mkdir -p "$WORDLISTS_DIR"
sudo chown "$USER:$USER" "$WORDLISTS_DIR"

# --- SecLists ---
if [ ! -d "$SECLISTS_DIR" ]; then
  echo "[*] Cloning SecLists..."
  git clone --depth 1 "$SECLISTS_REPO" "$SECLISTS_DIR" >/dev/null 2>&1
  echo "[✓] SecLists installed."
else
  echo "[✓] SecLists already present."
fi

# --- Wordlists repo ---
TMP_REPO="$(mktemp -d)"
echo "[*] Cloning wordlists repository..."
git clone --depth 1 "$WORDLISTS_REPO" "$TMP_REPO" >/dev/null 2>&1
echo "[✓] wordlists repository cloned."

# Move files to /usr/share/wordlists
cp -r "$TMP_REPO"/* "$WORDLISTS_DIR"/ 2>/dev/null || true
rm -rf "$TMP_REPO"

echo "[*] Extracting archives..."

find "$WORDLISTS_DIR" -type f -name "*.zip" | while read -r zipfile; do
  name="$(basename "$zipfile" .zip)"
  dest="$WORDLISTS_DIR/$name"


  mkdir -p "$dest"

  # Unzip contents quietly
  unzip -q -o "$zipfile" -d "$dest" >/dev/null 2>&1 || true

  # Flatten single-folder structures
  subdir="$(find "$dest" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
  if [ -n "$subdir" ] && [ "$(find "$dest" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
    mv "$subdir"/* "$dest"/ 2>/dev/null || true
    rmdir "$subdir" 2>/dev/null || true
  fi

  # Special case: rockyou.txt.zip → /usr/share/wordlists/rockyou.txt
  if [[ "$name" == "rockyou.txt" ]]; then
    txtfile="$(find "$dest" -type f -iname "rockyou.txt" | head -n1 || true)"
    if [ -n "$txtfile" ]; then
      mv -f "$txtfile" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || true
      rm -rf "$dest"
    fi
  fi

  # Remove zip after extraction
  rm -f "$zipfile"
done

# Remove empty dirs and fix permissions
find "$WORDLISTS_DIR" -type d -empty -delete 2>/dev/null || true
sudo chown -R "$USER:$USER" "$WORDLISTS_DIR"

echo "[✓] Wordlists ready."

