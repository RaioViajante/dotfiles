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
