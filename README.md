# dotfiles

Personal shell and app configuration for macOS and Linux, symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

## Platforms and branches

The building blocks (shell setup, `.env/*` tool installers, nvim, yazi, prompt themes) are written to work on both macOS and Linux, with OS checks (`$OSTYPE`) where behaviour differs. Anything outside `.zshrc`/`*.zsh` stays bash-compatible.

Each host gets its own branch for small host-specific differences:

| Branch | Host |
|--------|------|
| `main` | personal macOS laptop (also holds mac-only pieces such as Ghostty, AeroSpace and sketchybar) |
| `linux-server` | remote Ubuntu/Debian servers (x86_64/aarch64), ssh only, no sudo. Drops Ghostty, AeroSpace, sketchybar, llama-swap, the `llama.vim` and `minuet-ai.nvim` plugins (`claudecode.nvim` stays), the prompt's GPU segment and the laptop aliases in `.env/local`; the CPU segment reads `/proc/stat`. |
| *other host branches* | to be added; branch off `main` and keep the diff small |

Keep shared changes on `main` and merge or rebase them into the host branches, so the branches differ only in host-specific config.

### Linux distributions

The installers download prebuilt binaries, so what runs depends on the glibc of the host:

| Distribution | glibc | nvim (needs 2.34) | tree-sitter-cli (needs 2.39) |
|--------------|-------|:-----------------:|:----------------------------:|
| AlmaLinux / RHEL / Rocky 8 | 2.28 | no | no |
| AlmaLinux / RHEL / Rocky 9 | 2.34 | yes | needs `cargo` |
| AlmaLinux / RHEL / Rocky 10 | 2.39 | yes | yes |
| Debian 11 / Ubuntu 20.04 | 2.31 | no | no |
| Debian 12 / Ubuntu 22.04 | 2.35-2.36 | yes | needs `cargo` |
| Debian 13 / Ubuntu 24.04 | 2.39-2.41 | yes | yes |

- Without a usable nvim the `nvim` wrapper prints a message; install Neovim >= 0.11 yourself.
- Without tree-sitter-cli nvim still works, but nvim-treesitter cannot build parsers. The wrapper installs it with `cargo` if present, otherwise it remembers the failure in `~/.cache/no-tree-sitter` (delete it to retry). nvim-treesitter also needs a C compiler (`cc`).
- yazi uses static musl builds and has no glibc requirement.
- glibc minimums were read from the released binaries; the install paths have not yet been run on real servers.

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
| `.config/ghostty/` | [Ghostty](https://ghostty.org) terminal config |
| `.config/ohmyposh/` | oh-my-posh theme |
| `.config/yazi/` | yazi config; plugins are pinned in `package.toml` (manage with `ya pkg add/upgrade`) and not tracked in git |
| `.config/nvim/` | [LazyVim](https://www.lazyvim.org) config (from the starter); plugins are installed by lazy.nvim on first start, pinned in `lazy-lock.json` |
| `.config/aerospace/` | [AeroSpace](https://github.com/nikitabobko/AeroSpace) window manager config and session save/restore (macOS, see its [README](.config/aerospace/README.md)) |

## Install

```sh
git clone <repo-url> ~/.dotfiles
~/.dotfiles/install.sh
```

[`install.sh`](install.sh) does the following and is safe to re-run:

1. Needs `git` up front. Installs stow if it is missing: via Homebrew on macOS, on Linux into `~/.local` (no sudo; needs `curl`, `tar` and `perl`, no `make`).
2. On Linux, installs a static zsh into `~/.local` if zsh is missing and, only with `DOTFILES_BASHRC=1`, adds a hand-over to zsh to `~/.bashrc` for interactive logins (`NO_ZSH=1 bash` bypasses it). Skip this if your login shell is already zsh.
3. Initialises the plugin submodules.
4. Creates `~/.config` if missing, so stow links its subfolders instead of the whole directory.
5. Runs `stow --restow --target=$HOME .`, i.e. links every file in this repo to the same path under `$HOME`.

Extra arguments are passed to stow, e.g. `./install.sh -n -v` for a dry run.

If a real file already exists at a link location (e.g. `~/.zshrc` on a fresh machine), stow aborts with a conflict. Move the file away, or run `./install.sh --adopt` to move it into the repo, then check `git diff`.

## How stow is used here

The repo root is a single stow package whose layout mirrors `$HOME`. To add a config, put it at its home-relative path in the repo and re-run `./install.sh`. Stow links whole directories where it can, so new files in e.g. `~/.config/ghostty/` land in the repo directly.

Files that should not be linked (git files, `.DS_Store`, this README, `install.sh`) are listed in [`.stow-local-ignore`](.stow-local-ignore).

To remove all links: `cd ~/.dotfiles && stow -D --target=$HOME .`
