#!/bin/bash

# ========================
# Verificación de privilegios
# ========================
if [[ $EUID -ne 0 ]]; then
  echo "[!] Este script debe ejecutarse con sudo (como root)."
  exit 1
fi

# ========================
# Autenticación sudo una sola vez
# ========================
echo "[*] Autenticando sudo (una sola vez)..."
sudo -v

# Mantener sudo vivo
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID' EXIT

# ========================
# Listas de herramientas
# ========================

# Pacman
PACMAN_TOOLS=(
  openvpn
  openssh
  tree
  locate
  arp-scan
  exiftool
  socat
  gnu-netcat
  mysql
  wget
  freerdp2
  wireshark-qt
)

# Yay (AUR)
YAY_TOOLS=(
  hashcat-git
  ruby-evil-winrm
  john-git
  smtp-user-enum-git
  hashcat-utils-git
  medusa
  nmap-git
  hydra-git
  burpsuite
  powershell
  openssh
  metasploit-git
  crowbar
  proxychains-ng-git
  smbclient
  mssql-tools
  go-sqlcmd
  hash-identifier-git
  netexec
  subfinder
  enum4linux-git
  hashid
)

# ========================
# Instalación rápida
# ========================
echo "[*] Instalando herramientas de pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_TOOLS[@]}"

echo "[*] Instalando herramientas de yay (AUR)..."
sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${YAY_TOOLS[@]}"

# ========================
# Instalaciones especiales
# ========================
sudo pacman -S --needed --noconfirm python-pyasn1-modules --overwrite "/usr/lib/python3.13/site-packages/*"
sudo -u "$SUDO_USER" yay -S --needed --noconfirm enum4linux-git

echo "[✔] Instalación completada."
