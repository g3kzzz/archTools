#!/bin/bash
set -e


# --- ROOT RESTRICTION ---
if [[ $EUID -eq 0 ]]; then
  echo "[!] Do not run this script directly as root."
  echo "[!] Run it as a normal user."
  exit 1
fi



# =============================
#   G3K Installer
# =============================

# --- FUNCTION FOR ANIMATION ---
slow_print() {
  local text="$1"
  for ((i=0; i<${#text}; i++)); do
    echo -n "${text:$i:1}"
    sleep 0.000
  done
  echo
}

# --- ASCII BANNER ---

banner="                           
   _____ ___ _____ _____         _     
  |   __|_  |  |  |_   _|___ ___| |___ 
  |  |  |_  |    -| | | | . | . | |_ -|
  |_____|___|__|__| |_| |___|___|_|___|
                                                            
             Made by: g3kzzz
 Repo: https://github.com/g333k/archTools
"

clear
slow_print "$banner"
sleep 1


echo " ============================================================"
echo "             Welcome to the G3K Hacking Tools Installer"
echo " ============================================================"
echo
echo " [!] This script will perform the following changes:"
echo "   - Install essential pentesting packages with pacman"
echo "   - Install extra pentesting tools from AUR with yay"
echo "   - Install and configure BlackArch repository"
echo "   - Install Ruby gems required for whatweb and evil-winrm"
echo "   - Install Python dependencies for responder and others"
echo "   - Clone and setup wordlists and SecLists in /usr/share"
echo "   - Clone the custom tools repository into /tools"
echo "   - Copy all binaries from /tools/bin into /usr/bin"
echo "   - Remove /tools/bin (only other folders remain in /tools)"
echo "   - Run additional setup scripts for Windows/Linux tools"
echo "   - Clone webshells and payloads into /g3web"
echo
echo "============================================================"
echo

read -p " Do you want to continue with the installation? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo " [!] Installation cancelled by the user."
  exit 0
fi

clear
echo " [+] Starting installation..."
sleep 2

# =============================
# PASSWORD HANDLING
# =============================
while true; do
    echo -n "🔑 Enter your sudo password: "
    read -s SUDO_PASS
    echo
    # Validate password
    if echo "$SUDO_PASS" | sudo -S -v &>/dev/null; then
        echo "✅ Password accepted"
        break
    else
        echo "❌ Wrong password, try again."
    fi
done



# =============================
# SUDOERS TEMPORAL PARA YAY
# =============================
TMP_SUDOERS="/etc/sudoers.d/99_g3k_tmp"
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/makepkg, /usr/bin/chsh" | sudo tee "$TMP_SUDOERS" >/dev/null


# Custom sudo function
run_sudo() {
    echo "$SUDO_PASS" | sudo -S "$@"
}

# =============================
# AUXILIARY FUNCTIONS
# =============================
install_blackarch() {
    if grep -q "\[blackarch\]" /etc/pacman.conf; then
        echo "✅ BlackArch repo already installed."
    else
        echo "[*] Downloading and installing BlackArch..."
        cd /tmp || return
        curl -s -O https://blackarch.org/strap.sh
        run_sudo chmod +x strap.sh &>/dev/null
        if run_sudo ./strap.sh &>/dev/null; then
            echo "✅ BlackArch successfully installed"
        else
            echo "❌ Error installing BlackArch"
            return 1
        fi
    fi

    echo "[*] Updating repositories..."
    if run_sudo pacman -Syyu --noconfirm --overwrite '*' &>/dev/null; then
        echo "✅ BlackArch repositories updated"
    else
        echo "❌ Error updating BlackArch repos"
        return 1
    fi
}

pause_and_clear() {
  sleep 2
  clear
}

install_pacman() {
  for pkg in "$@"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "✅ $pkg already installed"
    else
      if echo "$SUDO_PASS" | sudo -S pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ $pkg installed"
      else
        echo "❌ Could not install $pkg with pacman"
      fi
    fi
  done
}

install_yay() {
  for pkg in "$@"; do
    if yay -Qi "$pkg" &>/dev/null; then
      echo "✅ $pkg already installed"
    else
      if yay -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo "✅ $pkg installed"
      else
        echo "❌ Could not install $pkg with yay"
      fi
    fi
  done
}

install_blackarch
cd /home/$USER

# =============================
# YAY INSTALL
# =============================
if ! command -v yay &>/dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/yay.git &>/dev/null
  cd yay
  makepkg -si --noconfirm <<<"$SUDO_PASS" &>/dev/null
  cd ~
  echo "✅ yay installed"
else
  echo "✅ yay already installed"
fi

# =============================
# TOOLS INSTALLATION
# =============================

PACMAN_TOOLS=( arp-scan net-tools locate tree net-snmp burpsuite smbclient chisel whois bind-tools finalrecon ffuf hashcat hashcat-utils subfinder gobuster enum4linux dnsrecon amap medusa hydra hash-identifier hashid responder metasploit crackmapexec netexec crowbar wireshark-qt gnu-netcat socat openssh freerdp2 openvpn john exiftool nfs-utils python-pyasn1-modules python-pip ptunnel exploitdb wget smbmap ) 

YAY_TOOLS=( whatweb smtp-user-enum-git ruby-evil-winrm proxychains-ng-git powershell-bin libreoffice-fresh mssql-tools go-sqlcmd )
echo "[+] PACMAN TOOLS..."
install_pacman "${PACMAN_TOOLS[@]}"
pause_and_clear
echo "[+] YAY TOOLS..."
install_yay "${YAY_TOOLS[@]}"
pause_and_clear

# =============================
# RUBY FIXES (WHATWEB + EVIL-WINRM)
# =============================
echo "[+] Checking missing Ruby libraries..."
OUT=$(whatweb --version 2>&1 || true)
while echo "$OUT" | grep -q "cannot load such file --"; do
  MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
  echo "[!] Installing missing Ruby gem: $MISSING"
  gem install --user-install "$MISSING" --no-document &>/dev/null
  OUT=$(whatweb --version 2>&1 || true)
done
OUT=$(evil-winrm 2>&1 || true)
while echo "$OUT" | grep -q "cannot load such file --"; do
    MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
    echo "[!] Installing dependency: $MISSING"
    gem install --user-install "$MISSING" --no-document &>/dev/null
    OUT=$(evil-winrm 2>&1 || true)
done

gem install --user-install evil-winrm --no-document &>/dev/null && echo "✅ evil-winrm installed"

# Extra gems
gem install --user-install csv --no-document &>/dev/null && echo "✅ gem csv installed"

# Add GEM bin path
GEM_PATH="$(ruby -e 'puts Gem.user_dir')/bin"
if ! echo "$PATH" | grep -q "$GEM_PATH"; then
  echo "[+] Adding $GEM_PATH to PATH"
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.zshrc
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.bashrc
  export PATH="$GEM_PATH:$PATH"
fi

# =============================
# RESPONDER FIX (PIP DEPS)
# =============================
pip install --break-system-packages --upgrade pip 
pip install --break-system-packages aioquic tldextract bloodhound python-ldap dnspython impacket netifaces &>/dev/null && \
  echo "✅ responder dependencies installed"
run_sudo pip install aioquic --break-system-packages &>/dev/null
pip install --user git+https://github.com/xmendez/wfuzz.git
pause_and_clear
# =============================
# WORDLISTS & SECLISTS
# =============================
USR_SHARE="/usr/share"
SECLISTS_REPO="https://github.com/danielmiessler/SecLists.git"
WORDLISTS_REPO="https://github.com/g333k/wordlists.git"
WORDLISTS_DIR="$USR_SHARE/wordlists"

FILES_TO_PROCESS=( "amass.zip" "dirb.zip" "dirbuster.zip" "dnsmap.txt" "fasttrack.txt" "fern-wifi.zip" "john.lst" "legion.zip" "metasploit.zip" "nmap.lst" "rockyou.txt.zip" "sqlmap.txt" "wfuzz.zip" "wifite.txt" )

clone_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    if [[ ! -d "$dest_dir" ]]; then
        echo "[*] Cloning $repo_url into $dest_dir..."
        if echo "$SUDO_PASS" | sudo -S git clone "$repo_url" "$dest_dir" &>/dev/null; then
            echo "✅ Repo $(basename "$dest_dir") installed"
        else
            echo "❌ Could not clone repo $(basename "$dest_dir")"
        fi
    else
        echo "[+] Repo $repo_url already exists in $dest_dir"
    fi
}
process_files() {
    local src_dir="$WORDLISTS_DIR"
    for file_name in "${FILES_TO_PROCESS[@]}"; do
        local src_file="$src_dir/$file_name"
        if [[ -f "$src_file" ]]; then
            if [[ "$file_name" == "rockyou.txt.zip" ]]; then
                echo "[+] Unzipping $file_name in $src_dir"
                run_sudo unzip -o "$src_file" -d "$src_dir" >/dev/null
                run_sudo rm -f "$src_file"
            elif [[ "$file_name" == *.zip ]]; then
                local folder_name="${file_name%.zip}"
                local dest_dir="$src_dir/$folder_name"
                run_sudo mkdir -p "$dest_dir"
                echo "[+] Unzipping $file_name in $dest_dir"
                run_sudo unzip -o "$src_file" -d "$dest_dir" >/dev/null
                run_sudo rm -f "$src_file"
            else
                echo "[+] Keeping $file_name in $src_dir"
            fi
        else
            echo "[!] File not found: $src_file"
        fi
    done
}

clone_repo "$SECLISTS_REPO" "$USR_SHARE/SecLists"
clone_repo "$WORDLISTS_REPO" "$WORDLISTS_DIR"
process_files

# =============================
# CLONE TOOLS AND EXPORT PATH
# =============================
if [[ -d "/tools" ]]; then
    echo "[*] Removing existing /tools..."
    run_sudo rm -rf /tools
fi

clone_repo "https://github.com/g333k/tools" "/tools"
run_sudo chown -R "$USER:$USER" /tools
run_sudo chmod -R 755 /tools

# Copy /tools/bin binaries into /usr/bin, then remove /tools/bin
if [[ -d "/tools/bin" ]]; then
    echo "[*] Copying /tools/bin binaries into /usr/bin..."
    run_sudo cp -a /tools/bin/* /usr/bin/
    echo "[*] Removing /tools/bin..."
    run_sudo rm -rf /tools/bin
fi


# Install and clean helper scripts
run_sudo /tools/windows/install_windows_tools.sh
run_sudo /tools/linux/install_linux_tools.sh
run_sudo rm /tools/windows/install_windows_tools.sh
run_sudo rm /tools/linux/install_linux_tools.sh

# =============================
# CLONE WEB & SHELLS
# =============================
if [[ -d "/g3web" ]]; then
    echo "[*] Removing existing /g3web..."
    run_sudo rm -rf /g3web
fi
clone_repo "https://github.com/g333k/g3web" "/g3web"
pause_and_clear


# =============================
# LIMPIEZA DE SUDOERS
# =============================
echo " [+] Cleaning up sudoers rule..."
run_sudo rm -f /etc/sudoers.d/99_g3k_tmp
echo " [✓] Sudoers restored"
pause_and_clear




# =============================
# DNScat2 INSTALLATION
# =============================
cd /tools/linux/ || exit 1

DNScat2_DIR="dnscat2"

echo "[*] Clonando dnscat2..."
if [[ -d "$DNScat2_DIR" ]]; then
    echo "[*] $DNScat2_DIR ya existe, eliminando carpeta antigua..."
    rm -rf "$DNScat2_DIR"
fi

git clone https://github.com/iagox86/dnscat2.git "$DNScat2_DIR"
echo "[+] dnscat2 clonado."

# Instalar dependencias Ruby
if [[ -f "$DNScat2_DIR/server/Gemfile" ]]; then
    echo "[*] Instalando dependencias Ruby de dnscat2..."
    cd "$DNScat2_DIR/server/" || exit 1
    if ! gem list bundler -i >/dev/null 2>&1; then
        run_sudo gem install bundler
    fi
    sudo bundle install
    cd /tools/linux/ || exit 1
    echo "[+] Dependencias Ruby instaladas."
fi

# Crear wrapper en /usr/bin
echo "[*] Creando wrapper /usr/bin/dnscat2..."
run_sudo tee /usr/bin/dnscat2 >/dev/null <<EOF
#!/bin/bash
ruby /tools/linux/dnscat2/server/dnscat2.rb "\$@"
EOF
run_sudo chmod +x /usr/bin/dnscat2
echo "[+] Wrapper listo: puedes ejecutar 'dnscat2' desde cualquier lugar."

# -------------------------
#     FINAL
# -------------------------
echo "============================================================"
echo " [✓] All done."
echo " ✅ G3K installation finished!"
echo "============================================================"
pause_and_clear
