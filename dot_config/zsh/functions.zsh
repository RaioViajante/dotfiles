mkcd() {
  [[ $# -eq 1 ]] || { print -u2 'usage: mkcd <directory>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  [[ -f "$1" ]] || { print -u2 'usage: extract <archive>'; return 2; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz|*.txz)   tar xJf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.zip)            unzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *) print -u2 "unsupported archive: $1"; return 1 ;;
  esac
}

psg() {
  [[ $# -gt 0 ]] || { print -u2 'usage: psg <pattern>'; return 2; }
  ps aux | rg -i -- "$*"
}

port() {
  [[ "$1" == <-> ]] || { print -u2 'usage: port <number>'; return 2; }
  lsof -nP -iTCP:"$1" -sTCP:LISTEN
}

proj() {
  local root="${PROJECTS_DIR:-$HOME/Developer}"
  local selected
  selected=$(find "$root" -maxdepth 4 -type d -name .git -prune 2>/dev/null | sed 's#/.git$##' | fzf --prompt='project> ')
  [[ -n "$selected" ]] && cd -- "$selected"
}

groot() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  cd -- "$root"
}

serve() {
  local listen_port="${1:-8000}"
  python3 -m http.server "$listen_port"
}
