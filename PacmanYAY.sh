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
# Herramientas organizadas por enfoque
# ========================

# ----------------------------------------
# Escaneo y reconocimiento
# ----------------------------------------
PACMAN_SCAN_TOOLS=(
  nmap-git         # Escaneo de puertos y servicios
  arp-scan         # Escaneo ARP en red local
  subfinder        # Descubrimiento de subdominios
  enum4linux-git   # Enumeración SMB/AD
  smtp-user-enum-git  # Enumeración de usuarios SMTP
)

YAY_SCAN_TOOLS=(
  nmap-git
  arp-scan
  subfinder
  enum4linux-git
  smtp-user-enum-git
)

# ----------------------------------------
# Cracking / Password attacks
# ----------------------------------------
PACMAN_CRACK_TOOLS=(
  # (ninguna en pacman aquí)
)

YAY_CRACK_TOOLS=(
  hashcat-git       # Cracking de hashes con GPU
  john-git          # John The Ripper, cracking de contraseñas
  hashcat-utils-git # Utilidades para hashcat
  medusa            # Fuerza bruta paralela
  hydra-git         # Fuerza bruta multi-protocolo
  hash-identifier-git # Identificador de hashes
  hashid            # Identificador de hashes (alternativa)
)

# ----------------------------------------
# Explotación de servicios comunes
# ----------------------------------------
PACMAN_EXPLOIT_TOOLS=(
  smbclient         # Cliente SMB
  mssql-tools       # Herramientas para MSSQL
  go-sqlcmd         # Herramienta para SQL Server
  freerdp2          # Cliente RDP
  openssh           # SSH client/server
)

YAY_EXPLOIT_TOOLS=(
  ruby-evil-winrm  # Exploits y acceso WinRM (Windows Remoting)
  metasploit-git   # Framework de explotación
  crowbar          # Fuerza bruta en servicios comunes (SSH, RDP, SMB)
  proxychains-ng-git # Proxy para redirigir tráfico (útil para pentesting)
  powershell       # Shell para administración Windows y explotación
)

# ----------------------------------------
# Análisis y sniffing de red
# ----------------------------------------
PACMAN_NET_TOOLS=(
  wireshark-qt    # Análisis de tráfico de red
  gnu-netcat      # Netcat para conexiones TCP/UDP
  socat           # Multipropósito para conexiones de red
)

YAY_NET_TOOLS=(
  netexec         # Ejecución remota de comandos (netexec)
)

# ----------------------------------------
# Fuzzing y otras utilidades
# ----------------------------------------
YAY_FUZZ_TOOLS=(
  burpsuite       # Proxy para pruebas de seguridad web (fuzzing y más)
)

# ----------------------------------------
# Herramientas básicas y utilidades
# ----------------------------------------
PACMAN_UTILS=(
  openvpn         # VPN
  tree            # Visualización de directorios en árbol
  locate          # Búsqueda rápida de archivos
  exiftool        # Análisis de metadatos en archivos
  wget            # Descarga de archivos
  nfs-utils       # Utilidades para NFS
)

# ========================
# Instalación de paquetes
# ========================

echo "[*] Instalando herramientas de pacman..."

sudo pacman -S --needed --noconfirm \
  "${PACMAN_SCAN_TOOLS[@]}" \
  "${PACMAN_CRACK_TOOLS[@]}" \
  "${PACMAN_EXPLOIT_TOOLS[@]}" \
  "${PACMAN_NET_TOOLS[@]}" \
  "${PACMAN_UTILS[@]}"

echo "[*] Instalando herramientas de yay (AUR)..."

sudo -u "$SUDO_USER" yay -S --needed --noconfirm \
  "${YAY_SCAN_TOOLS[@]}" \
  "${YAY_CRACK_TOOLS[@]}" \
  "${YAY_EXPLOIT_TOOLS[@]}" \
  "${YAY_NET_TOOLS[@]}" \
  "${YAY_FUZZ_TOOLS[@]}"

# ========================
# Instalaciones especiales
# ========================

sudo pacman -S --needed --noconfirm python-pyasn1-modules --overwrite "/usr/lib/python3.13/site-packages/*"
sudo -u "$SUDO_USER" yay -S --needed --noconfirm enum4linux-git

echo "[✔] Instalación completada."
