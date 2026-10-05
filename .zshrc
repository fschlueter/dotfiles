# zsh-specific setup; everything shell-independent is in .env/shell (shared with .bashrc)

# host profile (flags per host or OS, see .env/host)
source ~/.env/host
# hand over to bash where the profile asks for it (DOTFILES_NO_HANDOVER=1 skips)
if [[ ${DOTFILES_SHELL-} == bash && -z ${DOTFILES_NO_HANDOVER-} ]] && whence -p bash >/dev/null; then
    exec bash -l
fi

### History

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

### Globbing

# Pass unmatched patterns through literally (like bash), so remote globs work: scp host:/data/run26* .
setopt nonomatch

### zsh plugins

fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

ZSH_AUTOSUGGEST_STRATEGY=(completion history)
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# set key bindings
bindkey '^[[Z' autosuggest-accept   # Shift+Tab
bindkey '^[[1;5C' forward-word       # Ctrl+Right
bindkey '^[[1;5D' backward-word      # Ctrl+Left
bindkey '^[[1;3C' forward-word       # Alt+Right
bindkey '^[[1;3D' backward-word      # Alt+Left
bindkey '^[[H' beginning-of-line     # Home / Cmd+Left
bindkey '^[[F' end-of-line           # End / Cmd+Right


# This allows to loop over an array of words in zsh/bash scripts
set -o shwordsplit

### Shared setup (aliases, PATH, colors, fzf, zoxide, prompt, tools, environments)

source ~/.env/shell

# needs LS_COLORS from the shared setup
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
