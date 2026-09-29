
# Aliases
alias ll="ls -l"
alias ls="ls --color=auto"
alias grep="grep --color=auto"

# git aliases
alias gitclean='git branch --merged | egrep -v "(^\*|master|main|develop)" | xargs git branch -d'
alias gitadd='git ls-files --modified | xargs git add'
alias st='git status'
alias co='git checkout'

### History

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

### zsh plugins

fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

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

### PATH

# Basic locations for user-installed tools. Set before the integrations below,
# which are installed in these dirs.
export PATH="$HOME/.local/bin:$PATH"
if [[ "$OSTYPE" == darwin* ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

### Colors
eval "$(gdircolors -b)"

### Shell integrations

# fuzzy finder
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --exclude .cache . ~'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# replace cd with zoxide
eval "$(zoxide init zsh --cmd cd)"

# prompt engine
source ~/.env/omp

### Programs

# file manager (`y`)
source ~/.env/yazi

# editor (`nvim`)
source ~/.env/nvim
alias vim=nvim

### Set up woring environments

source ~/.env/env  # coding and software environment
source ~/.env/local  # local stuff
