# Luke's config for the Zoomer Shell

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.
setopt interactive_comments

# Load aliases and shortcuts if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' '^ulfcd\n'

bindkey -s '^a' '^ubc -lq\n'

bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^e' edit-command-line
bindkey -M visual '^[[P' vi-delete

# History
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE=$ZDOTDIR/.history
setopt append_history # Allows new commands to be appended to the history file, instead of overwriting it.
setopt inc_append_history # each command is added to the history file immediately after it's executed, not just when the session ends.
setopt share_history # synchronizes the command history between multiple zsh sessions. Commands entered in one session will be available in others.
setopt hist_ignore_dups # Prevents consecutive duplicates from being saved in the command history.
setopt hist_ignore_all_dups # Ignores all duplicate entries in the history, not just consecutive ones.
setopt hist_expire_dups_first #  When the history file reaches its size limit, remove older duplicate entries before removing unique commands.
setopt hist_find_no_dups  # When searching through history, prevent showing duplicate entries.
setopt hist_save_no_dups # When saving the history, omit duplicate entries, so only unique commands are saved.
setopt hist_reduce_blanks # Removes extra blanks from each command line being added to the history.
setopt hist_verify # After a history expansion (like using ! commands), this option prompts for verification before executing the command.

fzf-history-widget-with-date() {
  initial_query="$LBUFFER"
  setopt noglobsubst noposixbuiltins pipefail 2>/dev/null
  entry=$(fc -lir 1 |
          sed -E 's/^[[:space:]+[0-9]+\*?[[:space:]]+//' |
          awk '{cmd=$0; $1=$2=$3=""; sub(/^[ \t]+/, ""); if (!seen[$0]++) print cmd}' |
          fzf --query="$initial_query" +s -i -e)
  [ -n "$entry" ] && LBUFFER=${entry#* * * }
  zle redisplay
}

zle -N fzf-history-widget-with-date
bindkey '^R' fzf-history-widget-with-date


# Load syntax highlighting; should be last.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null
