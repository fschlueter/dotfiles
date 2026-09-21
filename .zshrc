source ~/.env/macos  # macos specific stuff
source ~/.env/env  # coding and software environment
source ~/.env/aliases  # aliases
source ~/.env/local  # local stuff

# fuzzy finder
source <(fzf --zsh)

# Prompt engine
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/omp.toml)"