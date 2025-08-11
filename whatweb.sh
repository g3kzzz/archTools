#!/bin/bash

set -e



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
#      DEPENDENCIAS BASE
# =============================
echo -n "[+] Verificando dependencias base... "
{
  sudo pacman -S --needed ruby rustup base-devel git --noconfirm &>/dev/null
  rustup show &>/dev/null || rustup default stable &>/dev/null
} & spin

# =============================
#      YAY INSTALL
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
#      INSTALL WHATWEB (AUR)
# =============================
echo -n "[+] Instalando WhatWeb desde AUR... "
yay -S whatweb --noconfirm &>/dev/null & spin

# =============================
#      FIX RUBY DEPENDENCIAS
# =============================
echo -n "[+] Verificando librerías Ruby faltantes... "
{
  OUT=$(whatweb --version 2>&1 || true)
  while echo "$OUT" | grep -q "cannot load such file --"; do
    MISSING=$(echo "$OUT" | grep "cannot load such file --" | sed -E "s/.*-- ([a-zA-Z0-9_\-]+).*/\1/" | head -n 1)
    echo "[!] Instalando Ruby gem faltante: $MISSING"
    gem install --user-install "$MISSING" --no-document &>/dev/null
    OUT=$(whatweb --version 2>&1 || true)
  done
} & spin

# =============================
#      PATH FIX (si aplica)
# =============================
GEM_PATH="$(ruby -e 'puts Gem.user_dir')/bin"
if ! echo $PATH | grep -q "$GEM_PATH"; then
  echo "[+] Añadiendo $GEM_PATH al PATH"
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.zshrc
  echo "export PATH=\"$GEM_PATH:\$PATH\"" >> ~/.bashrc
  export PATH="$GEM_PATH:$PATH"
fi

# =============================
#      FIN
# =============================
clear
echo "✅ WhatWeb está instalado y funcional."
echo
echo "📌 Ejecuta con:"
echo "   whatweb <URL>"
echo
echo "🚀 Powered by G3K - github.com/g333k"
