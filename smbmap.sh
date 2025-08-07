#!/bin/bash

# 📛 No ejecutar como root
if [ "$EUID" -eq 0 ]; then
  echo "❌ No ejecutes este script como root."
  exit 1
fi

# 🧰 Instalar yay si no está presente
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

# 📦 Instalar smbmap desde AUR
echo "📦 Instalando smbmap desde AUR..."
yay -S smbmap --noconfirm

# 🐍 Instalar dependencias necesarias para smbmap
echo "🐍 Instalando dependencias de Python necesarias para smbmap..."
sudo pacman -S python-pip --noconfirm
pip install --break-system-packages --upgrade pip

# 🧱 Dependencias requeridas por smbmap
pip install --break-system-packages impacket termcolor pycryptodome


# 🔗 Crear symlink para usar smbmap globalmente
if [ ! -f /usr/local/bin/smbmap ]; then
    echo "🔗 Creando symlink en /usr/local/bin/smbmap"
    sudo ln -s /usr/bin/smbmap.py /usr/local/bin/smbmap
    sudo chmod +x /usr/bin/smbmap.py
else
    echo "✅ El symlink de smbmap ya existe."
fi

echo "✅ Instalación de smbmap completa."
echo ""
echo "▶️ Prueba ejecutarlo con:"
echo "   smbmap -H <ip> -u '' -p ''"
