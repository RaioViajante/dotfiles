#!/bin/bash
# Install the curated Fedora package set from manifests/fedora-packages.txt.
# Only missing packages are installed, so re-running is cheap and safe.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root
require_fedora

manifest="$SCRIPT_DIR/../../manifests/fedora-packages.txt"
[[ -r "$manifest" ]] || die "package manifest not found: $manifest"

mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$manifest")
[[ ${#packages[@]} -gt 0 ]] || die "package manifest is empty"

log "curated packages: ${#packages[@]} entries"
dnf_install_missing "${packages[@]}"

# The default shell change is a user decision, not a silent one.
if [[ "${SHELL:-}" != *"/zsh" ]]; then
  warn "default shell is '${SHELL:-unknown}'. To use zsh: chsh -s \"\$(command -v zsh)\""
fi

ok "packages ready"
