#!/bin/bash
# Reproduce the intentional startup behaviour of the workstation: two classic
# Login Items and the Homebrew MySQL background service.
#
# Deliberately NOT handled here: applications that manage their own startup
# (Proton Mail Bridge, AltTab, Docker Desktop -- which is set to not start at
# login), peripheral software (Logitech / Razer), and any security-sensitive
# system service. MANUAL step, never run by `chezmoi apply`. Idempotent, no sudo.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi

login_apps=(
  "/Applications/ProtonVPN.app"
  "/Applications/Notion.app"
)

existing="$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || true)"
for app in "${login_apps[@]}"; do
  name="$(basename "$app" .app)"
  if [[ ! -d "$app" ]]; then
    echo "skip: $app is not installed" >&2
  elif [[ ", $existing, " == *", $name, "* ]]; then
    echo "ok:  login item already present: $name" >&2
  else
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app\", hidden:false}" >/dev/null
    echo "set: added login item: $name" >&2
  fi
done

if command -v brew >/dev/null 2>&1 && brew list --formula mysql >/dev/null 2>&1; then
  if brew services list | awk '$1 == "mysql" { print $2 }' | grep -qx started; then
    echo "ok:  mysql service already started" >&2
  else
    brew services start mysql
  fi
else
  echo "skip: mysql formula not installed" >&2
fi
