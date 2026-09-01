#!/bin/bash
# Java toolchain for Fedora: SDKMAN + Eclipse Temurin 25 (default) + 21 + Maven.
#
# The Fedora system JDK (java-*-openjdk-headless) is left untouched and
# `alternatives` is never modified. SDKMAN manages only the development JDKs
# under ~/.sdkman. Shell integration lives in dot_config/zsh/integrations.zsh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root

# Pinned, validated versions. Keep in sync with .chezmoi.toml.tmpl and
# dot_config/Code/User/settings.json.tmpl.
JAVA_DEFAULT="25.0.4-tem"
JAVA_LTS="21.0.12+1.1-tem"
MAVEN_VERSION="3.9.16"

export SDKMAN_DIR="$HOME/.sdkman"

# --- SDKMAN --------------------------------------------------------------
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  ok "SDKMAN already installed"
else
  log "installing SDKMAN (rc files not modified: rcupdate=false)"
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || die "SDKMAN installation failed"

export sdkman_auto_answer=true
export sdkman_selfupdate_feature=false
# SDKMAN's init script is not written for `set -eu`.
set +eu
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -eu

# Auto-env is intentionally left at its default (disabled).
if grep -q '^sdkman_auto_env=true' "$SDKMAN_DIR/etc/config" 2>/dev/null; then
  warn "sdkman_auto_env is enabled in ~/.sdkman/etc/config (not set by this script)"
fi

install_java() {
  local version="$1"
  if [[ -d "$SDKMAN_DIR/candidates/java/$version" ]]; then
    ok "Temurin $version already installed"
  else
    log "installing Temurin $version"
    sdk install java "$version" </dev/null
  fi
}

install_java "$JAVA_LTS"
install_java "$JAVA_DEFAULT"

log "setting Temurin $JAVA_DEFAULT as the default JDK"
sdk default java "$JAVA_DEFAULT" </dev/null

# --- Maven ------------------------------------------------------------
if [[ -d "$SDKMAN_DIR/candidates/maven/$MAVEN_VERSION" ]]; then
  ok "Maven $MAVEN_VERSION already installed"
else
  log "installing Maven $MAVEN_VERSION"
  sdk install maven "$MAVEN_VERSION" </dev/null
fi
sdk default maven "$MAVEN_VERSION" </dev/null

cat >&2 <<'NOTE'
Java toolchain ready.
  sdk use java 21.0.12+1.1-tem     switch the current shell to Java 21
  sdk env init                     create a project .sdkmanrc
  sdk env                          apply .sdkmanrc in the current directory
Automatic .sdkmanrc switching is deliberately NOT enabled.
The Fedora system OpenJDK and `alternatives` were not modified.
NOTE
