#!/usr/bin/env bash
# Install GNU Stow (macOS: Homebrew, Linux: from source into ~/.local) and symlink this repo into $HOME.
# Usage: ./install.sh [stow args], e.g. `./install.sh -n -v` for a dry run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_stow() {
    if [[ "$OSTYPE" == darwin* ]]; then
        command -v brew >/dev/null || { echo "Homebrew missing, see https://brew.sh" >&2; exit 1; }
        brew install stow
    else
        # Build from source into ~/.local: no sudo, only needs perl + make
        local tmp
        tmp="$(mktemp -d)"
        curl -fsSL https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz | tar xz -C "$tmp" --strip-components=1
        (cd "$tmp" && ./configure --prefix="$HOME/.local" && make install)
        rm -rf "$tmp"
    fi
}

# So a previous ~/.local install is found (and the fresh one is usable below)
export PATH="$HOME/.local/bin:$PATH"
command -v stow >/dev/null || install_stow

git -C "$DOTFILES" submodule update --init --recursive

# Stow "folds" missing dirs into a single symlink. Pre-create ~/.config so only its
# subfolders get linked, otherwise other apps would write their configs into this repo.
mkdir -p "$HOME/.config"

cd "$DOTFILES"
stow --restow --target="$HOME" "$@" .
