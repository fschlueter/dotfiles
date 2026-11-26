# zsh-specific setup; everything shell-independent is in .env/shell (shared with .bashrc)

### History

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

### Globbing
#alias scp='noglob scp'
#alias rsync='noglob rsync'
# Pass unmatched patterns through literally (like bash), so remote globs work: scp host:/data/run26* .
setopt nonomatch

### zsh plugins

fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

ZSH_AUTOSUGGEST_STRATEGY=(completion history)
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# set key bindings
bindkey -e  # emacs keymap (Ctrl+A/E, ...); zsh would pick vi mode when it starts with EDITOR=nvim inherited (e.g. herdr panes)
bindkey '^[[3~' delete-char          # Delete / Fn+Backspace
WORDCHARS=${WORDCHARS//\/}           # word motions/kills stop at '/' (path components)
bindkey '^[[Z' autosuggest-accept   # Shift+Tab
bindkey '^[[1;5C' forward-word       # Ctrl+Right
bindkey '^[[1;5D' backward-word      # Ctrl+Left
bindkey '^[[1;3C' forward-word       # Alt+Right
bindkey '^[[1;3D' backward-word      # Alt+Left
bindkey '^[[H' beginning-of-line     # Home / Cmd+Left
bindkey '^[[F' end-of-line           # End / Cmd+Right


# This allows to loop over an array of words in zsh/bash scripts
set -o shwordsplit

### Shared setup; must come after the zsh parts above (compinit, shwordsplit)

source ~/.env/host  # host profile (flags per host or OS); presets variables used by .env/shell
source ~/.env/shell

# needs LS_COLORS from the shared setup
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# last: wraps only widgets defined before it (fzf, zoxide, oh-my-posh)
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Up/Down search history for the typed text (e.g. `sudo` + Up); after syntax highlighting, as its README asks
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
HISTORY_SUBSTRING_SEARCH_PREFIXED=1      # match only at the start of the command
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
bindkey '^[[A' history-substring-search-up    # Up
bindkey '^[[B' history-substring-search-down  # Down
bindkey '^[OA' history-substring-search-up    # Up/Down in application cursor mode (e.g. inside tmux)
bindkey '^[OB' history-substring-search-down
