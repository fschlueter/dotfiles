# dotfiles

Personal shell and app configuration for macOS and Linux, symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Path | What |
|------|------|
| `.zshrc` | zsh config: aliases, history, plugins, PATH, shell integrations (fzf, zoxide) |
| `.zsh/plugins/` | zsh plugins as git submodules (completions, autosuggestions, syntax highlighting) |
| `.env/env` | coding and software environment, sourced by `.zshrc` |
| `.env/omp` | [oh-my-posh](https://ohmyposh.dev) prompt setup |
| `.env/yazi` | `y` wrapper for the [yazi](https://yazi-rs.github.io) file manager (cd's into its last dir), installs yazi and its plugins on first use |
| `.env/local` | machine-specific aliases and functions |
| `.config/ghostty/` | [Ghostty](https://ghostty.org) terminal config |
| `.config/ohmyposh/` | oh-my-posh theme |
| `.config/yazi/` | yazi config; plugins are pinned in `package.toml` (manage with `ya pkg add/upgrade`) and not tracked in git |
| `.config/aerospace/` | [AeroSpace](https://github.com/nikitabobko/AeroSpace) window manager config and session save/restore (macOS, see its [README](.config/aerospace/README.md)) |

## Install

```sh
git clone <repo-url> ~/.dotfiles
~/.dotfiles/install.sh
```

[`install.sh`](install.sh) does the following and is safe to re-run:

1. Installs stow if it is missing: via Homebrew on macOS, on Linux built from source into `~/.local` (no sudo; needs `curl`, `perl` and `make`).
2. Initialises the plugin submodules.
3. Creates `~/.config` if missing, so stow links its subfolders instead of the whole directory.
4. Runs `stow --restow --target=$HOME .`, i.e. links every file in this repo to the same path under `$HOME`.

Extra arguments are passed to stow, e.g. `./install.sh -n -v` for a dry run.

If a real file already exists at a link location (e.g. `~/.zshrc` on a fresh machine), stow aborts with a conflict. Move the file away, or run `./install.sh --adopt` to move it into the repo, then check `git diff`.

## How stow is used here

The repo root is a single stow package whose layout mirrors `$HOME`. To add a config, put it at its home-relative path in the repo and re-run `./install.sh`. Stow links whole directories where it can, so new files in e.g. `~/.config/ghostty/` land in the repo directly.

Files that should not be linked (git files, `.DS_Store`, this README, `install.sh`) are listed in [`.stow-local-ignore`](.stow-local-ignore).

To remove all links: `cd ~/.dotfiles && stow -D --target=$HOME .`
