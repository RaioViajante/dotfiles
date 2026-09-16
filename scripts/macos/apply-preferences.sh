#!/bin/bash
# Apply a small, conservative set of macOS desktop preferences for a developer
# machine: the global appearance (Dark mode + accent colour), the Dock contents
# and behaviour, and a few Finder view options. Every value here is cosmetic and
# reversible from System Settings.
#
# Like register-jdks.sh, this is a MANUAL post-bootstrap step. `chezmoi apply`
# never runs it, so a routine dotfiles update never rearranges the Dock.
#
# Idempotent and safe to re-run: every `defaults` value is checked first and
# only written when it differs, and the Dock app list is only rebuilt when it is
# not already in the desired order. Missing applications are skipped with a note
# instead of failing.
#
# This script deliberately does NOT touch: iCloud / Desktop / Documents sync,
# any network / DNS / firewall / proxy setting, security or privacy settings,
# the wallpaper, scroll direction, the keyboard, or the trackpad. It never calls
# sudo.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Do not run this script as root; it changes per-user preferences only." >&2
  exit 1
fi

appearance_changed=0
dock_changed=0
finder_changed=0

# Write a `defaults` value only when the current one differs. `defaults read`
# returns 1/0 for booleans, so <expected> is what a *read* returns (e.g. 1),
# while the trailing args are the *write* form (e.g. -bool true).
#   defaults_set <domain> <key> <expected> <changed-flag-var> <write-args...>
defaults_set() {
  local domain="$1" key="$2" expected="$3" flag="$4" current
  shift 4
  current="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  if [[ "$current" == "$expected" ]]; then
    echo "ok:  $domain $key = $expected" >&2
    return 0
  fi
  echo "set: $domain $key -> $expected (was: ${current:-unset})" >&2
  defaults write "$domain" "$key" "$@"
  printf -v "$flag" 1
}

# --- macOS appearance -------------------------------------------------------
# Dark mode and the Purple accent colour, matching the manual choice on this
# machine. AppleAccentColor: 0 red, 1 orange, 2 yellow, 3 green, 4 blue,
# 5 purple, 6 pink, -1 graphite (multicolour = the key is simply absent). The
# highlight colour is left to follow the accent. A full log out / in may be
# needed before every UI element picks up an accent change.
defaults_set NSGlobalDomain AppleInterfaceStyle Dark appearance_changed -string Dark
defaults_set NSGlobalDomain AppleAccentColor    5    appearance_changed -int    5

# --- Dock behaviour ----------------------------------------------------------
# Bottom, always visible (auto-hide OFF), no "recent applications" section, and
# windows minimise into the application icon.
#
# The icon size (tilesize) and magnification are intentionally NOT managed here:
# they are left exactly at the macOS defaults so the Dock keeps its normal
# proportions.
defaults_set com.apple.dock orientation             bottom dock_changed -string bottom
defaults_set com.apple.dock autohide                0      dock_changed -bool   false
defaults_set com.apple.dock show-recents            0      dock_changed -bool   false
defaults_set com.apple.dock minimize-to-application 1      dock_changed -bool   true

# --- Dock contents ---------------------------------------------------------
# Desired left-to-right order of pinned applications. Finder (always first) and
# Trash / the Downloads stack (always last, in the "others" section) are left
# exactly as macOS manages them and are never removed.
dock_apps=(
  "/Applications/Zen.app"
  "/Applications/Microsoft Outlook.app"
  "/Applications/Notion.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/IntelliJ IDEA.app"
  "/Applications/iTerm.app"
  "/Applications/Discord.app"
  "/Applications/Spotify.app"
  "/Applications/Proton Mail.app"
  "/Applications/Proton Pass.app"
  "/Applications/Proton Authenticator.app"
  "/Applications/Proton Drive.app"
  "/Applications/ProtonVPN.app"
  "/Applications/Tor Browser.app"
  "/Applications/ExcalidrawZ.app"
)

