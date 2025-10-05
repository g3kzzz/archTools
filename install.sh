#!/usr/bin/env bash
# install.sh - Main installer for archtools (tuned modes)
# Author: g3kzzz
# Location: ~/Documents/archtools

set -euo pipefail

# ---------- Colors ----------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
TMP_SUDOERS="/etc/sudoers.d/99_g3k_tmp"

# ---------- Defaults / Flags ----------
MODE_ALL=false        # -A / --all  -> non-interactive install of all modules
ASSUME_YES=false      # -y / --yes  -> auto-yes for module prompts (interactive)
LIST_ONLY=false       # -l / --list -> list modules and exit
SINGLE_MODULES=()     # -s / --single <file> -> array of exact filenames to run
UPDATE_REPO=false     # -u / --update
DRY_RUN=false         # -d / --dry-run -> show commands, don't run
SKIP_PATTERNS=()      # --skip <pattern> -> array of patterns to skip (substring match)

# ---------- Help (plain text, no colors) ----------
show_help() {
cat <<'EOF'
ArchTools Installer

Usage: ./install.sh [options]

Modes / options:
  -h, --help
        Show this help message and exit (plain text).
  -A, --all
        Install ALL modules without prompts (non-interactive).
  -y, --yes
        Auto-answer "yes" to module prompts (interactive mode).
  -s, --single <file>
        Install only the specified module (exact filename). Can be used
        multiple times or with a comma-separated list: -s a.sh -s b.sh
        or -s a.sh,b.sh
  -l, --list
        List available modules and exit.
  -u, --update
        Update this repo (git pull) before running.
  -d, --dry-run
        Show what would run (no changes made).
  --skip <pattern>
        Skip modules whose filename contains <pattern>. Can be repeated
        or given as a comma-separated list.

Notes:
  - --all (-A) implies non-interactive install: every module is executed.
  - --yes (-y) answers "yes" to module prompts but still allows per-module
    selection (unless you also use --all).
  - --single and --all are mutually exclusive.
  - --dry-run will not request sudo password nor change the system.

Examples:
  ./install.sh -A
    Install everything without prompts.

  ./install.sh -y
    Ask per-module but default Yes.

  ./install.sh -s 7.wordlists.sh -s blackarch.sh
    Run only those two modules.

  ./install.sh --skip blackarch
    Run all modules except those whose name contains "blackarch".

EOF
exit 0
}

# ---------- Arg parsing helpers ----------
append_csv_to_array() {
    # $1 = csv string, $2 = name of array variable to append to
    local csv="$1"; local arrname="$2"
    IFS=',' read -r -a parts <<< "$csv"
    for p in "${parts[@]}"; do
        p="${p## }"  # trim leading spaces
        p="${p%% }"  # trim trailing spaces
        if [ -n "$p" ]; then
            eval "$arrname+=(\"$p\")"
        fi
    done
}

# ---------- Parse args ----------
if [ "$#" -gt 0 ]; then
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) show_help ;;
      -A|--all) MODE_ALL=true ;;
      -y|--yes) ASSUME_YES=true ;;
      -l|--list) LIST_ONLY=true ;;
      -s|--single)
         shift
         if [ -z "${1:-}" ]; then
             echo -e "${RED}[!] --single requires a filename${RESET}"
             exit 1
         fi
         append_csv_to_array "$1" SINGLE_MODULES
         ;;
      -u|--update) UPDATE_REPO=true ;;
      -d|--dry-run) DRY_RUN=true ;;
      --skip)
         shift
         if [ -z "${1:-}" ]; then
             echo -e "${RED}[!] --skip requires a pattern${RESET}"
             exit 1
         fi
         append_csv_to_array "$1" SKIP_PATTERNS
         ;;
      *)
         echo -e "${RED}[!] Unknown option: $1${RESET}"
         show_help
         ;;
    esac
    shift
  done
fi

# Validate incompatible flags
if $MODE_ALL && [ "${#SINGLE_MODULES[@]}" -gt 0 ]; then
  echo -e "${RED}[!] --all and --single are mutually exclusive${RESET}"
  exit 1
fi

# ---------- list modules ----------
mapfile -t MODULE_FILES < <(find "$MODULES_DIR" -maxdepth 1 -type f -iname "*.sh" | sort)
if [ "${#MODULE_FILES[@]}" -eq 0 ]; then
    echo -e "${YELLOW}[!] No modules found in $MODULES_DIR${RESET}"
    exit 0
fi

if $LIST_ONLY; then
    echo -e "${BLUE}Available modules:${RESET}"
    for m in "${MODULE_FILES[@]}"; do
        echo "  - $(basename "$m")"
    done
    exit 0
fi

