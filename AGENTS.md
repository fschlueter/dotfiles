# Dotfiles

Personal shell/app config for macOS (primary) and Linux servers. See `README.md` for the file table and install steps.

## Layout and stow

- The repo root is one GNU Stow package mirroring `$HOME`; `./install.sh` (idempotent) runs `stow --restow --target=$HOME .`.
- To add a config, put it at its home-relative path and re-run `./install.sh`. Files that must not be linked go in `.stow-local-ignore` (Perl regexes; it replaces stow's defaults, so git files are listed too).
- Runtime state is gitignored and stow-ignored (e.g. `.config/ohmyposh/theme`, `.config/yazi/plugins/`, `.config/aerospace/session.tsv`).
- Zsh plugins are git submodules in `.zsh/plugins/`.

## Platforms and hosts

Code should work on macOS and Linux; gate OS-specific parts with `$OSTYPE`. Hosts differ through profiles, not branches: `.env/host` selects `.env/hosts/<profile>` (`$DOTFILES_HOST` > `~/.config/dotfiles/host` > FQDN (`hostname -f`) > OS default `darwin`/`linux`). Profiles set `DOTFILES_STOW_IGNORE` (stow `--ignore` regexes without a leading `^/`, used by `install.sh`) and `DOTFILES_NVIM_AI` (AI nvim plugins, read by `lua/config/dotfiles.lua`; plugins use `cond`, not `enabled`, so `lazy-lock.json` keeps their pins). Put host-specific values in a profile, never in shared files, and keep profiles bash-compatible.

## Shell conventions

- zsh and bash are both supported. Shell-independent setup lives in `.env/shell`, which `.zshrc` and `.bashrc` source after their own shell-specific parts (history, completion, plugins, key bindings); put new aliases/integrations there so the two stay in sync, and branch on `$ZSH_VERSION`/`$BASH_VERSION` only if unavoidable. Only `.zshrc` and `*.zsh` may use zsh-only syntax, only `.bashrc` bash-only. Everything else (`.env/*`) is sourced by both and must work in each: no `typeset -T/-U`, `${(P)var}`, glob qualifiers or `${!var}`; use `eval` for indirection. Keep `# shellcheck shell=bash`. Helpers in `.env/tools/core`: `path_append`/`path_prepend`, `dot_have` (executable lookup, ignores functions), `dot_unzip`, `dot_glibc_at_least`.
- `.env/tools/*` files follow one pattern: install the tool on first use if missing (brew on macOS, no-sudo download into `~/.local` on Linux), then configure it. Examples: `.env/tools/omp`, `.env/tools/yazi` (`y()` wrapper, auto-syncs plugins from `package.toml`), `.env/tools/nvim` (installs nvim + tree-sitter-cli, sets `EDITOR`), `.env/tools/core` (fzf, zoxide, uv, shared helpers).
- The base `PATH` is set once in `.env/tools/core` (`~/.local/bin` everywhere, homebrew dirs only on darwin). Use its `path_append`/`path_prepend` helpers for colon-separated vars (dedupes); they are not available yet in host profiles or `install.sh`.
- Python envs are uv-managed in `$ENVS_DIR` (default `~/software/envs`); `.env/env` creates one activation alias per folder. `$DEFAULT_ENV` names the env tools use (nvim's pyright); set both per host in a profile.
- Use `dot_have` (`.env/tools/core`; `whence -p` in zsh, `type -P` in bash) rather than `$commands`/`command -v` when checking for a tool installed mid-session (avoids a stale hash table).
- macOS quirks: `/bin/ls` ignores `LS_COLORS`, so `ls` is aliased to `gls`; `sed -i` needs an argument.

## Themes

**One source: the Ghostty palette** (16 ANSI slots plus text/background/cursor). Ghostty, herdr, oh-my-posh and Claude Code are tied to it by using only ANSI slots, so a palette change recolors all of them; give them new colors as slot names (`red`, `lightBlack`, ...), never hex. The palette has two contexts:

- **Outside herdr**: `Matrix Contrast` (`.config/ghostty/themes/`, selected in `config.ghostty`; reload with Cmd+Shift+,). A tweaked Matrix that repurposes slots so git diffs stay readable: 1 "red" = lime-yellow, 4 = dark green, 5 = cyan-blue, 8 (zsh-autosuggestions) = muted grey-green; default text is teal. The slot comments in the file say what uses each slot.
- **Inside herdr**: a different Ghostty theme, chosen with `herdr-theme <name>` (state: `~/.config/ghostty/theme-herdr`, default Rose Pine; the repo adds `Amber Contrast`). The `herdr` wrapper (`.env/tools/herdr`) sends that theme's colors via OSC 4/10/11/12 just before attaching and resets them (OSC 104/110-112) on exit, so it applies on the next attach, from a shell that has the current wrapper.

What follows the palette:

- **herdr UI**: `[theme] name = "terminal"` in `.config/herdr/config.toml`; reload with `herdr server reload-config`. `~/.config/herdr/` is a real directory holding herdr's runtime state (sessions, sockets, logs); only the files inside it are linked.
- **oh-my-posh**: theme `ansi` (`themes/ansi.toml`, matrix.toml's layout with the closest Matrix Contrast slots), selected by the `theme` state file; `theme-herdr` stays empty so herdr panes use the same. Because the slots were picked for Matrix Contrast's repurposed hues, standard palettes shift some meanings (dirty git red, errors gold). The hex palettes in `themes/` (matrix, rose-pine, amber, ...) stay selectable with `posh-theme` but ignore the palette.
  - `omp.toml` is concatenated with `themes/*.toml` (one palette per file) into `~/.cache/ohmyposh/config.toml` at shell start, so open a new shell to see changes. Segments use purpose-named aliases (`p:git-foreground`, ...) that resolve to the theme's `hue-*` colors. ANSI names cannot be shaded (darken/lighten, gradients).
  - Nerd Font glyphs are invisible private-use chars, so string matching on them fails: edit with Python regex or write `\uXXXX`/`\U000XXXXX` in double-quoted TOML strings (single-quoted TOML strings are literal, `\n` needs double quotes).
  - `parentBackground`/`parentForeground` only resolve within the same `[[blocks]]`; separate blocks give the visible gap between groups. Powerline segments fade out on their own when last, so no extra "end" segment is needed.
  - Slow metrics (CPU/GPU) use the async cache pattern: `_omp_sysload` precmd hook in `.env/tools/omp` reads `~/.cache/ohmyposh/sysload` and refreshes it in a background job (`ps`/`ioreg` on macOS, `/proc/stat` deltas on Linux; GPU is macOS only), exposed as `OMP_CPU`/`OMP_GPU`. Bash and zsh compatible (zsh `precmd` / bash `PROMPT_COMMAND`); avoid zsh-only `&!`. Reuse it for any expensive prompt metric.
- **Claude Code**: `"theme": "dark-ansi"` in `~/.claude/settings.json` (not in this repo). `~/.claude/scripts/statusline.sh` uses ANSI colors unless a custom theme is selected; the earlier custom theme `~/.claude/themes/rose-pine.json` (`custom:rose-pine`) is kept.
- **Shell output**: zsh-syntax-highlighting, zsh-autosuggestions (slot 8), `ls`/completion via `LS_COLORS`, git.

**On their own (for now)**: Neovim and yazi use their own Everforest colorschemes and ignore the palette.

- **Neovim** (LazyVim starter, `.config/nvim/`): options in `lua/config/options.lua`, autocmds in `lua/config/autocmds.lua`, plugins in `lua/plugins/`; versions pinned in `lazy-lock.json`. Derive custom highlight colors from the active colorscheme (`nvim_get_hl`, re-applied in a `ColorScheme` autocmd).
- **Yazi**: config in `.config/yazi/`; plugins pinned in `package.toml` (manage with `ya pkg add/upgrade`), not tracked in git; Everforest flavor in `flavors/`.

## Working here

- Verify aliases, key bindings and startup in a pty: `script -q /dev/null zsh -ic '<cmds>' </dev/null` (or `bash -ic`); plain `zsh -ic` can hang (observed with eza and zoxide's `cd`). Strip colors with `sed 's/\x1b\[[0-9;]*m//g'`. Say what was not run (e.g. Linux install paths).
- Aliases are also defined in `.env/env` and `.env/hosts/*`, not only `.env/shell`: before adding one, `grep -rn 'alias NAME=' .env .zshrc .bashrc`.
- `.githooks/pre-commit` (enabled by `install.sh` via `core.hooksPath`) checks staged changes: gitleaks (regex fallback), `bash -n`/`zsh -n`, shellcheck (`.shellcheckrc`). Run it directly to check before committing.
- Keep README's contents table current when adding a tool or `.env/` file.