# Most apps use the standard Contents/Info.plist layout. "Designed for iPad"
# / Mac Catalyst apps installed from the Mac App Store (e.g. Proton
# Authenticator) instead ship an outer wrapper whose real Info.plist lives at
# Wrapper/<Name>.app/Info.plist, with no top-level Contents directory.
bundle_id() {
  local app="$1"
  local plist="$app/Contents/Info.plist"
  [[ -f "$plist" ]] || plist="$(find "$app/Wrapper" -mindepth 2 -maxdepth 2 -name Info.plist 2>/dev/null | head -n1)"
  [[ -n "$plist" ]] || return 0
  plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || true
}

if ! command -v dockutil >/dev/null 2>&1; then
  echo "skip: dockutil is not installed (brew install dockutil); Dock contents unchanged" >&2
else
  # Keep only the applications that are actually installed.
  desired_ids=()
  desired_paths=()
  for app in "${dock_apps[@]}"; do
    if [[ ! -d "$app" ]]; then
      echo "skip: not installed, leaving out of the Dock: $app" >&2
      continue
    fi
    bid="$(bundle_id "$app")"
    [[ -n "$bid" ]] || { echo "skip: no bundle id for $app" >&2; continue; }
    desired_ids+=("$bid")
    desired_paths+=("$app")
  done

  # Current pinned-app bundle ids, in Dock order.
  current_ids="$(dockutil --list 2>/dev/null \
    | awk -F'\t' '$3 == "persistentApps" { print $5 }')"
  desired_ids_joined="$(printf '%s\n' "${desired_ids[@]}")"

  if [[ "$current_ids" == "$desired_ids_joined" ]]; then
    echo "ok:  Dock app list already in the desired order" >&2
  else
    echo "set: rebuilding the Dock app list" >&2
    # Remove every currently pinned app (leaves the Downloads stack alone).
    while IFS= read -r id; do
      [[ -n "$id" ]] || continue
      dockutil --remove "$id" --no-restart >/dev/null 2>&1 || true
    done <<< "$current_ids"
    # Add the desired apps in order; each one appends to the apps section.
    for app in "${desired_paths[@]}"; do
      dockutil --add "$app" --no-restart >/dev/null
    done
    dock_changed=1
  fi
fi

# --- Finder view options -------------------------------------------------
# Developer-friendly and non-destructive: always show filename extensions, show
# the Path Bar and the Status Bar, and keep the sidebar visible. Hidden files
# stay hidden by default. Only the sidebar's visibility is managed here
# (ShowSidebar, the stable toggle behind View > Show Sidebar / Cmd-Opt-S); its
# favourites, item order and iCloud locations are Finder-managed and untouched.
# iCloud Desktop/Documents sync is not touched.
defaults_set NSGlobalDomain    AppleShowAllExtensions 1 finder_changed -bool true
defaults_set com.apple.finder  ShowPathbar            1 finder_changed -bool true
defaults_set com.apple.finder  ShowStatusBar          1 finder_changed -bool true
defaults_set com.apple.finder  ShowSidebar            1 finder_changed -bool true
defaults_set com.apple.finder  AppleShowAllFiles      0 finder_changed -bool false

# --- Restart affected apps only if something changed --------------------
if [[ "$appearance_changed" -eq 1 ]]; then
  echo "Appearance updated. Log out and back in for the accent colour to apply everywhere." >&2
fi
if [[ "$dock_changed" -eq 1 ]]; then
  killall Dock 2>/dev/null || true
  echo "Dock updated." >&2
fi
if [[ "$finder_changed" -eq 1 ]]; then
  killall Finder 2>/dev/null || true
  echo "Finder updated. Log out and back in if a setting is not visible yet." >&2
fi
if [[ "$appearance_changed" -eq 0 && "$dock_changed" -eq 0 && "$finder_changed" -eq 0 ]]; then
  echo "Nothing to do: all preferences already applied." >&2
fi
