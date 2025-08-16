#!/bin/bash
set -e

# =============================
#   G3K ArchPentest Installer
# =============================

# 📛 Debe correr como usuario normal
if [[ $EUID -eq 0 ]]; then
  echo "❌ No ejecutes este script directamente como root."
  echo "✅ Ejecútalo como usuario normal."
  exit 1
fi

# =============================
# PASSWORD HANDLING
# =============================
echo -n "🔑 Ingresa tu contraseña de sudo: "
read -s SUDO_PASS
echo

# Función sudo personalizada
run_sudo() {
  echo "$SUDO_PASS" | sudo -S "$@"
}

# =============================
# FUNCIONES AUXILIARES
# =============================

instalar_pacman() {
  for pkg in "$@"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "✅ $pkg ya instalada"
    else
      if echo "$SUDO_PASS" | sudo -S pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ $pkg instalada"
      else
        echo "❌ No se pudo instalar $pkg con pacman"
      fi
    fi
  done
}

instalar_yay() {
  for pkg in "$@"; do
    if yay -Qi "$pkg" &>/dev/null; then
      echo "✅ $pkg ya instalada"
    else
      if yay -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ $pkg instalada"
      else
        echo "❌ No se pudo instalar $pkg con yay"
      fi
    fi
  done
}

# =============================
# DEPENDENCIAS BASE
# =============================
instalar_pacman git base-devel unzip wget curl ruby rustup python-pip

# Rust por defecto estable
rustup show &>/dev/null || rustup default stable &>/dev/null

# =============================
# YAY INSTALL
# =============================
if ! command -v yay &>/dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/yay.git &>/dev/null
  cd yay
  makepkg -si --noconfirm <<<"$SUDO_PASS" &>/dev/null
  cd ~
  echo "✅ yay instalada"
else
  echo "✅ yay ya instalada"
fi

# =============================
# LISTAS DE HERRAMIENTAS
# =============================
PACMAN_TOOLS=(
  arp-scan smbclient freerdp2 openssh net-tools
  wireshark-qt gnu-netcat socat openvpn tree locate exiftool wget
  nfs-utils python-pyasn1-modules python-pip
)

YAY_TOOLS=(
  nmap-git whatweb subfinder enum4linux-git smtp-user-enum-git
  hashcat-git responder mssql-tools go-sqlcmd
)

# =============================
# INSTALACIÓN DE HERRAMIENTAS
# =============================
instalar_pacman "${PACMAN_TOOLS[@]}"
instalar_yay "${YAY_TOOLS[@]}"

# =============================
# FIX RUBY (WHATWEB + EVIL-WINRM)
# =============================
echo "[+] Verificando librerías Ruby faltantes..."
OUT=$(whatweb --version 2>&1 || true)
while echo "$OUT" | grep -q "cannot load such file --"; do
  MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
  echo "[!] Instalando gem Ruby faltante: $MISSING"
  gem install --user-install "$MISSING" --no-document &>/dev/null
  OUT=$(whatweb --version 2>&1 || true)
done
OUT=$(evil-winrm 2>&1 || true)
while echo "$OUT" | grep -q "cannot load such file --"; do
    MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
    echo "[!] Inst. dependiente: $MISSING"
    gem install --user-install "$MISSING" --no-document &>/dev/null
    OUT=$(evil-winrm 2>&1 || true)
done

if gem install --user-install evil-winrm --no-document &>/dev/null; then
  echo "✅ evil-winrm instalada"
else
  echo "❌ No se pudo instalar evil-winrm"
fi

# =============================
# FIX PATH GEM
# =============================
GEM_PATH="$(ruby -e 'puts Gem.user_dir')/bin"
if ! echo "$PATH" | grep -q "$GEM_PATH"; then
  echo "[+] Añadiendo $GEM_PATH al PATH"
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.zshrc
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.bashrc
  export PATH="$GEM_PATH:$PATH"
fi


# =============================
# FIX RESPONDER (PIP DEPS)
# =============================
pip install --break-system-packages --upgrade pip
pip install --break-system-packages aioquic dnspython impacket netifaces &>/dev/null && \
  echo "✅ Dependencias responder instaladas" || \
  echo "❌ Error instalando dependencias responder"
sudo pip install aioquic --break-system-packages &>/dev/null

# =============================
# EXPLOITDB
# =============================
echo "$SUDO_PASS" | sudo -S rm -rf /opt/exploitdb
echo "$SUDO_PASS" | sudo -S rm -f /usr/local/bin/searchsploit

# Clonar desde GitHub oficial
if echo "$SUDO_PASS" | sudo -S git clone https://github.com/offensive-security/exploitdb.git /opt/exploitdb &>/dev/null; then
  echo "$SUDO_PASS" | sudo -S ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit
  echo "✅ exploitdb instalada"
else
  echo "❌ Error instalando exploitdb"
fi


# =============================
# WORDLISTS & SECLISTS
# =============================


# =========================
# CONFIG
# =========================
USR_SHARE="/usr/share"
SECLISTS_REPO="https://github.com/danielmiessler/SecLists.git"
WORDLISTS_REPO="https://github.com/g333k/wordlists.git"

FILES_TO_PROCESS=(
    "amass.zip"
    "dirb.zip"
    "dirbuster.zip"
    "dnsmap.txt"
    "fasttrack.txt"
    "fern-wifi.zip"
    "john.lst"
    "legion.zip"
    "metasploit.zip"
    "nmap.lst"
    "rockyou.txt.zip"
    "sqlmap.txt"
    "wfuzz.zip"
    "wifite.txt"
)

WORDLISTS_DIR="$USR_SHARE/wordlists"

# =========================
# FUNCIONES
# =========================


clone_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    if [[ ! -d "$dest_dir" ]]; then
        echo "[*] Clonando $repo_url en $dest_dir..."
        if echo "$SUDO_PASS" | sudo -S git clone "$repo_url" "$dest_dir" &>/dev/null; then
            echo "✅ Repo $(basename "$dest_dir") instalada"
        else
            echo "❌ No se pudo clonar repo $(basename "$dest_dir")"
        fi
    else
        echo "[+] El repositorio $repo_url ya existe en $dest_dir"
    fi
}

process_files() {
    local src_dir="$WORDLISTS_DIR"

    for file_name in "${FILES_TO_PROCESS[@]}"; do
        local src_file="$src_dir/$file_name"

        if [[ -f "$src_file" ]]; then
            if [[ "$file_name" == "rockyou.txt.zip" ]]; then
                # Caso especial: descomprimir directamente
                echo "[+] Descomprimiendo $file_name en $src_dir"
                unzip -o "$src_file" -d "$src_dir" >/dev/null
                rm -f "$src_file"
            elif [[ "$file_name" == *.zip ]]; then
                # Carpeta normal
                local folder_name="${file_name%.zip}"
                local dest_dir="$src_dir/$folder_name"
                mkdir -p "$dest_dir"
                echo "[+] Descomprimiendo $file_name en $dest_dir"
                unzip -o "$src_file" -d "$dest_dir" >/dev/null
                rm -f "$src_file"
            else
                echo "[+] Manteniendo $file_name en $src_dir"
            fi
        else
            echo "[!] Archivo no encontrado: $src_file"
        fi
    done
}

clone_repo "$SECLISTS_REPO" "$USR_SHARE/SecLists"
clone_repo "$WORDLISTS_REPO" "$WORDLISTS_DIR"

# =============================
# FIN
# =============================
echo
echo "🚀 Instalación completa. Powered by G3K"

