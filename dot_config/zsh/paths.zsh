typeset -U path PATH

# User scripts and portable macOS application CLIs.
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && \
  path=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $path)

# Java 21 LTS is the default for Java and Spring Boot work.
typeset -g JAVA_21_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
if [[ -d "$JAVA_21_HOME" ]]; then
  export JAVA_HOME="$JAVA_21_HOME"
  path=("$JAVA_HOME/bin" $path)
fi

# pnpm is installed by Homebrew, so PNPM_HOME is intentionally not added.
export PATH
