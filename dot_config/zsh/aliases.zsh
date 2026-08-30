# Navigation and files. Native ls/cat remain untouched.
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias l='eza --group-directories-first'
alias ll='eza -lah --group-directories-first --git'
alias tree='eza --tree --group-directories-first'
alias bcat='bat --paging=never'

# Git.
alias g='git'
alias gs='git st'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git lg'

# pnpm.
alias p='pnpm'
alias pi='pnpm install'
alias pd='pnpm dev'
alias pb='pnpm build'
alias pt='pnpm test'

# Containers.
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias pods='podman ps'

# Useful inspection commands.
alias ports='lsof -nP -iTCP -sTCP:LISTEN'
alias myip='curl -fsS https://api.ipify.org; echo'
