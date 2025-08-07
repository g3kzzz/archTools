#!/bin/bash

# =============================================================
#     📦 Instalador de Herramientas - ToolsArch Edition
# =============================================================

REPO_URL="https://github.com/g333k/toolsarch.git"
RUTA_TEMP="/tmp/toolsarch"
DESTINO_BASE="/usr/share"
CARPETAS=("wordlist" "nishang" "laudanum")

# Verificar permisos
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse como root."
    echo "➡️ Usa: sudo $0"
    exit 1
fi

# Clonar o actualizar repositorio
if [[ -d "$RUTA_TEMP/.git" ]]; then
    echo "🔄 Repositorio ya existe en /tmp. Actualizando..."
    git -C "$RUTA_TEMP" pull
else
    echo "📥 Clonando repositorio toolsarch..."
    git clone "$REPO_URL" "$RUTA_TEMP"
fi

# Mover carpetas seleccionadas
for carpeta in "${CARPETAS[@]}"; do
    ORIGEN="$RUTA_TEMP/$carpeta"
    DESTINO="$DESTINO_BASE/$carpeta"

    if [[ -d "$ORIGEN" ]]; then
        echo "📂 Instalando '$carpeta' en /usr/share/..."
        cp -r "$ORIGEN" "$DESTINO"
        echo "✅ '$carpeta' instalada."
    else
        echo "⚠️ Carpeta '$carpeta' no encontrada en el repositorio. Saltando..."
    fi
done

echo "🎉 ¡Instalación completada!"
