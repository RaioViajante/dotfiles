typeset -U path PATH

# User-local executables.
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# Kimi Code CLI, installed by its official installer into ~/.kimi-code/bin.
[[ -d "$HOME/.kimi-code/bin" ]] && path=("$HOME/.kimi-code/bin" $path)

# Docker Desktop CLI helpers and Compose plugins.
[[ -d "$HOME/.docker/bin" ]] && path=("$HOME/.docker/bin" $path)
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# Visual Studio Code CLI shipped inside the macOS application bundle.
[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && \
  path=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $path)

# Homebrew MySQL client and server commands.
[[ -d "/opt/homebrew/opt/mysql/bin" ]] && path=("/opt/homebrew/opt/mysql/bin" $path)

# Homebrew's versioned Node runtime is keg-only; expose it through the
# managed PATH rather than per-machine symlinks in ~/.local/bin.
[[ -d "/opt/homebrew/opt/node@24/bin" ]] && path=("/opt/homebrew/opt/node@24/bin" $path)

# Rust: Homebrew's keg-only rustup and its proxies (cargo, rustc,
# rust-analyzer, ...), which honour rust-toolchain.toml files, then binaries
# installed with `cargo install`.
[[ -d "/opt/homebrew/opt/rustup/bin" ]] && path=("/opt/homebrew/opt/rustup/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# Java 25 is the current default for Java and Spring Boot work. Java 21 remains
# available through jdk 21 for projects that still require it.
typeset -g JAVA_25_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
typeset -g JAVA_21_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
if [[ -d "$JAVA_25_HOME" ]]; then
  export JAVA_HOME="$JAVA_25_HOME"
  path=("$JAVA_HOME/bin" $path)
elif [[ -d "$JAVA_21_HOME" ]]; then
  export JAVA_HOME="$JAVA_21_HOME"
  path=("$JAVA_HOME/bin" $path)
fi

# pnpm is installed by Homebrew, so PNPM_HOME is intentionally not added.
export PATH
