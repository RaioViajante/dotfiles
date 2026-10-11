#!/bin/bash
# Set up Rust through rustup (brew/dev.Brewfile): the stable toolchain with
# rustfmt, clippy and rust-analyzer. rust-analyzer comes only from this rustup
# component; Neovim and VS Code use its proxy, so a project's
# rust-toolchain.toml or rust-toolchain file still selects the toolchain.
#
# Run by `setup dev`; safe to run by hand and to rerun. An installed stable
# toolchain is never updated (only missing components are added), an existing
# default toolchain is never changed, and no cargo utilities are installed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"
refuse_root

# Homebrew's rustup is keg-only: rustup and its proxies (cargo, rustc,
# rust-analyzer, ...) live in $(brew --prefix rustup)/bin, which is not on PATH
# by default. Use it for this process when present, without editing shell files.
rustup_bin="$(homebrew_prefix)/opt/rustup/bin"
[[ -x "$rustup_bin/rustup" ]] && PATH="$rustup_bin:$PATH"
has rustup || die "rustup not found; install it with 'setup dev' (brew/dev.Brewfile)"

# Run outside any project so no toolchain file or directory override applies.
cd "$(mktemp -d)"

components=(rustfmt clippy rust-analyzer)
if rustup toolchain list | grep -q '^stable-'; then
  log "stable toolchain present; adding any missing components"
  rustup component add --toolchain stable "${components[@]}"
else
  log "installing the stable toolchain (minimal profile + ${components[*]})"
  rustup toolchain install stable --profile minimal --no-self-update \
    --component rustfmt --component clippy --component rust-analyzer
fi

if rustup default >/dev/null 2>&1; then
  ok "default toolchain kept: $(rustup default)"
else
  rustup default stable
fi

ok "rust-analyzer: $(rustup which --toolchain stable rust-analyzer)"
ok "Rust ready: $(rustup run stable rustc --version)"
