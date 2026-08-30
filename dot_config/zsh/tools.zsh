# Keep tool initialization explicit and late in startup.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd z)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
