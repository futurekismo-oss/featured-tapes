#!/usr/bin/env bash

set -uo pipefail

TAPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TAPE_DIR" || { echo "cannot cd to tape dir $TAPE_DIR" >&2; exit 1; }

REPO_URL="${CYBERARCH_REPO:-https://github.com/ARCANGEL0/CyberArch-Shell.git}"
CLONE_DIR="CyberArch-Shell"

echo "▸ cloning $REPO_URL"

if ! git clone --depth 1 "$REPO_URL" "$CLONE_DIR"; then
    echo "shallow clone failed, retrying full clone"
    git clone "$REPO_URL" "$CLONE_DIR" || { echo "✗ clone failed" >&2; exit 1; }
fi

echo "▸🔎 relocating $CLONE_DIR/* into tape root"
shopt -s dotglob nullglob
for item in "$CLONE_DIR"/*; do
    case "$(basename "$item")" in
        .git) continue ;;
    esac
    mv -f "$item" .
done
shopt -u dotglob nullglob
rm -rf "$CLONE_DIR"
mkdir -p hypr/themes
if [ ! -e hypr/themes/cyberpunk ] && [ ! -L hypr/themes/cyberpunk ]; then
    ln -s ../.. hypr/themes/cyberpunk
    echo "✓ created theme symlink hypr/themes/cyberpunk -> ../.."
else
    echo "• Great! ☺️ theme symlink already present, leaving as-is"
fi
if command -v ags >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    if [ ! -x "$HOME/.local/bin/ags" ]; then
        ln -sfn "$(command -v ags)" "$HOME/.local/bin/ags"
        echo "✓ linked ~/.local/bin/ags -> $(command -v ags)"
    else
        echo "• ~/.local/bin/ags already present"
    fi
else
    echo "• ❗ Ops! 'ags' not on PATH yet ( 💪CyberArch install.sh below will install it)"
fi
if [ "${TAPE_SKIP_INSTALLER:-0}" = "1" ]; then
    cat <<'SKIP'

▸ TAPE_SKIP_INSTALLER=1 — CyberArch install.sh skipped.
  You MUST install the runtime deps yourself before `tapes insert`:
      paru -S ags-git libastal-gjs-git libastal-notifd-git \
               libastal-wireplumber-git libastal-mpris-git quickshell

SKIP
elif [ -x ./install.sh ]; then
    echo "▸ running CyberArch install.sh (interactive — answer the prompts)"
    echo "  skip with TAPE_SKIP_INSTALLER=1 if you have the deps already"
    if ! ./install.sh; then
        echo "✗ CyberArch install.sh failed😩" >&2
        echo "  the tape files are in place, but runtime deps may be missing." >&2
        echo "  re-run after fixing:  cd \"$TAPE_DIR\" && ./install.sh" >&2
        echo "  (continuing — insert hook will report if the HUD can't start)"
    else
        echo "✓ CyberArch install.sh completed. Good Job 👏"
    fi
else
    echo "⚠ Opsi! ./install.sh not found or not executable — skipping dep install"
fi
rm -f "$0"
echo "✓ cyberarch tape installed"
