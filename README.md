# dotfiles

Personal shell and app configuration for macOS and Linux, symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

## Platforms and branches

The building blocks (shell setup, `.env/*` tool installers, nvim, yazi, prompt themes) are written to work on both macOS and Linux, with OS checks (`$OSTYPE`) where behaviour differs. Anything outside `.zshrc`/`*.zsh` stays bash-compatible.

Each host gets its own branch for small host-specific differences:

| Branch | Host |
|--------|------|
| `main` | personal macOS laptop (also holds mac-only pieces such as Ghostty, AeroSpace and sketchybar) |
| `linux-server` | remote Ubuntu/Debian servers (x86_64/aarch64), ssh only, no sudo. Drops Ghostty, AeroSpace, sketchybar, llama-swap, the AI nvim plugins (`claudecode.nvim`, `llama.vim`, `minuet-ai.nvim`), the prompt's GPU segment and the laptop aliases in `.env/local`; the CPU segment reads `/proc/stat`. |
| *other host branches* | to be added; branch off `main` and keep the diff small |

Keep shared changes on `main` and merge or rebase them into the host branches, so the branches differ only in host-specific config.

## Contents

| Path | What |
|------|------|
| `.zshrc` | zsh config: aliases, history, plugins, PATH, shell integrations (fzf, zoxide) |
| `.zsh/plugins/` | zsh plugins as git submodules (completions, autosuggestions, syntax highlighting) |
| `.env/env` | coding and software environment, sourced by `.zshrc` |
| `.env/omp` | [oh-my-posh](https://ohmyposh.dev) prompt setup |
| `.env/yazi` | `y` wrapper for the [yazi](https://yazi-rs.github.io) file manager (cd's into its last dir), installs yazi and its plugins on first use |
| `.env/nvim` | `nvim` wrapper, installs [Neovim](https://neovim.io) and `tree-sitter-cli` on first use |
| `.env/local` | machine-specific aliases and functions |
| `.config/ohmyposh/` | oh-my-posh theme |
| `.config/yazi/` | yazi config; plugins are pinned in `package.toml` (manage with `ya pkg add/upgrade`) and not tracked in git |
| `.config/nvim/` | [LazyVim](https://www.lazyvim.org) config (from the starter); plugins are installed by lazy.nvim on first start, pinned in `lazy-lock.json` |

## Install

```sh
git clone <repo-url> ~/.dotfiles
~/.dotfiles/install.sh
```

[`install.sh`](install.sh) does the following and is safe to re-run:

1. Needs `git` up front. Installs stow if it is missing: via Homebrew on macOS, on Linux into `~/.local` (no sudo; needs `curl`, `tar` and `perl`, no `make`).
2. On Linux, installs a static zsh into `~/.local` if zsh is missing and adds a hand-over to zsh to `~/.bashrc` for interactive logins (`DOTFILES_NO_BASHRC=1` skips it, `NO_ZSH=1 bash` bypasses it).
3. Initialises the plugin submodules.
4. Creates `~/.config` if missing, so stow links its subfolders instead of the whole directory.
5. Runs `stow --restow --target=$HOME .`, i.e. links every file in this repo to the same path under `$HOME`.

Extra arguments are passed to stow, e.g. `./install.sh -n -v` for a dry run.

If a real file already exists at a link location (e.g. `~/.zshrc` on a fresh machine), stow aborts with a conflict. Move the file away, or run `./install.sh --adopt` to move it into the repo, then check `git diff`.

## How stow is used here

The repo root is a single stow package whose layout mirrors `$HOME`. To add a config, put it at its home-relative path in the repo and re-run `./install.sh`. Stow links whole directories where it can, so new files in e.g. `~/.config/yazi/` land in the repo directly.

Files that should not be linked (git files, `.DS_Store`, this README, `install.sh`) are listed in [`.stow-local-ignore`](.stow-local-ignore).

To remove all links: `cd ~/.dotfiles && stow -D --target=$HOME .`
