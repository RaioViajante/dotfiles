#!/bin/bash
# Install the Mac App Store apps listed in manifests/mas-apps.txt.
#
# MANUAL step: the App Store must already be signed in with your own Apple ID
# (interactive; no credentials are ever stored here). Uses `mas install`, which
# only downloads apps already in your purchase history -- it never purchases.
# Idempotent: apps that are already installed are skipped.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi
if ! command -v mas >/dev/null 2>&1; then
  echo "mas is not installed (Brewfile: brew \"mas\"). Run brew bundle first." >&2
  exit 1
fi

manifest="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/manifests/mas-apps.txt"
installed="$(mas list | awk '{ print $1 }')"

while read -r id name; do
  [[ -z "${id:-}" || "$id" == \#* ]] && continue
  if grep -qx "$id" <<<"$installed"; then
    echo "ok:  $name already installed" >&2
  else
    echo "set: installing $name ($id)" >&2
    mas install "$id" || echo "warn: could not install $name; sign in to the App Store and retry" >&2
  fi
done < "$manifest"
