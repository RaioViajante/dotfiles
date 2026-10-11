#!/bin/bash
# Check that the module definitions stay consistent with the repository:
#   - every file chezmoi manages belongs to exactly one configuration module,
#   - every module target matches at least one managed file,
#   - every package appears in exactly one bundle under brew/.
# Run from anywhere: scripts/check-modules.sh [repo]

set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
status=0

targets="$("$root/setup" --print-targets)"
managed="$(chezmoi managed --source "$root" --include files --path-style relative)"

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  owners="$(printf '%s\n' "$targets" | while IFS=$'\t' read -r module target; do
    if [[ "$file" == "$target" || "$file" == "$target/"* ]]; then
      echo "$module"
    fi
  done)"
  count="$(printf '%s' "$owners" | grep -c . || true)"
  if [[ "$count" -ne 1 ]]; then
    echo "managed file ~/$file belongs to ${count} modules: ${owners//$'\n'/ }" >&2
    status=1
  fi
done <<<"$managed"

while IFS=$'\t' read -r module target; do
  if ! printf '%s\n' "$managed" | grep -qxF -e "$target" && ! printf '%s\n' "$managed" | grep -qF -e "$target/"; then
    echo "module $module lists ~/$target, which chezmoi does not manage" >&2
    status=1
  fi
done <<<"$targets"

dupes="$(cat "$root"/brew/*.Brewfile "$root"/brew/shared/*.Brewfile |
  grep -E '^[[:space:]]*(brew|cask|mas|tap|vscode)[[:space:]]' |
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*(#.*)?$//' | sort | uniq -d)"
if [[ -n "$dupes" ]]; then
  echo "packages listed in more than one bundle:" >&2
  echo "$dupes" >&2
  status=1
fi

if (( status == 0 )); then
  echo "Module check passed: $(printf '%s\n' "$managed" | grep -c .) managed files, each in one module; no duplicate packages."
fi
exit "$status"
