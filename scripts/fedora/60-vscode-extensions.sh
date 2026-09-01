#!/bin/bash
# Install VS Code (official Microsoft RPM) and the curated extension set from
# manifests/vscode-extensions.txt. Only missing extensions are installed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root
require_fedora

manifest="$SCRIPT_DIR/../../manifests/vscode-extensions.txt"
[[ -r "$manifest" ]] || die "extension manifest not found: $manifest"

# --- VS Code (Stable, Microsoft RPM) ---------------------------------
if rpm -q code >/dev/null 2>&1; then
  ok "VS Code already installed ($(code --version | head -n1))"
else
  [[ -f /etc/yum.repos.d/vscode.repo ]] || die "VS Code repository missing; run 10-repositories.sh first"
  dnf_install_missing code
fi
has code || die "'code' is not on PATH after installation"

# --- Extensions -------------------------------------------------------
mapfile -t wanted < <(grep -vE '^[[:space:]]*(#|$)' "$manifest")
mapfile -t installed < <(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

declare -i failures=0
for ext in "${wanted[@]}"; do
  if printf '%s\n' "${installed[@]}" | grep -qxF "${ext,,}"; then
    ok "$ext"
    continue
  fi
  log "installing $ext"
  if ! code --install-extension "$ext" --force >/dev/null 2>&1; then
    warn "failed to install $ext"
    failures+=1
  fi
done

if (( failures > 0 )); then
  die "$failures extension(s) failed to install; re-run this script or check the ids"
fi
ok "VS Code extensions ready"
