if (( $+commands[code] )); then
  export EDITOR='code --wait'
  export VISUAL='code --wait'
else
  export EDITOR=vim
  export VISUAL=vim
fi

export PAGER=less
export LESS='-FRX'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'

jdk() {
  if [[ $# -eq 0 ]]; then
    print "active: ${JAVA_HOME:-system}"
    java -version
    print '\navailable:'
    /usr/libexec/java_home -V 2>&1
    [[ -d "$JAVA_21_HOME" ]] && print "    21 (Homebrew) $JAVA_21_HOME"
    return
  fi

  local requested="$1" selected_home
  if [[ "$requested" == 21 && -d "$JAVA_21_HOME" ]]; then
    selected_home="$JAVA_21_HOME"
  else
    selected_home=$(/usr/libexec/java_home -v "$requested" 2>/dev/null) || {
      print -u2 "JDK not found: $requested"
      return 1
    }
  fi

  path=(${path:#*/Contents/Home/bin})
  export JAVA_HOME="$selected_home"
  path=("$JAVA_HOME/bin" $path)
  typeset -U path PATH
  export PATH
  rehash
  java -version
}
