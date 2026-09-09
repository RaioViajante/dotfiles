#!/bin/bash
# Register the Homebrew OpenJDK formulae with macOS so that /usr/libexec/java_home
# and GUI applications (VS Code, IntelliJ) discover them without relying on the
# Zsh environment. Idempotent and safe to re-run.
#
# sudo is used only to create the symlink inside the system
# /Library/Java/JavaVirtualMachines directory. Do not run the whole script as
# root.
#
# The unversioned "openjdk" formula (pulled in as a Maven dependency, currently
# JDK 26) is deliberately NOT registered: doing so would make it the
# /usr/libexec/java_home default. Java 25 stays the default development JDK
# because it is the newest JDK registered here.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Do not run this script as root; it calls sudo only where required." >&2
  exit 1
fi

brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
jvm_dir="/Library/Java/JavaVirtualMachines"

# Homebrew JDK formulae to register, newest first. The newest one becomes the
# java_home default; JAVA_HOME in the Zsh environment still pins the default.
formulae=(openjdk@25 openjdk@21)

sudo mkdir -p "$jvm_dir"

for formula in "${formulae[@]}"; do
  version="${formula#openjdk@}"
  bundle="$brew_prefix/opt/$formula/libexec/openjdk.jdk"
  link="$jvm_dir/openjdk-$version.jdk"

  if [[ ! -d "$bundle" ]]; then
    echo "skip: $formula is not installed ($bundle missing)" >&2
    continue
  fi

  if [[ "$(readlink "$link" 2>/dev/null || true)" == "$bundle" ]]; then
    echo "ok: $formula already registered at $link" >&2
    continue
  fi

  echo "registering $formula -> $link" >&2
  sudo ln -sfn "$bundle" "$link"
done

echo >&2
echo "Registered JDKs (/usr/libexec/java_home -V):" >&2
/usr/libexec/java_home -V 2>&1 || true
