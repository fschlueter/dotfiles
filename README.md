# dotfiles

Personal shell and app configuration for macOS and Linux, symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

## Load order

An interactive shell runs, top to bottom. Every file shown is always sourced, except in `.env/hosts/`: the OS default plus at most one host profile.

```
~/.zshrc  or  ~/.bashrc       (a bash login shell gets there via the stock ~/.profile or ~/.bash_profile;
│                              non-interactive bash, e.g. scp, stops at the top of .bashrc)
├── zsh:  history, nonomatch, compinit + .zsh/plugins/zsh-completions, zsh-autosuggestions,
│         key bindings, shwordsplit
│   bash: history, system bash_completion (first one found), readline bindings
├── .env/host                 always: picks the profile (reads ~/.config/dotfiles/host, `hostname -f`),
│   │                         exports DOTFILES_* flags, prints the banner. install.sh sources it too.
│   ├── .env/hosts/darwin  OR  .env/hosts/linux     always: the OS default
│   └── .env/hosts/<name>     at most one, only if it exists, on top: $DOTFILES_HOST > ~/.config/dotfiles/host > FQDN
├── .env/shell                aliases (ls/ll/la/lt/grep), TERM fallback for xterm-ghostty
│   ├── .env/tools/core       path_append/path_prepend, dot_have, dot_unzip, dot_glibc_at_least;
│   │                         base PATH; installs fzf, zoxide, uv if missing
│   ├── (shell)               LS_COLORS, fzf init + FZF_DEFAULT_COMMAND, zoxide (as cd), uv completion (bash)
│   ├── .env/tools/omp        installs oh-my-posh if missing; CPU/GPU hook; builds ~/.cache/ohmyposh/config.toml
│   │                         from omp.toml + themes/*.toml; oh-my-posh init; posh-theme
│   ├── .env/tools/yazi       defines y() (installs yazi and its plugins on first call)
│   ├── .env/tools/nvim       EDITOR/VISUAL; defines nvim() (installs nvim and tree-sitter on first call)
│   ├── (shell)               alias vim
│   ├── .env/tools/eza        installs eza if missing; ls-style ls, ll, la, lt, ltree, lsize become eza
│   ├── .env/tools/herdr      defines herdr() (installs herdr on first call); cached zsh/bash completion
│   └── .env/env              SOFTWARE, venv aliases from ENVS_DIR, DEFAULT_ENV, PYTHONPATH, MATPLOTLIB, RNO-G paths,
│                             thisroot (macOS), uv, git and vd aliases
└── zsh: completion menu + list-colors (needs LS_COLORS), then zsh-syntax-highlighting (wraps all widgets defined before it),
          zsh-history-substring-search (after it, as its README asks) + Up/Down bindings
```

The shell-specific part must come first: bash's `history -a` has to be in `PROMPT_COMMAND` before `.env/tools/omp` puts the prompt hook ahead of it (bash < 5.1), bash-completion and zsh's `compinit` before fzf/zoxide, and `shwordsplit` before the bash-style shared files. Profiles run before `.env/shell`, so they can preset variables (`SOFTWARE`, `ENVS_DIR`, `python_module_extra`, ...) that `.env/env` only defaults.

## Platforms and hosts

The building blocks (shell setup, `.env/*` tool installers, nvim, yazi, prompt themes) are written to work on both macOS and Linux, with OS checks (`$OSTYPE`) where behaviour differs. Anything outside `.zshrc`/`*.zsh` stays bash-compatible.

Hosts differ through a **profile** (`.env/hosts/<profile>`), not through branches. `.env/host` picks the first that exists of: `$DOTFILES_HOST`, the first line of `~/.config/dotfiles/host` (untracked override), the FQDN (`hostname -f`; short names collide, e.g. two hosts called `rno-g`); otherwise the OS default (`darwin` or `linux`). A profile is a small bash-compatible script that sets:

