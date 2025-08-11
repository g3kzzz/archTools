#!/bin/bash

# ========================
# Verificación de privilegios
# ========================
if [[ $EUID -eq 0 && -z "$SUDO_USER" ]]; then
  echo "[!] No ejecutes este script como root directamente."
  echo "    Usa: sudo $0"
  exit 1
fi

# ========================
# Autenticación sudo una sola vez
# ========================
echo "[*] Autenticando sudo..."
sudo -v

# Mantener sudo vivo
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID' EXIT

# ========================
# Listas de herramientas
# ========================
PACMAN_SCAN_TOOLS=(nmap-git arp-scan subfinder enum4linux-git smtp-user-enum-git)
YAY_SCAN_TOOLS=(nmap-git subfinder enum4linux-git smtp-user-enum-git)

PACMAN_CRACK_TOOLS=()
YAY_CRACK_TOOLS=(hashcat-git john-git hashcat-utils-git medusa hydra-git hash-identifier-git hashid)

PACMAN_EXPLOIT_TOOLS=(smbclient mssql-tools go-sqlcmd freerdp2 openssh)
YAY_EXPLOIT_TOOLS=(ruby-evil-winrm metasploit-git crowbar proxychains-ng-git powershell)

PACMAN_NET_TOOLS=(wireshark-qt gnu-netcat socat)
YAY_NET_TOOLS=(netexec)

YAY_FUZZ_TOOLS=(burpsuite)

PACMAN_UTILS=(openvpn tree locate exiftool wget nfs-utils)

# ========================
# Instalación con pacman
# ========================
echo "[*] Instalando herramientas de pacman..."
sudo pacman -S --needed --noconfirm \
  "${PACMAN_SCAN_TOOLS[@]}" \
  "${PACMAN_CRACK_TOOLS[@]}" \
  "${PACMAN_EXPLOIT_TOOLS[@]}" \
  "${PACMAN_NET_TOOLS[@]}" \
  "${PACMAN_UTILS[@]}"

# ========================
# Instalación con yay (AUR)
# ========================
if [[ -n "$SUDO_USER" ]]; then
  echo "[*] Instalando herramientas de yay (AUR)..."
  sudo -u "$SUDO_USER" yay -S --needed --noconfirm \
    "${YAY_SCAN_TOOLS[@]}" \
    "${YAY_CRACK_TOOLS[@]}" \
    "${YAY_EXPLOIT_TOOLS[@]}" \
    "${YAY_NET_TOOLS[@]}" \
    "${YAY_FUZZ_TOOLS[@]}"
else
  echo "[!] No se pudo instalar AUR porque no se detectó SUDO_USER."
fi

# ========================
# Instalaciones especiales
# ========================
sudo pacman -S --needed --noconfirm python-pyasn1-modules --overwrite "/usr/lib/python3.13/site-packages/*"

echo "[✔] Instalación completada."
