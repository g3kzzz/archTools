#!/usr/bin/env bash
# 10.lxdm.sh - Minimalist LXDM keyboard + config installer (silent)
# Author: g3kzzz
# Location: ~/archtools/modules

set -euo pipefail

# --- Helpers (silent) ---
_sudo() { sudo -n bash -c "$*" >/dev/null 2>&1 || sudo bash -c "$*"; } # try non-interactive then interactive
_backup_if_exists() {
    local path="$1"
    if [ -e "$path" ]; then
        local bak="${path}.$(date +%s).bak"
        _sudo "cp -a '$path' '$bak'" >/dev/null 2>&1 || true
    fi
}

# --- Detect keyboard layout (prefer X11 layout) ---
detect_layout() {
    local layout=""

    # 1) localectl (preferred)
    if command -v localectl >/dev/null 2>&1; then
        layout="$(localectl status 2>/dev/null | awk -F: '
            /X11 Layout/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }
            /VC Keymap/   { if (!found) { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit } }
        ')"
    fi

    # 2) setxkbmap (if X available)
    if [ -z "$layout" ] && command -v setxkbmap >/dev/null 2>&1; then
        layout="$(setxkbmap -query 2>/dev/null | awk '/layout/ {print $2; exit}')"
    fi

    # 3) /etc/vconsole.conf (fallback for consoles)
    if [ -z "$layout" ] && [ -f /etc/vconsole.conf ]; then
        layout="$(awk -F= '/^KEYMAP=/ {gsub(/"/,"",$2); print $2; exit}' /etc/vconsole.conf)"
    fi

    # 4) final fallback
    if [ -z "$layout" ]; then
        layout="us"
    fi

    # Normalize common names (simple mapping)
    case "$layout" in
        latam|LATAM|Latam|latn|la*) echo "latam" ;;
        es|es_ES|spanish|sp|es-* ) echo "es" ;;
        us|en_US|us-*|en* ) echo "us" ;;
        fr* ) echo "fr" ;;
        de* ) echo "de" ;;
        *) echo "$layout" ;;
    esac
}

# --- Main (silent) ---
# 1) Ensure package present (blackarch-config-lxdm). install if missing (non-interactive)
if ! pacman -Qi blackarch-config-lxdm >/dev/null 2>&1; then
    _sudo "pacman -S --needed --noconfirm blackarch-config-lxdm" || true
fi

# 2) Validate expected source dirs exist (fail if not)
for d in /etc/lxdm-blackarch /usr/share/lxdm-blackarch /usr/share/xsessions-blackarch; do
    if [ ! -d "$d" ]; then
        # If directories missing, abort quietly with non-zero exit (caller may handle)
        exit 1
    fi
done

# 3) Copy config files (make backups silently)
_backup_if_exists "/etc/lxdm"
_backup_if_exists "/usr/share/lxdm"
_backup_if_exists "/usr/share/xsessions"

_sudo "cp -a /etc/lxdm-blackarch/* /etc/lxdm/" || true
_sudo "cp -a /usr/share/lxdm-blackarch/* /usr/share/lxdm/" || true
_sudo "cp -a /usr/share/xsessions-blackarch/* /usr/share/xsessions/" || true

# 4) Detect layout and write X11 keyboard conf (ensures X sessions use it)
LAYOUT="$(detect_layout)"

XORG_DIR="/etc/X11/xorg.conf.d"
XORG_FILE="${XORG_DIR}/00-keyboard.conf"

_sudo "mkdir -p '$XORG_DIR'"

# backup existing
_backup_if_exists "$XORG_FILE"

# Write the minimal keyboard config (silent)
_sudo "cat > '$XORG_FILE' <<'EOF'
Section \"InputClass\"
    Identifier \"system-keyboard\"
    MatchIsKeyboard \"on\"
    Option \"XkbLayout\" \"${LAYOUT}\"
EndSection
EOF
" >/dev/null 2>&1 || true

# 5) Ensure LXDM will set the layout at greeter time: append setxkbmap to Xsetup if present,
#    otherwise create a minimal Xsetup file that runs setxkbmap (LXDM reads /etc/lxdm/Xsetup)
LXDM_XSETUP="/etc/lxdm/Xsetup"
if [ -f "$LXDM_XSETUP" ]; then
    _backup_if_exists "$LXDM_XSETUP"
    # Avoid duplicating entry: check quietly
    if ! sudo grep -q "setxkbmap" "$LXDM_XSETUP" >/dev/null 2>&1; then
        _sudo "printf '\n# ensure greeter uses system layout\nsetxkbmap ${LAYOUT} >/dev/null 2>&1 || true\n' >> '$LXDM_XSETUP'" >/dev/null 2>&1 || true
    fi
else
    # create minimal Xsetup that just sets the keyboard (owned by root)
    _sudo "cat > '$LXDM_XSETUP' <<'EOF'\n#!/bin/sh\nsetxkbmap ${LAYOUT} >/dev/null 2>&1 || true\nEOF" >/dev/null 2>&1 || true
    _sudo "chmod +x '$LXDM_XSETUP'" >/dev/null 2>&1 || true
fi

# 6) Enable & start lxdm service (best-effort, silent)
_sudo "systemctl enable lxdm.service" >/dev/null 2>&1 || true
_sudo "systemctl restart lxdm.service" >/dev/null 2>&1 || true

# Exit success (no stdout)
exit 0
