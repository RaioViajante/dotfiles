#!/bin/bash
# Install the terminal AI coding agents that ship their own official installers:
# Claude Code (claude), Codex CLI (codex) and Kimi Code (kimi). Each installer
# self-updates the tool afterwards. OpenCode comes from brew/ai.Brewfile.
#
# MANUAL step, never run by `chezmoi apply`. Idempotent: a tool whose command
# is already available (from any install method) is skipped, so an existing
# installation is never replaced or duplicated. Sign-in stays manual; no
# credentials or tokens are read or written. Usage: install-ai-clis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"
refuse_root
has curl || die "curl is required"

# The managed zsh config already puts these directories on PATH. Adding them
# here too stops the installers from appending their own PATH lines to the
# chezmoi-managed ~/.zprofile and ~/.zshrc.
export PATH="$HOME/.local/bin:$HOME/.kimi-code/bin:$PATH"
export KIMI_NO_MODIFY_PATH=1

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

installed=()
skipped=()
failed=()

# install_cli <name> <command> <installer-url> <interpreter>
install_cli() {
  local name="$1" command="$2" url="$3" interpreter="$4"
  local script="$tmp_dir/$command-install.sh"

  if has "$command"; then
    ok "$name already installed ($(command -v "$command")); skipping"
    skipped+=("$name")
    return
  fi

  log "installing $name from $url"
  if ! curl -fsSL "$url" -o "$script"; then
    warn "could not download the $name installer"
    failed+=("$name")
    return
  fi
  if ! "$interpreter" "$script"; then
    warn "the $name installer failed"
    failed+=("$name")
    return
  fi
  hash -r
  if has "$command"; then
    ok "$name installed ($(command -v "$command"))"
    installed+=("$name")
  else
    warn "$name installer finished but '$command' is not on PATH"
    failed+=("$name")
  fi
}

# Official installers, as documented by each vendor:
#   https://code.claude.com/docs/en/setup
#   https://learn.chatgpt.com/docs/codex/cli
#   https://moonshotai.github.io/kimi-code/ (Kimi Code, not the older kimi-cli)
install_cli "Claude Code" claude "https://claude.ai/install.sh" bash
install_cli "Codex CLI" codex "https://chatgpt.com/codex/install.sh" sh
install_cli "Kimi Code" kimi "https://code.kimi.com/kimi-code/install.sh" bash

log "installed: ${installed[*]:-none}"
log "skipped:   ${skipped[*]:-none}"
if (( ${#failed[@]} > 0 )); then
  die "failed:    ${failed[*]}"
fi
ok "AI CLIs ready; sign in to each one interactively before first use"
