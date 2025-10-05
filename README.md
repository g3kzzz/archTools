# archTools

Instalador minimalista de herramientas de pentesting para **Arch Linux**.

## Qué hace
- Añade BlackArch (si ejecutas el módulo correspondiente).  
- Instala `yay` (AUR) si falta.  
- Instala paquetes `pacman` y AUR categorizados por módulos.  
- Clona y organiza `/usr/share/wordlists` y `/usr/share/SecLists`.  
- Clona `https://github.com/g3kzzz/tools` en `/tools`, copia `tools/bin/*` a `/usr/bin` y ejecuta sus instaladores.  
- Maneja `sudo` temporalmente con una entrada en `/etc/sudoers.d/99_g3k_tmp` y la elimina al terminar.

## Uso rápido
```bash
git clone https://github.com/g3kzzz/archTools.git
cd archTools
chmod +x install.sh
./install.sh [options]

```
##Modos / opciones

-h, --help : muestra ayuda.

-A, --all : ejecutar todos los módulos sin preguntas.

-y, --yes : responder "yes" por defecto a las preguntas por módulo.

-s, --single <file> : ejecutar solo el/los módulo(s) especificado(s). Repetible o coma-separado.

--skip <pattern> : omitir módulos cuyo nombre contenga pattern. Repetible o coma-separado.

-l, --list : listar módulos disponibles.

-u, --update : git pull del repo antes de ejecutar.

-d, --dry-run : mostrar plan y salir (no hace cambios).


Módulos (qué instala, resumen)

1.blackarch.sh — instala/actualiza repo BlackArch y actualiza sistema.

2.gathering.sh — herramientas de recolección (amass, subfinder, ffuf...).

3.enumeration.sh — nmap, enum4linux, smbmap, etc.

4.explotation.sh — metasploit, exploitdb, fuzzers.

5.post-exploitation.sh — utilidades post-explotación.

6.reporting.sh — herramientas de reporting/export.

7.wordlists.sh — clona SecLists y wordlists g3, descomprime comunes en /usr/share/wordlists.

8.misc-tools.sh — clona g3kzzz/tools en /tools, copia binarios y ejecuta instaladores locales.