# If SINGLE_MODULES provided, verify exists
if [ "${#SINGLE_MODULES[@]}" -gt 0 ]; then
    for sm in "${SINGLE_MODULES[@]}"; do
        found=false
        for m in "${MODULE_FILES[@]}"; do
            if [[ "$(basename "$m")" == "$sm" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            echo -e "${RED}[!] Module not found: $sm${RESET}"
            exit 1
        fi
    done
fi

# ---------- Dry-run: just show plan and exit ----------
if $DRY_RUN; then
    echo -e "${YELLOW}[DRY-RUN] The following modules WOULD be executed:${RESET}"
    for m in "${MODULE_FILES[@]}"; do
        modname="$(basename "$m")"
        # apply single/skip filters
        if [ "${#SINGLE_MODULES[@]}" -gt 0 ]; then
            keep=false
            for sm in "${SINGLE_MODULES[@]}"; do
                if [[ "$modname" == "$sm" ]]; then keep=true; break; fi
            done
            $keep || continue
        fi
        skip=false
        for pat in "${SKIP_PATTERNS[@]}"; do
            if [[ "$modname" == *"$pat"* ]]; then skip=true; break; fi
        done
        $skip && continue
        echo "  - $modname"
    done
    echo -e "${YELLOW}[DRY-RUN] No changes made.${RESET}"
    exit 0
fi

# ---------- If update requested, git pull repo (best effort) ----------
if $UPDATE_REPO; then
    echo -e "${BLUE}[*] Updating installer repository...${RESET}"
    git -C "$SCRIPT_DIR" pull || echo -e "${YELLOW}[!] Git update failed, continuing...${RESET}"
fi

# ---------- Ask for sudo password ----------
echo -e "${BLUE}[*] This installer requires sudo privileges.${RESET}"
while true; do
    echo -n "🔑 Enter your sudo password: "
    read -r -s SUDO_PASS || true
    echo
    if echo "$SUDO_PASS" | sudo -S -v &>/dev/null; then
        echo -e "${GREEN}✅ Password accepted${RESET}"
        break
    else
        echo -e "${RED}❌ Wrong password, try again.${RESET}"
    fi
done

# ---------- Create temporary sudoers ----------
echo -e "${BLUE}[*] Creating temporary sudoers for pacman/makepkg/chsh/yay...${RESET}"
SUDOERS_LINE="$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/makepkg, /usr/bin/chsh, /usr/bin/yay"
echo "$SUDO_PASS" | sudo -S bash -c "echo '$SUDOERS_LINE' > '$TMP_SUDOERS' && chmod 0440 '$TMP_SUDOERS'"

# ---------- Traps & cleanup ----------
cleanup() {
    echo -e "\n${BLUE}[*] Cleaning up temporary permissions...${RESET}"
    if [ -f "$TMP_SUDOERS" ]; then
        echo "$SUDO_PASS" | sudo -S rm -f "$TMP_SUDOERS" >/dev/null 2>&1 || true
    fi
    sudo -k 2>/dev/null || true
    echo -e "${GREEN}[✓] Environment restored.${RESET}"
}
on_interrupt() {
    echo -e "\n${RED}[!] Installation interrupted by user (Ctrl+C).${RESET}"
    cleanup
    exit 130
}
trap on_interrupt INT
trap cleanup EXIT

# Export SUDO_PASS for modules that might rely on run_sudo (if used)
export SUDO_PASS

# ---------- Main loop: run modules based on flags ----------
echo -e "${GREEN}ArchTools Installer${RESET}"
echo -e "${YELLOW}Modules directory:${RESET} $MODULES_DIR"
echo

for module in "${MODULE_FILES[@]}"; do
    modname="$(basename "$module")"

    # apply single filter (if provided)
    if [ "${#SINGLE_MODULES[@]}" -gt 0 ]; then
        keep=false
        for sm in "${SINGLE_MODULES[@]}"; do
            if [[ "$modname" == "$sm" ]]; then keep=true; break; fi
        done
        $keep || continue
    fi

    # apply skip patterns
    skip=false
    for pat in "${SKIP_PATTERNS[@]}"; do
        if [[ "$modname" == *"$pat"* ]]; then skip=true; break; fi
    done
    if $skip; then
        echo -e "${YELLOW}[-] Skipping ${modname} (matched skip pattern)${RESET}"
        continue
    fi

    echo -e "\n${BLUE}--- Module: ${modname} ---${RESET}"

    if $MODE_ALL; then
        echo -e "${YELLOW}[~] Running ${modname} (all-mode)...${RESET}"
        bash "$module" || echo -e "${RED}[!] ${modname} exited with non-zero code.${RESET}"
        echo -e "${GREEN}✔ ${modname} finished.${RESET}"
        continue
    fi

    # If ASSUME_YES, auto-yes. Otherwise ask interactively.
    if $ASSUME_YES; then
        run_it=true
    else
        # interactive prompt per module
        while true; do
            read -r -p "Install ${modname}? [Y/n] " resp
            resp="${resp:-Y}"
            case "$resp" in
                [Yy]* ) run_it=true; break ;;
                [Nn]* ) run_it=false; break ;;
                * ) echo "Please answer Y or n." ;;
            esac
        done
    fi

    if $run_it; then
        echo -e "${YELLOW}[~] Running ${modname}...${RESET}"
        bash "$module" || echo -e "${RED}[!] ${modname} exited with non-zero code.${RESET}"
        echo -e "${GREEN}✔ ${modname} finished.${RESET}"
    else
        echo -e "${YELLOW}[-] Skipped ${modname}.${RESET}"
    fi
done

# ---------- Finalize ----------
echo
echo -e "${GREEN}[✓] All selected modules processed.${RESET}"
cleanup
echo -e "${GREEN}[✓] Installation finished successfully.${RESET}"
exit 0

