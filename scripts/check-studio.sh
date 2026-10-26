#!/bin/bash
# Behavior checks for the studio module, run in throwaway HOME directories whose
# names contain spaces; nothing outside them is read or written:
#   - scripts/macos/setup-studio.sh is non-destructive and idempotent, works
#     without iCloud Drive and never creates a broken link,
#   - the shell shortcuts in dot_config/studio/studio.zsh load without iCloud
#     Drive and behave with and without it.
# Run from anywhere: scripts/check-studio.sh [repo]

# SC2016: the single-quoted snippets are zsh code, expanded by the inner zsh.
# SC2329: the helpers are invoked indirectly through check.
# shellcheck disable=SC2016,SC2329
set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
script="$root/scripts/macos/setup-studio.sh"
zshfile="$root/dot_config/studio/studio.zsh"
status=0
checks=0

unset STUDIO_DIR RAIOVIAJANDO_DIR WHISPER_MODEL_DIR WHISPER_MODEL WHISPER_LANG
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; status=1; }
check() { # check "description" command...
  local what="$1"
  shift
  checks=$((checks + 1))
  "$@" >/dev/null 2>&1 || fail "$what"
}
absent() { [[ ! -e "$1" && ! -L "$1" ]]; }
listing() { (cd "$1" && find . | LC_ALL=C sort); }
newhome() { mkdir -p "$tmp/$1/home with space" && echo "$tmp/$1/home with space"; }
run_setup() { HOME="$1" "$script" 2>&1; }

# 1. Fresh machine, no iCloud Drive: layout created, no link, success.
h="$(newhome fresh)"
out="$(run_setup "$h")" || fail "fresh run failed: $out"
check "fresh: video template export dir" test -d "$h/Studio/templates/video/export"
check "fresh: library sounds dir" test -d "$h/Studio/library/sounds"
check "fresh: README created" test -f "$h/Studio/README.md"
check "fresh: no link without iCloud" absent "$h/Studio/raioviajando"
check "fresh: warns about missing folder" grep -q 'Raioviajando folder not found' <<<"$out"
check "fresh: nothing created outside Studio" test "$(ls -A "$h")" = "Studio"

# 2. Idempotent: a second run changes nothing.
before="$(listing "$h")"
run_setup "$h" >/dev/null || fail "rerun failed"
check "rerun: identical tree" test "$before" = "$(listing "$h")"

# 3. iCloud appears later: link is created, resolves, iCloud is untouched.
icloud="$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
mkdir -p "$icloud/_Library/sfx" "$icloud/Episodes/EP001-First One" "$icloud/Episodes/EP002-Second"
icloud_before="$(listing "$icloud")"
out="$(run_setup "$h")" || fail "run with iCloud failed: $out"
check "icloud: link created" test -L "$h/Studio/raioviajando"
check "icloud: link resolves" test -d "$h/Studio/raioviajando/_Library"
check "icloud: link target exact" test "$(readlink "$h/Studio/raioviajando")" = "$icloud"
check "icloud: tree untouched" test "$icloud_before" = "$(listing "$icloud")"
out="$(run_setup "$h")"
check "icloud rerun: quiet" test -z "$out"

# 4. Existing user files and directories are preserved.
h="$(newhome existing)"
mkdir -p "$h/Studio/videos/2026-01-keep" "$h/Studio/raioviajando" "$h/Studio/library"
echo mine >"$h/Studio/README.md"
echo keep >"$h/Studio/videos/2026-01-keep/note.txt"
echo file >"$h/Studio/library/music"
mkdir -p "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
out="$(run_setup "$h")" || fail "existing run failed: $out"
check "existing: README kept" test "$(cat "$h/Studio/README.md")" = mine
check "existing: project kept" test "$(cat "$h/Studio/videos/2026-01-keep/note.txt")" = keep
check "existing: directory at link path kept" test -d "$h/Studio/raioviajando" -a ! -L "$h/Studio/raioviajando"
check "existing: file at a directory path kept" test "$(cat "$h/Studio/library/music")" = file
check "existing: warns" grep -q 'left alone' <<<"$out"