| Variable | Effect |
|----------|--------|
| `DOTFILES_STOW_IGNORE` | space-separated regexes `install.sh` passes to stow as `--ignore` (e.g. the macOS-only configs on Linux) |
| `DOTFILES_AUTO_INSTALL` | `0` stops missing fzf/zoxide/uv/oh-my-posh/eza being installed at shell start (default `1`) |
| `DOTFILES_NVIM_AI` | AI nvim plugins to load (`claudecode`, `minuet`); the others stay unloaded, their pins stay in `lazy-lock.json` |
| `ENVS_DIR` | folder holding the Python envs; `.env/env` creates one activation alias per env (default `$SOFTWARE/envs`) |
| `DEFAULT_ENV` | env in `ENVS_DIR` that tools use, e.g. nvim's pyright (default `py314`; `hosts/darwin` sets `py315`, the Python Homebrew ROOT is built for) |

It can also hold aliases and exports for that host (the laptop's DESY aliases live in `hosts/darwin`). To give a server its own settings, add `.env/hosts/<FQDN>` and re-run `./install.sh`.

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
| `.zsh/plugins/` | zsh plugins as git submodules (completions, autosuggestions, syntax highlighting, history substring search: type a prefix, then Up/Down) |
| `.env/env` | coding and software environment, sourced by `.env/shell` |
| `.env/tools/core` | base PATH, installs fzf, zoxide and uv on first use; shared helpers (`path_append`/`path_prepend`, `dot_have`, `dot_unzip`, `dot_glibc_at_least`) |
| `.env/tools/eza` | installs [eza](https://eza.rocks) on first use; `ls` (grid), `ll`/`la` (long, git status), `lt` (newest last), `ltree`, `lsize` use eza; GNU `ls` aliases without it |
| `.env/tools/omp` | [oh-my-posh](https://ohmyposh.dev) prompt setup |
| `.env/tools/yazi` | `y` wrapper for the [yazi](https://yazi-rs.github.io) file manager (cd's into its last dir), installs yazi and its plugins on first use |
| `.env/tools/nvim` | `nvim` wrapper, installs [Neovim](https://neovim.io) and `tree-sitter-cli` on first use |
| `.env/tools/herdr` | `herdr` wrapper, installs [herdr](https://herdr.dev) on first use (official installer); shell completion; key binding cheat sheet; recolors Ghostty with another theme while herdr is attached (`herdr-theme`) |
| `.env/host`, `.env/hosts/` | host profiles (see above) |
| `.config/ghostty/` | [Ghostty](https://ghostty.org) terminal config |
| `.config/ohmyposh/` | oh-my-posh theme |
| `.config/herdr/` | [herdr](https://herdr.dev) config (`config.toml`); `~/.config/herdr/` also holds herdr runtime state, so only the files are linked |
| `.config/yazi/` | yazi config; plugins are pinned in `package.toml` (manage with `ya pkg add/upgrade`) and not tracked in git |
| `.tmux.conf` | tmux: passes image escape codes and `TERM`/`TERM_PROGRAM` through, so yazi image previews work inside tmux; Ctrl+S as a second prefix next to Ctrl+B |
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
3. Initialises the plugin submodules and enables the pre-commit hook (`.githooks/pre-commit`: secret scan with gitleaks or a regex fallback, `bash -n`/`zsh -n`, shellcheck if installed).
4. Creates `~/.config` if missing, so stow links its subfolders instead of the whole directory.
5. Runs `stow --restow --target=$HOME .`, i.e. links every file in this repo to the same path under `$HOME`.

Extra arguments are passed to stow, e.g. `./install.sh -n -v` for a dry run.

If a real file already exists at a link location (e.g. `~/.zshrc` or `~/.bashrc` on a fresh machine), stow aborts with a conflict. Move the file away, or run `./install.sh --adopt` to move it into the repo, then check `git diff`.

## How stow is used here

The repo root is a single stow package whose layout mirrors `$HOME`. To add a config, put it at its home-relative path in the repo and re-run `./install.sh`. Stow links whole directories where it can, so new files in e.g. `~/.config/ghostty/` land in the repo directly.

Files that should not be linked (git files, `.DS_Store`, this README, `install.sh`, `.githooks/`, `.shellcheckrc`) are listed in [`.stow-local-ignore`](.stow-local-ignore).

To remove all links: `cd ~/.dotfiles && stow -D --target=$HOME .`
