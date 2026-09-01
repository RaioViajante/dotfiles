#!/bin/bash
# Shared helpers for the bootstrap scripts. Source this file; do not execute it.
# All output is English and goes to stderr so stdout stays machine-readable.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m  !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m  xx\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

require_fedora() {
  [[ -r /etc/os-release ]] || die "cannot read /etc/os-release"
  . /etc/os-release
  [[ "${ID:-}" == "fedora" ]] || die "this script targets Fedora (found ID=${ID:-unknown})"
  has dnf || die "dnf is not available"
}

# Never run the whole script as root; individual steps call sudo explicitly.
refuse_root() {
  [[ "${EUID:-$(id -u)}" -ne 0 ]] || die "do not run this script as root; it will call sudo when needed"
}

# Install only the packages that are missing. Accepts a list of package names.
dnf_install_missing() {
  local pkg missing=()
  for pkg in "$@"; do
    rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "all requested packages already installed"
    return 0
  fi
  log "installing: ${missing[*]}"
  sudo dnf install -y "${missing[@]}"
}
