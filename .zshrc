
# Aliases
alias ll="ls -l"
if [[ "$OSTYPE" == darwin* ]]; then
    alias ls="gls --color=auto"  # GNU ls honors LS_COLORS; macOS /bin/ls does not
else
    alias ls="ls --color=auto"
fi
alias grep="grep --color=auto"

# Ghostty on the laptop sets TERM=xterm-ghostty, which servers usually have no terminfo for
if [[ "$TERM" == xterm-ghostty ]] && ! infocmp "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

# git aliases
alias gitclean='git branch --merged | grep -Ev "(^\*|master|main|develop)" | xargs git branch -d'
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

### PATH

# Basic locations for user-installed tools. Set before the integrations below,
# which are installed in these dirs.
export PATH="$HOME/.local/bin:$PATH"
if [[ "$OSTYPE" == darwin* ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

### Colors
if [[ "$OSTYPE" == darwin* ]]; then
    eval "$(gdircolors -b)"
else
    eval "$(dircolors -b)"
fi
LS_COLORS+=":fi=92"  # regular files: bright green (Ghostty palette 10)

### Shell integrations

# installs fzf, zoxide and uv if missing
source ~/.env/tools

# fuzzy finder
whence -p fzf >/dev/null && source <(fzf --zsh)
# fd is optional (Debian/Ubuntu name it fdfind); without it fzf falls back to find
if whence -p fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --exclude .cache . ~'
elif whence -p fdfind >/dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git --exclude .cache . ~'
fi
[[ -n $FZF_DEFAULT_COMMAND ]] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# replace cd with zoxide
whence -p zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# prompt engine
source ~/.env/omp

### Programs

# file manager (`y`)
source ~/.env/yazi

# editor (`nvim`)
source ~/.env/nvim
alias vim=nvim

# uv

alias vd='uvx --with pyarrow visidata'

### Set up woring environments

source ~/.env/env  # coding and software environment
source ~/.env/local  # local stuff
