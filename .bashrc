# shellcheck shell=bash
# bash-specific setup; everything shell-independent is in .env/shell (shared with .zshrc)

# Non-interactive shells (scp, ssh host cmd) must stay silent and unchanged
[[ $- == *i* ]] || return

# host profile (flags per host or OS, see .env/host)
source ~/.env/host

### History

HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups  # ignore duplicates and lines starting with a space
shopt -s histappend checkwinsize
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"  # share history between sessions

### Completion

for f in /usr/share/bash-completion/bash_completion /etc/bash_completion /opt/homebrew/etc/profile.d/bash_completion.sh; do
    # shellcheck disable=SC1090
    [[ -r $f ]] && { . "$f"; break; }
done
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'

# set key bindings
bind '"\e[1;5C": forward-word'       # Ctrl+Right
bind '"\e[1;5D": backward-word'      # Ctrl+Left
bind '"\e[1;3C": forward-word'       # Alt+Right
bind '"\e[1;3D": backward-word'      # Alt+Left
bind '"\e[H": beginning-of-line'     # Home / Cmd+Left
bind '"\e[F": end-of-line'           # End / Cmd+Right

### Shared setup (aliases, PATH, colors, fzf, zoxide, prompt, tools, environments)

source ~/.env/shell
