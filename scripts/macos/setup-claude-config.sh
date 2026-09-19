#!/bin/bash
# Reconstruct the intentional, non-sensitive Claude Code user settings:
# theme, TUI mode and the iTerm2 status hooks. Merges into
# ~/.claude/settings.json and only ADDS keys that are missing; it never
# overwrites a value you already set and never touches credentials, OAuth state
# (~/.claude.json), per-project trust or the autoMode notes.
#
# Codex (~/.codex/config.toml) is intentionally not edited: its model and
# per-project trust are chosen interactively, and the proton-mail MCP entry is
# handled by setup-proton-mcp.sh. MANUAL step, idempotent, no sudo.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi

mkdir -p "$HOME/.claude" "$HOME/.config/iterm2"

# iTerm2 ships the status helper inside the app; the hooks call it through a
# stable symlink in ~/.config/iterm2.
helper_src="/Applications/iTerm.app/Contents/Resources/utilities/cc-status"
helper="$HOME/.config/iterm2/cc-status"
if [[ -e "$helper_src" && ! -e "$helper" ]]; then
  ln -s "$helper_src" "$helper"
  echo "set: linked $helper" >&2
fi

HELPER="$helper" python3 - <<'PY'
import json, os, pathlib

path = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text()) if path.exists() else {}
changed = []

for key, value in (("theme", "dark"), ("tui", "fullscreen")):
    if key not in data:
        data[key] = value
        changed.append(key)

helper = os.environ["HELPER"]
if os.path.exists(helper):
    hooks = data.setdefault("hooks", {})
    events = ("Notification", "PermissionRequest", "PostToolUse", "PreToolUse",
              "SessionEnd", "SessionStart", "Stop", "StopFailure",
              "SubagentStop", "UserPromptSubmit")
    for event in events:
        if event not in hooks:
            hooks[event] = [{"hooks": [{"type": "command", "command": helper}]}]
            changed.append("hooks." + event)

if changed:
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("set: added " + ", ".join(changed))
else:
    print("ok:  Claude Code settings already contain the managed keys")
PY
