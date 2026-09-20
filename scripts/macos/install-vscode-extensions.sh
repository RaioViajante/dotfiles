#!/bin/bash
# Install the curated VS Code extensions from manifests/vscode-extensions.txt.
# Only missing extensions are installed. Run by chezmoi
# (run_onchange_after_25-vscode-extensions.sh.tmpl) whenever the manifest changes,
# and safe to run by hand. Written for the bash 3.2 that ships with macOS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

[[ "$(uname -s)" == Darwin ]] || die "this script targets macOS"

manifest="$SCRIPT_DIR/../../manifests/vscode-extensions.txt"
[[ -r "$manifest" ]] || die "extension manifest not found: $manifest"

# A chezmoi run script does not inherit the interactive PATH, so fall back to
# the CLI shipped inside the application bundle.
bundle_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if ! has code && [[ -x "$bundle_bin/code" ]]; then
  PATH="$bundle_bin:$PATH"
fi
if ! has code; then
  warn "VS Code is not installed yet (Brewfile cask visual-studio-code); skipping extensions"
  exit 0
fi

installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

failures=0
while IFS= read -r ext; do
  [[ -n "$ext" ]] || continue
  if printf '%s\n' "$installed" | grep -qxF "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"; then
    ok "$ext"
    continue
  fi
  log "installing $ext"
  if ! code --install-extension "$ext" --force >/dev/null 2>&1; then
    warn "failed to install $ext"
    failures=$((failures + 1))
  fi
done < <(grep -vE '^[[:space:]]*(#|$)' "$manifest")

if (( failures > 0 )); then
  die "$failures extension(s) failed to install; re-run this script or check the ids"
fi
ok "VS Code extensions ready"
