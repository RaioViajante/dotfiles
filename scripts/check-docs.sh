#!/bin/bash
# Check README.md and docs/*.md against the repository:
#   - relative Markdown links point to existing files,
#   - every scripts/... path mentioned exists,
#   - every documented `./setup ARGS` invocation is accepted (run as a dry run
#     with a throwaway HOME, so nothing is installed or applied). The bare
#     `./setup` is checked in CI: it must print help and fail.
# Run from anywhere: scripts/check-docs.sh [repo]

set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root"
status=0
docs=(README.md docs/*.md)

for doc in "${docs[@]}"; do
  dir="$(dirname "$doc")"
  while IFS= read -r link; do
    target="${link%%#*}"
    [[ -z "$target" ]] && continue
    if [[ ! -e "$dir/$target" ]]; then
      echo "$doc: broken link: $link" >&2
      status=1
    fi
  done < <(grep -oE '\]\([^)]+\)' "$doc" | sed -E 's/^\]\((.*)\)$/\1/' | grep -vE '^(https?|mailto|macappstore):' || true)
done

while IFS= read -r path; do
  if [[ ! -e "$path" ]]; then
    echo "documented script does not exist: $path" >&2
    status=1
  fi
done < <(grep -ohE 'scripts/[A-Za-z0-9_./-]+\.sh' "${docs[@]}" | sort -u)

home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
count=0
while IFS= read -r invocation; do
  args="${invocation#./setup}"
  # shellcheck disable=SC2086 # documented arguments are plain words
  if ! HOME="$home" ./setup --dry-run $args >/dev/null 2>&1; then
    echo "documented command fails: $invocation" >&2
    status=1
  fi
  count=$((count + 1))
done < <(grep -ohE '\./setup +[-a-z][^`#]*' "${docs[@]}" | sed -E 's/[[:space:]]+$//' | sort -u)

if (( status == 0 )); then
  echo "Documentation check passed: ${#docs[@]} files, links and script paths valid, $count setup invocations accepted."
fi
exit "$status"
