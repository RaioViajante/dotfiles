#!/bin/bash
# Make the managed iTerm2 Dynamic Profile (JetBrainsMono Nerd Font) the default
# profile. Only the "Default Bookmark Guid" preference is written; other
# profiles and preferences are left alone. Skipped when iTerm2 loads its
# preferences from a custom folder, which `defaults` cannot change.
#
# Run by `setup shell`; safe to run by hand and to rerun. ITERM_PREFS selects
# another preferences domain or plist file (used by tests).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"
refuse_root

domain="${ITERM_PREFS:-com.googlecode.iterm2}"
profile="$HOME/Library/Application Support/iTerm2/DynamicProfiles/raioviajante.json"

[[ -r "$profile" ]] || die "managed profile not found: $profile (apply it with 'setup shell')"
guid="$(plutil -extract Profiles.0.Guid raw -o - "$profile")" || die "no Guid in $profile"

if [[ "$(defaults read "$domain" LoadPrefsFromCustomFolder 2>/dev/null || true)" == 1 ]]; then
  warn "iTerm2 loads its settings from a custom folder; set the default profile in iTerm2 > Settings > Profiles"
  exit 0
fi

current="$(defaults read "$domain" "Default Bookmark Guid" 2>/dev/null || true)"
if [[ "$current" == "$guid" ]]; then
  ok "iTerm2 default profile already set ($guid)"
  exit 0
fi

defaults write "$domain" "Default Bookmark Guid" -string "$guid"
ok "iTerm2 default profile set to the managed profile ($guid; was: ${current:-unset})"
if pgrep -xq iTerm2; then
  log "restart iTerm2 for new windows to use it"
fi
