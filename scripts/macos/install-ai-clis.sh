#!/bin/bash
# Install the terminal AI coding agents that ship their own official installers:
# Claude Code (claude), Codex CLI (codex) and Kimi Code (kimi). Each installer
# self-updates the tool afterwards. OpenCode comes from brew/ai.Brewfile.
#
# Run by `setup ai` (and `setup all`); safe to run by hand and to rerun. A tool
# whose command is already available (from any install method) is skipped, so
# an existing installation is never replaced or duplicated. Sign-in stays
# manual; no credentials or tokens are read or written. Exits non-zero when any
# installation fails. Usage: install-ai-clis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"
refuse_root
has curl || die "curl is required"

# The managed zsh config already puts these directories on PATH. Adding them
# here too keeps the installers from appending their own PATH lines to shell
# startup files; any edit that still happens is reverted below.
export PATH="$HOME/.local/bin:$HOME/.kimi-code/bin:$PATH"
export KIMI_NO_MODIFY_PATH=1

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

shell_files=(.zshrc .zprofile .zshenv .bashrc .bash_profile .profile)

# Keep a copy of each shell startup file (or a marker that it was absent).
snapshot_shell_files() {
  local file
  rm -rf "$tmp_dir/shell" && mkdir -p "$tmp_dir/shell"
  for file in "${shell_files[@]}"; do
    if [[ -e "$HOME/$file" ]]; then
      cp -p "$HOME/$file" "$tmp_dir/shell/$file"
    else
      : >"$tmp_dir/shell/$file.absent"
    fi
  done
}

# Undo any change an installer made to the shell startup files.
restore_shell_files() {
  local name="$1" file
  for file in "${shell_files[@]}"; do
    if [[ -e "$tmp_dir/shell/$file.absent" ]]; then
      if [[ -e "$HOME/$file" ]]; then
        rm -f "$HOME/$file"
        warn "$name installer created ~/$file; removed it (PATH is managed by dot_config/zsh)"
      fi
    elif ! cmp -s "$tmp_dir/shell/$file" "$HOME/$file"; then
      cp -p "$tmp_dir/shell/$file" "$HOME/$file"
      warn "$name installer edited ~/$file; restored it (PATH is managed by dot_config/zsh)"
    fi
  done
}

installed=()
skipped=()
failed=()

# install_cli <name> <command> <installer-url> <interpreter>
install_cli() {
  local name="$1" command="$2" url="$3" interpreter="$4"
  local script="$tmp_dir/$command-install.sh" status=0

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
  snapshot_shell_files
  "$interpreter" "$script" || status=$?
  restore_shell_files "$name"
  if (( status != 0 )); then
    warn "the $name installer failed (exit $status)"
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
