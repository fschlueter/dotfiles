
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
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

### zsh plugins

fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# This allows to loop over an array of words in zsh/bash scripts
set -o shwordsplit

### PATH

# Basic locations for user-installed tools. Set before the integrations below,
# which are installed in these dirs.
export PATH="$HOME/.local/bin:$PATH"
if [[ "$OSTYPE" == darwin* ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

### Shell integrations

# fuzzy finder
source <(fzf --zsh)

# replace cd with zoxide
eval "$(zoxide init zsh --cmd cd)"

# prompt engine
source ~/.env/omp



source ~/.env/env  # coding and software environment
source ~/.env/local  # local stuff