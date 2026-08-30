# History: persistent, shared and deduplicated without losing useful context.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Comfortable, predictable interactive behavior.
setopt ALWAYS_TO_END
setopt AUTO_PUSHD
setopt COMPLETE_IN_WORD
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
unsetopt BEEP

bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
