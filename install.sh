#!/usr/bin/env bash
# Install GNU Stow (macOS: Homebrew, Linux: from source into ~/.local) and symlink this repo into $HOME.
# On Linux also installs zsh into ~/.local if missing.
# Usage: ./install.sh [stow args], e.g. `./install.sh -n -v` for a dry run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fail early with the full list of missing tools (no sudo here, so they can't be installed for you)
require() {
    local missing=() c
    for c in "$@"; do
        command -v "$c" >/dev/null || missing+=("$c")
    done
    if ((${#missing[@]})); then
        echo "Missing required tools: ${missing[*]}. Install them first (e.g. ask an admin / apt)." >&2
        exit 1
    fi
}

install_stow() {
    if [[ "$OSTYPE" == darwin* ]]; then
        command -v brew >/dev/null || { echo "Homebrew missing, see https://brew.sh" >&2; exit 1; }
        brew install stow
    else
        # Stow is plain Perl: fill in the few build-time placeholders by hand instead of
        # ./configure && make, so only perl is needed (no make, no sudo).
        require curl tar perl
        local tmp lib ver
        tmp="$(mktemp -d)"
        lib="$HOME/.local/share/stow/lib"
        curl -fsSL https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz | tar xz -C "$tmp" --strip-components=1
        ver="$(sed -n "s/^AC_INIT(\[stow\],[[:space:]]*\[\([^]]*\)\].*/\1/p" "$tmp/configure.ac")"
        mkdir -p "$lib/Stow" "$HOME/.local/bin"
        sed "s/@VERSION@/$ver/" "$tmp/lib/Stow.pm.in" > "$lib/Stow.pm"
        sed "s/@VERSION@/$ver/" "$tmp/lib/Stow/Util.pm.in" > "$lib/Stow/Util.pm"
        sed -e "s|^#!@PERL@|#!/usr/bin/env perl|" -e "s/@VERSION@/$ver/" \
            -e "s|^@USE_LIB_PMDIR@|use lib \"$lib\";|" "$tmp/bin/stow.in" > "$HOME/.local/bin/stow"
        chmod 755 "$HOME/.local/bin/stow"
        rm -rf "$tmp"
    fi
}

# zsh is the shell these dotfiles are written for. Without root, install a static build
# (romkatv/zsh-bin, x86_64 and aarch64) into ~/.local.
install_zsh() {
    require curl tar
    curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
        | sh -s -- -q -d "$HOME/.local" -e no
}

# So a previous ~/.local install is found (and the fresh one is usable below)
export PATH="$HOME/.local/bin:$PATH"
require git
command -v stow >/dev/null || install_stow

if [[ "$OSTYPE" != darwin* ]]; then
    command -v zsh >/dev/null || install_zsh
fi

git -C "$DOTFILES" submodule update --init --recursive
git -C "$DOTFILES" config core.hooksPath .githooks

# Stow "folds" missing dirs into a single symlink. Pre-create ~/.config so only its
# subfolders get linked, otherwise other apps would write their configs into this repo.
mkdir -p "$HOME/.config"

# Host profile: files to leave unlinked on this host (e.g. macOS-only configs on Linux)
# shellcheck disable=SC1091
DOTFILES_ENV_DIR="$DOTFILES/.env" . "$DOTFILES/.env/host"
ignore=()
for r in $DOTFILES_STOW_IGNORE; do ignore+=(--ignore="$r"); done
# Only link the rc file of the shell the profile selects (both if it selects none)
case "${DOTFILES_SHELL-}" in
    zsh) ignore+=(--ignore='\.bashrc$') ;;
    bash) ignore+=(--ignore='\.zshrc$') ;;
esac

cd "$DOTFILES"
stow --restow --target="$HOME" ${ignore[@]+"${ignore[@]}"} "$@" .
