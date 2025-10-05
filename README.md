# archTools

Instalador minimalista de herramientas de pentesting para **Arch Linux**.

![License: MIT](https://img.shields.io/badge/license-MIT-brightgreen)

## Qué hace
- Añade BlackArch (si ejecutas el módulo correspondiente).  
- Instala `yay` (AUR) si falta.  
- Instala paquetes vía `pacman` y AUR organizados por módulos.  
- Clona y organiza `/usr/share/wordlists` y `/usr/share/SecLists`.  
- Clona `https://github.com/g3kzzz/tools` en `/tools`, copia `tools/bin/*` a `/usr/bin` y ejecuta sus instaladores locales.  
- Maneja `sudo` temporalmente añadiendo `/etc/sudoers.d/99_g3k_tmp` y elimina la entrada al terminar.

---

## Uso rápido

```bash
# clona el repo y ejecuta el instalador
git clone https://github.com/g3kzzz/archTools.git
cd archTools
chmod +x install.sh
./install.sh [OPCIONES]
```

## Modos

-h, --help
Muestra ayuda y lista de opciones.

-A, --all
Ejecuta todos los módulos sin interacción.

-y, --yes
Contesta yes por defecto a los prompts de los módulos.

-s <file>, --single <file>
Ejecuta sólo el/los módulo(s) especificado(s). Puede repetirse o pasarse coma-separado.
Ej.: -s 2.gathering.sh o -s 2.gathering.sh,7.wordlists.sh

--skip <pattern>
Omite módulos cuyo nombre contenga pattern. Repetible o coma-separado.
Ej.: --skip blackarch --skip msf

-l, --list
Lista módulos disponibles (nombre, descripción breve).

-u, --update
Ejecuta git pull en el repo antes de comenzar.

-d, --dry-run
Muestra el plan/acciones que se realizarían y sale (no hace cambios).