# 5. A dangling link already at the link path is left alone, never replaced.
h="$(newhome dangling)"
mkdir -p "$h/Studio" "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
ln -s "$h/gone" "$h/Studio/raioviajando"
run_setup "$h" >/dev/null || fail "dangling run failed"
check "dangling: link not replaced" test "$(readlink "$h/Studio/raioviajando")" = "$h/gone"

# 6. STUDIO_DIR and RAIOVIAJANDO_DIR overrides are honored.
h="$(newhome override)"
mkdir -p "$tmp/custom raio"
HOME="$h" STUDIO_DIR="$tmp/custom studio" RAIOVIAJANDO_DIR="$tmp/custom raio" "$script" >/dev/null 2>&1 ||
  fail "override run failed"
check "override: layout in custom dir" test -d "$tmp/custom studio/videos"
check "override: link to custom folder" test "$(readlink "$tmp/custom studio/raioviajando")" = "$tmp/custom raio"
check "override: default dir untouched" absent "$h/Studio"

# 7. Shell shortcuts without iCloud Drive: load silently, fail with a message.
zrun() { HOME="$1" zsh -f -c 'source "$1"; eval "$2"' _ "$zshfile" "$2"; }
zfails() { ! zrun "$@"; }
h="$(newhome shell-none)"
out="$(zrun "$h" ':' 2>&1)"
check "shell: sourcing prints nothing" test -z "$out"
check "shell: raio fails without iCloud" zfails "$h" 'raio'
out="$(zrun "$h" 'ep 1' 2>&1 || true)"
check "shell: ep explains the missing folder" grep -q 'Episodes folder not found' <<<"$out"
out="$(zrun "$h" 'transcribe x.wav' 2>&1 || true)"
check "shell: transcribe fails cleanly" grep -qE 'needs whisper-cli|file not found|model not found' <<<"$out"

# 8. Shell shortcuts with iCloud Drive and a workspace (paths with spaces).
h="$(newhome shell)"
raio="$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
mkdir -p "$raio/_Library/sfx" "$raio/Episodes/EP001-First One" "$raio/Episodes/EP002-Second" "$raio/Episodes/EP010-Tenth"
printf 'id,library_path,original_filename,category\nSFX-001,bells/Pleasing Bell.wav,x.wav,bells\nSFX-002,pops/pop.wav,y.wav,pops\n' >"$raio/_Library/sfx/manifest.csv"
run_setup "$h" >/dev/null || fail "shell workspace setup failed"
check "shell: ep 1 enters EP001" test "$(zrun "$h" 'ep 1 && print -r -- ${PWD:t}' 2>&1)" = "EP001-First One"
check "shell: ep 002 enters EP002" test "$(zrun "$h" 'ep 002 && print -r -- ${PWD:t}' 2>&1)" = "EP002-Second"
check "shell: ep with no match fails" zfails "$h" 'ep 7'
check "shell: ep with no argument lists episodes dir" test "$(zrun "$h" 'ep && print -r -- ${PWD:t}' 2>&1)" = "Episodes"
check "shell: raio" test "$(zrun "$h" 'raio && print -r -- ${PWD:t}' 2>&1)" = "Raioviajando"
check "shell: rlib sfx" test "$(zrun "$h" 'rlib sfx && print -r -- ${PWD:t}' 2>&1)" = "sfx"
check "shell: studio" test "$(zrun "$h" 'studio videos && print -r -- ${PWD:t}' 2>&1)" = "videos"
out="$(zrun "$h" 'sfx "pleasing bell"' 2>&1)"
check "shell: sfx finds a row with spaces" test "$out" = "$raio/_Library/sfx/bells/Pleasing Bell.wav"
check "shell: sfx without argument fails" zfails "$h" 'sfx'
check "shell: newvideo creates a dated project" test -d "$(zrun "$h" 'newvideo my-video && print -r -- $PWD' 2>&1)/export"
check "shell: newvideo refuses an existing project" zfails "$h" 'newvideo my-video'
check "shell: newvideo rejects a bad slug" zfails "$h" 'newvideo "Bad Slug"'

if (( status == 0 )); then
  echo "Studio check passed: $checks checks (setup script and shell shortcuts, paths with spaces)."
fi
exit "$status"
