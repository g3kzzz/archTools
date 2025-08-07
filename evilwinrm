#!/bin/bash

set -e

# =============================
#      G3K ASCII HEADER
# =============================




# =============================
#      SPINNER FUNC
# =============================
spin() {
  local pid=$!
  local spin='-\|/'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r[⏳] %s" "${spin:$i:1}"
    sleep .1
  done
  echo -ne "\r[✔] Listo!                 \n"
}

# =============================
#      DEPENDENCIAS
# =============================
echo -n "[+] Verificando dependencias base... "
{
  sudo pacman -S --needed ruby rustup base-devel git --noconfirm &>/dev/null
  rustup show &>/dev/null || rustup default stable &>/dev/null
} & spin

# =============================
#      YAY / PARU fallback
# =============================
if ! command -v yay &>/dev/null; then
  echo -n "[+] yay no encontrado, instalando... "
  {
    cd /tmp
    git clone https://aur.archlinux.org/yay.git &>/dev/null
    cd yay
    makepkg -si --noconfirm &>/dev/null
  } & spin
fi

# =============================
#      LIMPIEZA DE GEMAS
# =============================
echo -n "[+] Eliminando gemas rotas anteriores... "
#rm -rf ~/.local/share/gem/ruby/* &>/dev/null & spin

# =============================
#      INSTALL evil-winrm
# =============================
echo -n "[+] Instalando evil-winrm vía RubyGems... "
{
  gem install --user-install evil-winrm --no-document &>/dev/null
} & spin

# =============================
#      PATH FIX
# =============================
GEM_PATH="$HOME/.local/share/gem/ruby/3.4.0/bin"
if ! echo $PATH | grep -q "$GEM_PATH"; then
  echo "[+] Añadiendo $GEM_PATH a PATH"
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.bashrc
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.zshrc
  export PATH="$GEM_PATH:$PATH"
fi

# =============================
#      AUTO FIX DEPENDENCIAS
# =============================
echo -n "[+] Verificando librerías faltantes... "
{
  OUT=$(evil-winrm 2>&1 || true)
  while echo "$OUT" | grep -q "cannot load such file --"; do
    MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
    echo "[!] Inst. dependiente: $MISSING"
    gem install --user-install "$MISSING" --no-document &>/dev/null
    OUT=$(evil-winrm 2>&1 || true)
  done
} & spin

# =============================
#      FIN
# =============================
clear
echo "✅ Evil-WinRM está instalado y funcional."
echo
echo "📌 Ejecuta con:"
echo "   evil-winrm -i <ip> -u <usuario> -p <contraseña>"
echo
echo "🚀 Powered by G3K - github.com/g333k"
