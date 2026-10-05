# Dotfiles

Personal shell/app config for macOS (primary) and Linux servers. See `README.md` for the file table and install steps.

## Layout and stow

- The repo root is one GNU Stow package mirroring `$HOME`; `./install.sh` (idempotent) runs `stow --restow --target=$HOME .`.
- To add a config, put it at its home-relative path and re-run `./install.sh`. Files that must not be linked go in `.stow-local-ignore` (Perl regexes; it replaces stow's defaults, so git files are listed too).
- Runtime state is gitignored and stow-ignored (e.g. `.config/ohmyposh/theme`, `.config/yazi/plugins/`, `.config/aerospace/session.tsv`).
- Zsh plugins are git submodules in `.zsh/plugins/`.

## Platforms and hosts

Code should work on macOS and Linux; gate OS-specific parts with `$OSTYPE`. Hosts differ through profiles, not branches: `.env/host` selects `.env/hosts/<profile>` (`$DOTFILES_HOST` > `~/.config/dotfiles/host` > short hostname > OS default `darwin`/`linux`). Profiles set `DOTFILES_STOW_IGNORE` (stow `--ignore` regexes without a leading `^/`, used by `install.sh`) and `DOTFILES_NVIM_AI` (AI nvim plugins, read by `lua/config/dotfiles.lua`; plugins use `cond`, not `enabled`, so `lazy-lock.json` keeps their pins). Put host-specific values in a profile, never in shared files, and keep profiles bash-compatible.

## Shell conventions

- zsh and bash are both supported. Shell-independent setup lives in `.env/shell`, which `.zshrc` and `.bashrc` source after their own shell-specific parts (history, completion, plugins, key bindings); put new aliases/integrations there so the two stay in sync, and branch on `$ZSH_VERSION`/`$BASH_VERSION` only if unavoidable. Only `.zshrc` and `*.zsh` may use zsh-only syntax, only `.bashrc` bash-only. Everything else (`.env/*`) is sourced by both and must work in each: no `typeset -T/-U`, `${(P)var}`, glob qualifiers or `${!var}`; use `eval` for indirection. Keep `# shellcheck shell=bash`. Helpers in `.env/tools`: `_have` (executable lookup, ignores functions), `_unzip`, `_glibc_at_least`.
- `.env/*` files follow one pattern: install the tool on first use if missing (brew on macOS, no-sudo download into `~/.local` on Linux), then configure it. Examples: `.env/omp`, `.env/yazi` (`y()` wrapper, auto-syncs plugins from `package.toml`), `.env/nvim` (installs nvim + tree-sitter-cli, sets `EDITOR`), `.env/tools` (fzf, zoxide, uv).
- `PATH` is set once in `.env/shell` (`~/.local/bin` everywhere, homebrew dirs only on darwin). Use the `path_append`/`path_prepend` helpers in `.env/env` for colon-separated vars (dedupes).
- Python envs are uv-managed in `~/software/uvenvs`; `.env/env` creates one activation alias per folder.
- Use `_have` (`.env/tools`; `whence -p` in zsh, `type -P` in bash) rather than `$commands`/`command -v` when checking for a tool installed mid-session (avoids a stale hash table).
- macOS quirks: `/bin/ls` ignores `LS_COLORS`, so `ls` is aliased to `gls`; `sed -i` needs an argument.

## Themes

Keep nvim, Ghostty and oh-my-posh looks aligned (soft preference): when theming one, check the other two first.

- **Ghostty**: `Matrix Contrast` (`.config/ghostty/themes/`, selected in `config.ghostty`) is a tweaked copy of Matrix and deliberately repurposes ANSI slots (1 "red" = amber/yellow, 4 = dark green, 5 = cyan-blue) so git diffs stay readable. Default fg is muted grey-green so untouched lines differ from `+` lines. Reload with Cmd+Shift+,.
- **oh-my-posh**: edit `.config/ohmyposh/omp.toml`. `.env/omp` concatenates it with `themes/*.toml` (one palette per file) into `~/.cache/ohmyposh/config.toml` at shell start, so open a new shell to see changes. Themes: default, catppuccin, dracula, everforest, gruvbox, matrix, nord; chosen by the `theme` state file. The `matrix` theme is not yet aligned with Matrix Contrast.
  - Segments use purpose-named palette aliases (`p:git-foreground`, ...) that resolve to base `hue-*` colors; don't hardcode hex.
  - Nerd Font glyphs are invisible private-use chars, so string matching on them fails: edit with Python regex or write `\uXXXX`/`\U000XXXXX` in double-quoted TOML strings (single-quoted TOML strings are literal, `\n` needs double quotes).
  - `parentBackground`/`parentForeground` only resolve within the same `[[blocks]]`; separate blocks give the visible gap between groups. Powerline segments fade out on their own when last, so no extra "end" segment is needed.
  - Slow metrics (CPU/GPU) use the async cache pattern: `_omp_sysload` precmd hook in `.env/omp` reads `~/.cache/ohmyposh/sysload` and refreshes it in a background job (`ps`/`ioreg` on macOS, `/proc/stat` deltas on Linux; GPU is macOS only), exposed as `OMP_CPU`/`OMP_GPU`. Bash and zsh compatible (zsh `precmd` / bash `PROMPT_COMMAND`); avoid zsh-only `&!`. Reuse it for any expensive prompt metric.
- **Neovim** (LazyVim starter, `.config/nvim/`): options in `lua/config/options.lua`, autocmds in `lua/config/autocmds.lua`, plugins in `lua/plugins/`; versions pinned in `lazy-lock.json`. Derive custom highlight colors from the active theme (`nvim_get_hl`, re-applied in a `ColorScheme` autocmd), never hardcoded hex. Current colorscheme family: everforest.
- **Yazi**: config in `.config/yazi/`; plugins pinned in `package.toml` (manage with `ya pkg add/upgrade`), not tracked in git; Everforest flavor in `flavors/`.

## Working here

- Most changes can't be verified without a new shell/terminal; syntax-check instead (`zsh -n`, `bash -n`, `oh-my-posh config export`) and say what was not run.
- Keep README's contents table current when adding a tool or `.env/` file.
- Check for secrets before pushing (gitleaks was discussed).
