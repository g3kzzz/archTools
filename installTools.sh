#!/bin/bash
set -e

# =============================
#   G3K ArchPentest Installer
# =============================

# 📛 Debe correr como root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Este script debe ejecutarse como root."
  exit 1
fi

# =============================
# FUNCIONES
# =============================

instalar_pacman() {
  for pkg in "$@"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "✅ CHECK $pkg INSTALADA"
    else
      if pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ CHECK $pkg INSTALADA"
      else
        echo "❌ CRUZ $pkg NO SE PUDO INSTALAR: error pacman"
      fi
    fi
  done
}

instalar_yay() {
  for pkg in "$@"; do
    if yay -Qi "$pkg" &>/dev/null; then
      echo "✅ CHECK $pkg INSTALADA"
    else
      if yay -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ CHECK $pkg INSTALADA"
      else
        echo "❌ CRUZ $pkg NO SE PUDO INSTALAR: error yay"
      fi
    fi
  done
}

clone_repo() {
  local repo="$1"
  local dir="$2"
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    echo "❗ Repo previo eliminado: $dir"
  fi
  if git clone "$repo" "$dir" &>/dev/null; then
    echo "✅ CHECK $(basename $dir) INSTALADA"
  else
    echo "❌ CRUZ $(basename $dir) NO SE PUDO INSTALAR: error git"
  fi
}

# =============================
# BASE DEPS
# =============================
instalar_pacman git base-devel unzip wget curl ruby rustup python-pip

rustup show &>/dev/null || rustup default stable &>/dev/null

# =============================
# YAY INSTALL
# =============================
if ! command -v yay &>/dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/yay.git &>/dev/null
  cd yay
  makepkg -si --noconfirm &>/dev/null
  cd ~
  echo "✅ CHECK yay INSTALADA"
else
  echo "✅ CHECK yay INSTALADA"
fi

# =============================
# TOOL LISTS
# =============================
PACMAN_TOOLS=(
  arp-scan smbclient mssql-tools go-sqlcmd freerdp2 openssh
  wireshark-qt gnu-netcat socat openvpn tree locate exiftool wget
  nfs-utils python-pyasn1-modules
)

YAY_TOOLS=(
  nmap-git subfinder enum4linux-git smtp-user-enum-git
  hashcat-git john-git hashcat-utils-git medusa hydra-git hash-identifier-git hashid
  ruby-evil-winrm metasploit-git crowbar proxychains-ng-git powershell netexec
  burpsuite responder whatweb
)

# =============================
# INSTALL TOOLS
# =============================
instalar_pacman "${PACMAN_TOOLS[@]}"
instalar_yay "${YAY_TOOLS[@]}"

# =============================
# EVIL-WINRM FIX
# =============================
if gem install --user-install evil-winrm --no-document &>/dev/null; then
  echo "✅ CHECK evil-winrm INSTALADA"
else
  echo "❌ CRUZ evil-winrm NO SE PUDO INSTALAR: error gem"
fi

GEM_PATH="$(ruby -e 'puts Gem.user_dir')/bin"
if ! echo $PATH | grep -q "$GEM_PATH"; then
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.bashrc
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.zshrc
fi

# =============================
# RESPONDER FIX
# =============================
if pip install --break-system-packages aioquic dnspython impacket netifaces &>/dev/null; then
  echo "✅ CHECK responder deps INSTALADAS"
else
  echo "❌ CRUZ responder deps NO SE PUDO INSTALAR: error pip"
fi

# =============================
# EXPLOITDB
# =============================
clone_repo "https://gitlab.com/exploit-database/exploitdb.git" "/opt/exploitdb"
ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit

# =============================
# WORDLISTS & SECLISTS
# =============================
USR_SHARE="/usr/share"
WORDLISTS_DIR="$USR_SHARE/wordlists"

clone_repo "https://github.com/danielmiessler/SecLists.git" "$USR_SHARE/SecLists"
clone_repo "https://github.com/g333k/wordlists.git" "$WORDLISTS_DIR"

FILES_TO_PROCESS=(
  "amass.zip" "dirb.zip" "dirbuster.zip" "dnsmap.txt" "fasttrack.txt"
  "fern-wifi.zip" "john.lst" "legion.zip" "metasploit.zip" "nmap.lst"
  "rockyou.txt.zip" "sqlmap.txt" "wfuzz.zip" "wifite.txt"
)

for file in "${FILES_TO_PROCESS[@]}"; do
  src="$WORDLISTS_DIR/$file"
  if [[ -f "$src" ]]; then
    if [[ "$file" == "rockyou.txt.zip" ]]; then
      unzip -o "$src" -d "$WORDLISTS_DIR" &>/dev/null && rm -f "$src"
      echo "✅ CHECK rockyou INSTALADA"
    elif [[ "$file" == *.zip ]]; then
      folder="${file%.zip}"
      rm -rf "$WORDLISTS_DIR/$folder"
      mkdir -p "$WORDLISTS_DIR/$folder"
      unzip -o "$src" -d "$WORDLISTS_DIR/$folder" &>/dev/null && rm -f "$src"
      echo "✅ CHECK $folder INSTALADA"
    else
      echo "✅ CHECK $file INSTALADA"
    fi
  fi
done

# =============================
# FIN
# =============================
echo
echo "🚀 Instalación completa. Powered by G3K"
