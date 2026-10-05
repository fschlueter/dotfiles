# shellcheck shell=bash
# bash-specific setup; everything shell-independent is in .env/shell (shared with .zshrc)

# Non-interactive shells (scp, ssh host cmd) must stay silent and unchanged
[[ $- == *i* ]] || return

# host profile (flags per host or OS, see .env/host); quiet because the banner is printed below
DOTFILES_QUIET=1
source ~/.env/host
unset DOTFILES_QUIET
# hand over to zsh where the profile asks for it (DOTFILES_NO_HANDOVER=1 skips); lets a bash login
# shell become zsh when it can't be changed without root. Only once per session (DOTFILES_HANDED_OVER):
# a host that switches shells itself must not cause a loop.
if [[ ${DOTFILES_SHELL-} == zsh && -z ${DOTFILES_NO_HANDOVER-} && -z ${DOTFILES_HANDED_OVER-} ]] \
    && PATH="$HOME/.local/bin:$PATH" command -v zsh >/dev/null; then
    export PATH="$HOME/.local/bin:$PATH" DOTFILES_HANDED_OVER=1
    exec zsh -l
fi
_dotfiles_banner

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
