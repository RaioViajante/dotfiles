#!/bin/bash
# Register the local Proton Mail MCP server (~/Developer/proton-mail-mcp,
# managed in its own repo, not here) with Claude Code and Codex at
# user/global scope, so `proton-mail` is available from any working
# directory instead of only inside that repo.
#
# Idempotent and safe to re-run. Never stores or prints secrets: no Bridge
# password, Keychain value, signing key or token is read, generated or
# written by this script. It never overwrites an existing registration that
# already points somewhere else -- it reports the mismatch instead and
# leaves it untouched.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi

repo="$HOME/Developer/proton-mail-mcp"
entrypoint="$repo/dist/index.js"
node_bin="/opt/homebrew/opt/node@24/bin/node"

if [[ ! -d "$repo" ]]; then
  echo "skip: $repo not found. Clone proton-mail-mcp there, then re-run this script." >&2
  exit 0
fi

if [[ ! -d "/Applications/Proton Mail Bridge.app" ]]; then
  echo "warn: Proton Mail Bridge.app not found. Install it (Brewfile: proton-mail-bridge cask) and sign in before proton-mail will work." >&2
fi

if [[ ! -f "$entrypoint" ]]; then
  echo "skip: $entrypoint not built yet. Build it once with:" >&2
  echo "    (cd '$repo' && pnpm install && pnpm run build)" >&2
  echo "then re-run this script." >&2
  exit 0
fi

if [[ ! -x "$node_bin" ]]; then
  echo "skip: expected Node at $node_bin (Brewfile: node@24) but it is missing." >&2
  exit 0
fi

# --- Claude Code: register at user scope, visible from every directory. ---
if command -v claude >/dev/null 2>&1; then
  claude_status="$( (cd "$HOME"; claude mcp get proton-mail 2>&1) || true )"
  if echo "$claude_status" | grep -q "No MCP server named"; then
    (cd "$HOME" && claude mcp add --scope user proton-mail "$node_bin" -- "$entrypoint")
    echo "ok: registered proton-mail in Claude Code (user scope)." >&2
  elif echo "$claude_status" | grep -q "Scope: User config" && echo "$claude_status" | grep -qF "$entrypoint"; then
    echo "ok: proton-mail already registered in Claude Code (user scope)." >&2
  else
    echo "warn: proton-mail is already configured in Claude Code, but not as expected:" >&2
    echo "$claude_status" >&2
    echo "Not changing it automatically; inspect with 'claude mcp get proton-mail' and resolve by hand." >&2
  fi
else
  echo "skip: claude CLI not found." >&2
fi

# --- Codex: config.toml has no per-project scope, so an entry there is
# already global. Match by entrypoint path (not name) since an existing
# machine may have registered it under a different server name. ---
if command -v codex >/dev/null 2>&1; then
  codex_list="$(codex mcp list 2>&1 || true)"
  if echo "$codex_list" | grep -qF "$entrypoint"; then
    match="$(echo "$codex_list" | grep -F "$entrypoint")"
    if echo "$match" | grep -qF "$node_bin"; then
      echo "ok: proton-mail MCP already registered in Codex." >&2
    else
      echo "warn: Codex already has a server pointing at $entrypoint with a different command:" >&2
      echo "$match" >&2
      echo "Not changing it automatically; inspect with 'codex mcp list' and resolve by hand." >&2
    fi
  else
    codex mcp add proton-mail -- "$node_bin" "$entrypoint"
    echo "ok: registered proton-mail MCP server in Codex." >&2
  fi
else
  echo "skip: codex CLI not found." >&2
fi
