#!/bin/bash
# Install the Mac App Store apps listed in manifests/mas-apps.txt.
#
# MANUAL step: the App Store must already be signed in with your own Apple ID
# (interactive; no credentials are ever stored here). Uses `mas install`, which
# only downloads apps already in your purchase history -- it never purchases.
# `mas install` asks for an administrator password in the terminal. After Xcode
# installs, accept its license (`sudo xcodebuild -license accept`) or git and
# clang stop working (docs/development.md).
# Idempotent: apps that are already installed are skipped.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script supports macOS only." >&2
  exit 1
fi
# Homebrew's bin may not be on PATH when the managed shell is not in use.
if ! command -v mas >/dev/null 2>&1 && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
fi
if ! command -v mas >/dev/null 2>&1; then
  echo "mas is not installed; run 'setup dev' (brew/dev.Brewfile) first." >&2
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
    mas install "$id" || echo "warn: could not install $name; check the App Store sign-in and the administrator password, then retry" >&2
  fi
done < "$manifest"
