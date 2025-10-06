#!/usr/bin/env bash
# 7.wordlists.sh - Wordlists installer for ArchTools (quiet mode)
# Author: g3kzzz (patched)
# Description: Installs common wordlists under /usr/share/wordlists.
# By default this script is silent on success; errors are printed.

set -euo pipefail

# Set QUIET=1 for silent (default). Set to 0 to enable informative output.
QUIET=${QUIET:-1}

WORDLISTS_DIR="/usr/share/wordlists"
SECLISTS_DIR="/usr/share/SecLists"
SECLISTS_REPO="https://github.com/danielmiessler/SecLists.git"
WORDLISTS_REPO="https://github.com/g333k/wordlists.git"

# helpers
err() { printf '%s\n' "$*" >&2; }
run_quiet() {
  if [ "$QUIET" -eq 1 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

# Create base dir (use sudo if needed). Only print errors.
if ! run_quiet sudo mkdir -p "$WORDLISTS_DIR"; then
  err "[!] Failed to create $WORDLISTS_DIR"
  exit 1
fi
if ! run_quiet sudo chown "$USER:$USER" "$WORDLISTS_DIR"; then
  err "[!] Failed to chown $WORDLISTS_DIR"
  exit 1
fi

# --- SecLists ---
if [ ! -d "$SECLISTS_DIR" ]; then
  TMP_SECLISTS="$(mktemp -d)"
  if run_quiet git clone --depth 1 "$SECLISTS_REPO" "$TMP_SECLISTS"; then
    if ! run_quiet sudo rm -rf "$SECLISTS_DIR" 2>/dev/null; then
      # non-fatal: continue
      true
    fi
    if ! run_quiet sudo mv "$TMP_SECLISTS" "$SECLISTS_DIR"; then
      err "[!] Failed to move SecLists into $SECLISTS_DIR"
      rm -rf "$TMP_SECLISTS"
      exit 1
    fi
    if ! run_quiet sudo chown -R "$USER:$USER" "$SECLISTS_DIR"; then
      err "[!] Failed to chown $SECLISTS_DIR"
      exit 1
    fi
  else
    rm -rf "$TMP_SECLISTS"
    err "[!] Failed to clone SecLists. Run with QUIET=0 or run the clone manually to see details."
    exit 1
  fi
fi

# --- Wordlists repo ---
TMP_REPO="$(mktemp -d)"
if run_quiet git clone --depth 1 "$WORDLISTS_REPO" "$TMP_REPO"; then
  # copy contents silently; cp may succeed even if nothing to copy
  if ! run_quiet cp -r "$TMP_REPO"/* "$WORDLISTS_DIR"/ 2>/dev/null; then
    # non-fatal, continue to extraction (may be empty)
    true
  fi
  rm -rf "$TMP_REPO"
else
  rm -rf "$TMP_REPO"
  err "[!] Failed to clone wordlists repo. Run with QUIET=0 to see why."
  exit 1
fi

# --- Extract archives (silent) ---
shopt -s nullglob
for zipfile in "$WORDLISTS_DIR"/*.zip; do
  name="$(basename "$zipfile" .zip)"
  dest="$WORDLISTS_DIR/$name"
  mkdir -p "$dest"
  # unzip quietly; on failure warn and continue
  if ! run_quiet unzip -o "$zipfile" -d "$dest"; then
    err "[!] Warning: unzip failed for $zipfile (ignored)"
    continue
  fi

  # Flatten single-folder structures
  subdir="$(find "$dest" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
  if [ -n "$subdir" ] && [ "$(find "$dest" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
    run_quiet mv "$subdir"/* "$dest"/ 2>/dev/null || true
    run_quiet rmdir "$subdir" 2>/dev/null || true
  fi

  # rockyou special-case
  if [[ "$name" == "rockyou.txt" ]] || [[ "$name" == "rockyou" ]]; then
    txtfile="$(find "$dest" -type f -iname "rockyou.txt" | head -n1 || true)"
    if [ -n "$txtfile" ]; then
      run_quiet mv -f "$txtfile" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || true
      run_quiet rm -rf "$dest" 2>/dev/null || true
    fi
  fi

  run_quiet rm -f "$zipfile"
done
shopt -u nullglob

# Clean up empty dirs and fix perms (silent)
run_quiet find "$WORDLISTS_DIR" -type d -empty -delete 2>/dev/null || true
if ! run_quiet sudo chown -R "$USER:$USER" "$WORDLISTS_DIR"; then
  err "[!] Failed to chown $WORDLISTS_DIR"
  exit 1
fi

# Success: no output in quiet mode
exit 0

