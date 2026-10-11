#!/bin/bash
# Shared helpers for the bootstrap scripts. Source this file; do not execute it.
# All output is English and goes to stderr so stdout stays machine-readable.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m  !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m  xx\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# Never run the whole script as root; individual steps call sudo explicitly.
refuse_root() {
  [[ "${EUID:-$(id -u)}" -ne 0 ]] || die "do not run this script as root; it will call sudo when needed"
}

# Homebrew's prefix: $HOMEBREW_PREFIX when it points at an installation (brew
# shellenv exports it), else what brew itself reports, else the Apple Silicon
# default. Works without the managed shell configuration.
homebrew_prefix() {
  if [[ -n "${HOMEBREW_PREFIX:-}" && -d "$HOMEBREW_PREFIX" ]]; then
    printf '%s\n' "$HOMEBREW_PREFIX"
  elif has brew; then
    brew --prefix
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    /opt/homebrew/bin/brew --prefix
  else
    printf '%s\n' /opt/homebrew
  fi
}

# Put Homebrew on PATH for this process only (the user's shell files are not
# touched). Returns non-zero when Homebrew is not installed.
use_homebrew() {
  local prefix
  prefix="$(homebrew_prefix)"
  [[ -x "$prefix/bin/brew" ]] || return 1
  eval "$("$prefix/bin/brew" shellenv bash)"
}
