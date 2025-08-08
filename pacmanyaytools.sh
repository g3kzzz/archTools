#!/bin/bash

# ========================
# Verificación de privilegios
# ========================
if [[ $EUID -ne 0 ]]; then
  echo "[!] Este script debe ejecutarse con sudo (como root)."
  exit 1
fi

# ========================
# Función para instalar
# ========================
instalar() {
  local tipo=$1
  local herramienta=$2

  if [[ "$tipo" == "pacman" ]]; then
    echo "[*] Instalando $herramienta..."
    sudo -u "$SUDO_USER" yay -S --noconfirm "$herramienta" &> /dev/null
  elif [[ "$tipo" == "yay" ]]; then
    echo "[*] Instalando $herramienta..."
    sudo -u "$SUDO_USER" yay -S --noconfirm "$herramienta" &> /dev/null
  fi

  if [[ $? -eq 0 ]]; then
    echo "[✔] $herramienta instalado correctamente."
  else
    echo "[✘] Error al instalar $herramienta."
  fi
}

# ========================
# Lista de herramientas
# ========================

# Pacman
PACMAN_TOOLS=(
  openvpn
  openssh
  tree
  locate
  exiftool
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
  hashcat-utils-git
  medusa
  seclists
  burpsuite
  powershell
  openssh
  metasploit-git
  smbclient
  mssql-tools
  go-sqlcmd
  
  smbmap
  hash-identifier-git
  enum4linux-git
  hashid
)

# ========================
# Instalar paquetes con pacman
# ========================
for tool in "${PACMAN_TOOLS[@]}"; do
  instalar pacman "$tool"
done

# ========================
# Instalar paquetes con yay
# ========================
for tool in "${YAY_TOOLS[@]}"; do
  instalar yay "$tool"
done

sudo pacman -S python-pyasn1-modules --overwrite "/usr/lib/python3.13/site-packages/*"
yay -S enum4linux-git
