#!/usr/bin/env bash
# Install GNU Stow (macOS: Homebrew, Linux: from source into ~/.local) and symlink this repo into $HOME.
# On Linux also installs zsh into ~/.local if missing.
# Usage: ./install.sh [--agents] [stow args], e.g. `./install.sh -n -v` for a dry run.
#   --agents  also clone the private agent config repos (see AGENT_REPOS; needs SSH access)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENT_REPOS=(
    "$HOME/.claude ssh://git@codeberg.org/fschlueter/claude-config.git"
    "$HOME/.agents ssh://git@codeberg.org/fschlueter/agents.git"
)

agents=0
stow_args=()
for a in "$@"; do
    if [[ "$a" == --agents ]]; then agents=1; else stow_args+=("$a"); fi
done

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

# Clone repo $2 into $1. An existing non-git $1 is kept (it may hold runtime state such as
# logins and sessions); only the paths the repo tracks are moved into $1.backup-<date>.
install_agent_repo() {
    local dest="$1" url="$2" tmp backup f
    if [[ -e "$dest/.git" ]]; then
        if [[ "$(git -C "$dest" remote get-url origin 2>/dev/null)" == "$url" ]]; then
            echo "agents: $dest already cloned"
        else
            echo "agents: $dest is another git repo, skipped" >&2
        fi
        return
    fi

    tmp="$(mktemp -d "$dest.clone.XXXXXX")"
    git clone --quiet --no-checkout "$url" "$tmp/repo" || { rm -rf "$tmp"; return 1; }
    mkdir -p "$dest"
    mv "$tmp/repo/.git" "$dest/.git"
    rm -rf "$tmp"

    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    while IFS= read -r f; do
        if [[ -e "$dest/$f" || -L "$dest/$f" ]]; then
            mkdir -p "$backup/$(dirname "$f")"
            mv "$dest/$f" "$backup/$f"
        fi
    done < <(git -C "$dest" ls-tree -r --name-only HEAD)
    git -C "$dest" reset --quiet --hard HEAD

    echo "agents: cloned $url into $dest"
    [[ -d "$backup" ]] && echo "agents: replaced files moved to $backup"
    return 0
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

echo "dotfiles: installing profile '$DOTFILES_PROFILE'"
cd "$DOTFILES"
stow --restow --target="$HOME" ${ignore[@]+"${ignore[@]}"} ${stow_args[@]+"${stow_args[@]}"} .

if ((agents)); then
    for r in "${AGENT_REPOS[@]}"; do
        # shellcheck disable=SC2086  # "dest url" pair
        install_agent_repo $r
    done
fi
