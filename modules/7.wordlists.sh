#!/usr/bin/env bash
# 7.wordlists.sh - Wordlists installer for ArchTools (quiet mode)
# Author: g3kzzz (patched) + improvements for rockyou archives
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
info() {
  if [ "$QUIET" -eq 0 ]; then
    printf '%s\n' "$*"
  fi
}
warn() {
  # always show warnings (useful when QUIET=1)
  printf '%s\n' "$*" >&2
}

run_quiet() {
  if [ "$QUIET" -eq 1 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

# Check required extraction tools (informative only)
_check_tools() {
  local missing=0
  command -v unzip >/dev/null 2>&1 || { warn "[!] 'unzip' not found — .zip extraction may fail"; missing=1; }
  command -v tar >/dev/null 2>&1 || { warn "[!] 'tar' not found — .tar(.gz/.xz) extraction may fail"; missing=1; }
  command -v 7z >/dev/null 2>&1 || command -v 7za >/dev/null 2>&1 || { warn "[!] '7z' (p7zip) not found — .7z extraction may fail"; }
  return $missing
}

extract_archive() {
  # $1 = path to archive
  # $2 = destination dir (should exist)
  local archive="$1"
  local dest="$2"
  local lc="$(echo "$archive" | awk '{print tolower($0)}')"

  if [[ "$lc" == *.zip ]]; then
    if command -v unzip >/dev/null 2>&1; then
      if ! run_quiet unzip -o "$archive" -d "$dest"; then
        warn "[!] unzip failed for $archive"
        return 1
      fi
    else
      warn "[!] unzip not available for $archive"
      return 1
    fi
  elif [[ "$lc" == *.tar.gz ]] || [[ "$lc" == *.tgz ]]; then
    if ! run_quiet tar -xzf "$archive" -C "$dest"; then
      warn "[!] tar -xzf failed for $archive"
      return 1
    fi
  elif [[ "$lc" == *.tar.xz ]] || [[ "$lc" == *.txz ]]; then
    if ! run_quiet tar -xJf "$archive" -C "$dest"; then
      warn "[!] tar -xJf failed for $archive"
      return 1
    fi
  elif [[ "$lc" == *.tar ]]; then
    if ! run_quiet tar -xf "$archive" -C "$dest"; then
      warn "[!] tar -xf failed for $archive"
      return 1
    fi
  elif [[ "$lc" == *.gz ]] && [[ "$lc" != *.tar.gz ]]; then
    # single-file gzip (e.g., rockyou.txt.gz)
    if command -v gunzip >/dev/null 2>&1; then
      local fname
      fname="$(basename "$archive" .gz)"
      if ! run_quiet cp "$archive" "$dest/"; then
        warn "[!] copy failed for $archive"
        return 1
      fi
      if ! run_quiet gunzip -f "$dest/$(basename "$archive")"; then
        warn "[!] gunzip failed for $archive"
        return 1
      fi
    else
      warn "[!] gunzip not available for $archive"
      return 1
    fi
  elif [[ "$lc" == *.7z ]]; then
    if command -v 7z >/dev/null 2>&1 || command -v 7za >/dev/null 2>&1; then
      if ! run_quiet 7z x -y "$archive" -o"$dest" >/dev/null 2>&1; then
        warn "[!] 7z extraction failed for $archive"
        return 1
      fi
    else
      warn "[!] 7z not installed for $archive"
      return 1
    fi
  else
    warn "[!] Unknown archive type: $archive (skipped)"
    return 1
  fi

  return 0
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

_check_tools || true

# --- SecLists ---
if [ ! -d "$SECLISTS_DIR" ]; then
  TMP_SECLISTS="$(mktemp -d)"
  if run_quiet git clone --depth 1 "$SECLISTS_REPO" "$TMP_SECLISTS"; then
    if ! run_quiet sudo rm -rf "$SECLISTS_DIR" 2>/dev/null; then true; fi
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
  # Copy files into WORDLISTS_DIR
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

# --- Extract archives and handle rockyou variants ---
shopt -s nullglob
for archive in "$WORDLISTS_DIR"/*; do
  # handle only archives we care about (zip, gz, 7z, tar*)
  case "${archive,,}" in
    *.zip|*.tar|*.tgz|*.tar.gz|*.tar.xz|*.txz|*.gz|*.7z)
      name="$(basename "$archive")"
      # choose a temp destination per-archive to avoid collisions
      dest="$WORDLISTS_DIR/.extract_${name%.*}"
      mkdir -p "$dest"
      info "Extracting $name -> $dest"
      if extract_archive "$archive" "$dest"; then
        # Flatten if single top-level dir
        subdir="$(find "$dest" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
        if [ -n "$subdir" ] && [ "$(find "$dest" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
          run_quiet mv "$subdir"/* "$dest"/ 2>/dev/null || true
          run_quiet rmdir "$subdir" 2>/dev/null || true
        fi

        # SPECIAL: rockyou handling
        # Find any rockyou file inside extracted folder (case-insensitive)
        rock="$(find "$dest" -type f -iname "rockyou*" | head -n1 || true)"
        if [ -n "$rock" ]; then
          info "Found rockyou candidate: $rock"
          # If it's gz, decompress to final name
          lcrock="$(echo "$rock" | awk '{print tolower($0)}')"
          if [[ "$lcrock" == *.gz ]]; then
            if command -v gunzip >/dev/null 2>&1; then
              # copy and gunzip to final location
              run_quiet cp -f "$rock" "$WORDLISTS_DIR/rockyou.txt.gz" 2>/dev/null || true
              if run_quiet gunzip -f "$WORDLISTS_DIR/rockyou.txt.gz"; then
                info "rockyou.txt.gz decompressed -> $WORDLISTS_DIR/rockyou.txt"
              else
                warn "[!] Failed to gunzip rockyou candidate: $rock"
              fi
            else
              warn "[!] gunzip not available for $rock"
            fi
          else
            # move/copy plain rockyou (txt or similar) to main dir
            run_quiet mv -f "$rock" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || run_quiet cp -f "$rock" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || true
            info "rockyou placed at $WORDLISTS_DIR/rockyou.txt"
          fi
          # remove extracted folder after rockyou moved (keep other files removed to avoid duplicates)
          run_quiet rm -rf "$dest" 2>/dev/null || true
        else
          # not rockyou: move extracted content into a directory named after the archive (without extension)
          base="$(basename "$archive")"
          base="${base%.*}"  # first strip one extension (.zip)
          # strip another extension for e.g. .tar.gz: handle common double-exts
          case "${base,,}" in
            *.tar|*.tar.gz|*.tar.xz) base="${base%.*}" ;;
          esac
          target="$WORDLISTS_DIR/$base"
          mkdir -p "$target"
          run_quiet mv "$dest"/* "$target"/ 2>/dev/null || true
          run_quiet rmdir "$dest" 2>/dev/null || true
        fi

        # remove original archive file
        run_quiet rm -f "$archive" 2>/dev/null || true
      else
        warn "[!] Extraction failed for $archive (kept as-is)"
        # do not rm the archive so user can inspect
      fi
      ;;
    *)
      # ignore non-archive files
      ;;
  esac
done
shopt -u nullglob

# Clean up empty dirs and fix perms (silent)
run_quiet find "$WORDLISTS_DIR" -type d -empty -delete 2>/dev/null || true
if ! run_quiet sudo chown -R "$USER:$USER" "$WORDLISTS_DIR"; then
  err "[!] Failed to chown $WORDLISTS_DIR"
  exit 1
fi

# final check: if rockyou still not present try to find compressed variants in root and decompress
if [ ! -f "$WORDLISTS_DIR/rockyou.txt" ]; then
  # try gz
  if [ -f "$WORDLISTS_DIR/rockyou.txt.gz" ]; then
    if command -v gunzip >/dev/null 2>&1; then
      if ! run_quiet gunzip -f "$WORDLISTS_DIR/rockyou.txt.gz"; then
        warn "[!] Could not decompress $WORDLISTS_DIR/rockyou.txt.gz"
      fi
    else
      warn "[!] gunzip missing to decompress rockyou.txt.gz in $WORDLISTS_DIR"
    fi
  fi

  # try other common names
  if [ ! -f "$WORDLISTS_DIR/rockyou.txt" ]; then
    candidate="$(find "$WORDLISTS_DIR" -type f -iname "rockyou*.txt*" -maxdepth 2 | head -n1 || true)"
    if [ -n "$candidate" ]; then
      run_quiet mv -f "$candidate" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || run_quiet cp -f "$candidate" "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || true
      info "Moved rockyou candidate $candidate -> $WORDLISTS_DIR/rockyou.txt"
    fi
  fi
fi

# Success: no output in quiet mode (but warnings/errors are shown)
exit 0

