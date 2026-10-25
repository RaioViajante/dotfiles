#!/bin/bash
# Install the current Descript desktop app with Descript's official macOS
# installer. The Homebrew cask can provide the retired 114.x-release build,
# which cannot load the current web application. Safe to rerun: a current
# non-legacy Descript installation is left untouched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"
refuse_root
has curl || die "curl is required"
has ditto || die "ditto is required"

app="/Applications/Descript.app"
plist="$app/Contents/Info.plist"
installer_url="https://web.descript.com/download?v2=true&platform=mac"

descript_version() {
  [[ -r "$plist" ]] || return 1
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null
}

version="$(descript_version || true)"
if [[ -n "$version" && "$version" != *release* ]]; then
  ok "Descript $version already installed; skipping"
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
archive="$tmp_dir/descript-installer.zip"

log "downloading the official Descript installer"
curl -fL "$installer_url" -o "$archive" || die "could not download Descript"
ditto -x -k "$archive" "$tmp_dir/unpacked"

installer="$(find "$tmp_dir/unpacked" -maxdepth 1 -name 'Descript Installer.app' -print -quit)"
[[ -n "$installer" ]] || die "the download did not contain Descript Installer.app"

log "opening the Descript installer; keep it open until the download finishes"
open "$installer" || die "macOS could not open the Descript installer"

# The installer runs as a GUI app and returns immediately. Wait until it has
# replaced a legacy build (or created a new installation) with the current app.
attempt=0
while (( attempt < 300 )); do
  version="$(descript_version || true)"
  if [[ -n "$version" && "$version" != *release* && -x "$app/Contents/MacOS/Descript" ]]; then
    ok "Descript $version installed"
    exit 0
  fi
  sleep 2
  attempt=$((attempt + 1))
done

die "Descript did not finish installing within 10 minutes; rerun this script"
