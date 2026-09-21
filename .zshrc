fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# This allows to loop over an array of words in zsh/bash scripts
set -o shwordsplit

source ~/.env/env  # coding and software environment
source ~/.env/aliases  # aliases
source ~/.env/local  # local stuff

# fuzzy finder
source <(fzf --zsh)

# replace cd with zoxide
eval "$(zoxide init zsh --cmd cd)"

# Prompt engine
export POSH_THEME="$(cat ~/.config/ohmyposh/theme 2>/dev/null)"  # persisted by `posh-theme`
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/omp.toml)"