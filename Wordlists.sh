#!/bin/bash

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
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "[!] Este script debe ejecutarse como root."
        exit 1
    fi
}

clone_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    if [[ ! -d "$dest_dir" ]]; then
        echo "[*] Clonando $repo_url en $dest_dir..."
        git clone "$repo_url" "$dest_dir"
    else
        echo "[+] El repositorio $repo_url ya existe en $dest_dir"
    fi
}

process_files() {
    local src_dir="$WORDLISTS_DIR"

    for file_name in "${FILES_TO_PROCESS[@]}"; do
        local src_file="$src_dir/$file_name"

        if [[ -f "$src_file" ]]; then
            if [[ "$file_name" == *.zip ]]; then
                local folder_name="${file_name%.zip}"
                local dest_dir="$src_dir/$folder_name"
                mkdir -p "$dest_dir"
                echo "[+] Descomprimiendo $file_name en $dest_dir"
                unzip -o "$src_file" -d "$dest_dir" >/dev/null
                rm -f "$src_file"  # Eliminar el zip después
            else
                echo "[+] Manteniendo $file_name en $src_dir"
                # Ya está en el lugar correcto, no se mueve
            fi
        else
            echo "[!] Archivo no encontrado: $src_file"
        fi
    done
}

# =========================
# MAIN
# =========================
check_root

echo "[*] Clonando repositorios..."
clone_repo "$SECLISTS_REPO" "$USR_SHARE/SecLists"
clone_repo "$WORDLISTS_REPO" "$WORDLISTS_DIR"

echo "[*] Procesando archivos adicionales..."
process_files

echo "[+] Proceso completado."
