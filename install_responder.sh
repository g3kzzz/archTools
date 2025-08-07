#!/bin/bash

# 📛 No ejecutar como root
if [ "$EUID" -eq 0 ]; then
  echo "❌ No ejecutes este script como root."
  exit 1
fi

echo "📦 Instalando yay si no está..."
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed git base-devel --noconfirm
    cd /tmp || exit
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd ~ || exit
else
    echo "✅ yay ya está instalado."
fi

echo "📦 Instalando responder desde AUR..."
yay -S responder --noconfirm

echo "🐍 Instalando dependencias Python globalmente..."
sudo pacman -S python-pip --noconfirm
pip install --break-system-packages --upgrade pip

pip install --break-system-packages aioquic dnspython impacket netifaces

sudo pip install aioquic --break-system-packages

echo "✅ Instalación completa. Ejecuta responder con:"
echo "   responder -I <interfaz>"
