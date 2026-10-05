# dotfiles

Personal shell and app configuration for macOS and Linux, symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

## Platforms and hosts

The building blocks (shell setup, `.env/*` tool installers, nvim, yazi, prompt themes) are written to work on both macOS and Linux, with OS checks (`$OSTYPE`) where behaviour differs. Anything outside `.zshrc`/`*.zsh` stays bash-compatible.

Hosts differ through a **profile** (`.env/hosts/<profile>`), not through branches. `.env/host` picks the first that exists of: `$DOTFILES_HOST`, the first line of `~/.config/dotfiles/host` (untracked override), the short hostname; otherwise the OS default (`darwin` or `linux`). A profile is a small bash-compatible script that sets:

| Variable | Effect |
|----------|--------|
| `DOTFILES_STOW_IGNORE` | space-separated regexes `install.sh` passes to stow as `--ignore` (e.g. the macOS-only configs on Linux) |
| `DOTFILES_SHELL` | `zsh` or `bash`: the shell this host should use. If a shell is started the other way (e.g. a bash login shell that can't be changed without root), its rc file hands over with `exec`; unset keeps whatever started. `DOTFILES_NO_HANDOVER=1` skips it. Defaults: `zsh` on macOS, `bash` on Linux, `zsh` on `NuRadioOpt-GPU` |
| `DOTFILES_AUTO_INSTALL` | `0` stops missing fzf/zoxide/uv/oh-my-posh being installed at shell start (default `1`) |
| `DOTFILES_NVIM_AI` | AI nvim plugins to load (`claudecode`, `minuet`); the others stay unloaded, their pins stay in `lazy-lock.json` |

It can also hold aliases and exports for that host (the laptop's DESY aliases live in `hosts/darwin`). To give a server its own settings, add `.env/hosts/<hostname>` and re-run `./install.sh`.

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
| `.zshrc`, `.bashrc` | per-shell parts only: history, completion, plugins, key bindings. Login shells must source `.bashrc`; the stock `~/.profile` (Debian/Ubuntu) and `~/.bash_profile` (RHEL/Alma) already do, so no `.bash_profile` is shipped |
| `.env/shell` | everything shell-independent, sourced by both: aliases, PATH, colors, fzf, zoxide, prompt, tools, environments |
| `.zsh/plugins/` | zsh plugins as git submodules (completions, autosuggestions, syntax highlighting) |
| `.env/env` | coding and software environment, sourced by `.env/shell` |
| `.env/omp` | [oh-my-posh](https://ohmyposh.dev) prompt setup |
| `.env/yazi` | `y` wrapper for the [yazi](https://yazi-rs.github.io) file manager (cd's into its last dir), installs yazi and its plugins on first use |
| `.env/nvim` | `nvim` wrapper, installs [Neovim](https://neovim.io) and `tree-sitter-cli` on first use |
| `.env/host`, `.env/hosts/` | host profiles (see above); `.env/local` is for anything else machine-specific |
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
2. On Linux, installs a static zsh into `~/.local` if zsh is missing.
3. Initialises the plugin submodules.
4. Creates `~/.config` if missing, so stow links its subfolders instead of the whole directory.
5. Runs `stow --restow --target=$HOME .`, i.e. links every file in this repo to the same path under `$HOME`.

Extra arguments are passed to stow, e.g. `./install.sh -n -v` for a dry run.

If a real file already exists at a link location (e.g. `~/.zshrc` or `~/.bashrc` on a fresh machine), stow aborts with a conflict. Move the file away, or run `./install.sh --adopt` to move it into the repo, then check `git diff`.

## How stow is used here

The repo root is a single stow package whose layout mirrors `$HOME`. To add a config, put it at its home-relative path in the repo and re-run `./install.sh`. Stow links whole directories where it can, so new files in e.g. `~/.config/ghostty/` land in the repo directly.

Files that should not be linked (git files, `.DS_Store`, this README, `install.sh`) are listed in [`.stow-local-ignore`](.stow-local-ignore).

To remove all links: `cd ~/.dotfiles && stow -D --target=$HOME .`
