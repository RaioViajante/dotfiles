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
check "fresh: says the shell module is needed" grep -q 'apply the shell module' <<<"$out"
check "fresh: does not touch ~/.zshrc" absent "$h/.zshrc"
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
# With the shell module's hook present the script has nothing to say; it only
# ever reads ~/.zshrc.
hook='[[ -r "$HOME/.config/studio/studio.zsh" ]] && source "$HOME/.config/studio/studio.zsh"'
printf '%s\n' "$hook" >"$h/.zshrc"
out="$(run_setup "$h")"
check "icloud rerun: quiet when the hook is in place" test -z "$out"
check "icloud rerun: ~/.zshrc untouched" test "$(cat "$h/.zshrc")" = "$hook"

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

# 6b. Relative overrides are rejected: a relative link target would be broken.
h="$(newhome relative)"
mkdir -p "$tmp/relative/cwd/rel-raio"
check "relative: RAIOVIAJANDO_DIR rejected" bash -c 'cd "$1/cwd" && ! HOME="$2" RAIOVIAJANDO_DIR=rel-raio "$3"' _ "$tmp/relative" "$h" "$script"
check "relative: STUDIO_DIR rejected" bash -c 'cd "$1/cwd" && ! HOME="$2" STUDIO_DIR=rel-studio "$3"' _ "$tmp/relative" "$h" "$script"
check "relative: nothing created" absent "$h/Studio"
check "relative: no stray directory" absent "$tmp/relative/cwd/rel-studio"

# 6c. Blocked paths never abort the script: files where directories are
# expected are kept, each failure is a warning, and unrelated parts still work.
h="$(newhome blocked-root)"
echo keep >"$h/Studio"
mkdir -p "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
out="$(run_setup "$h")" || fail "blocked root: script aborted: $out"
check "blocked root: ~/Studio file kept" test "$(cat "$h/Studio")" = keep
check "blocked root: warns about the directories" grep -q 'cannot create' <<<"$out"
check "blocked root: warns that no link is possible" grep -q 'workspace is not a directory' <<<"$out"
check "blocked root: nothing else created" test "$(ls -A "$h")" = "Library
Studio"

h="$(newhome blocked-sub)"
mkdir -p "$h/Studio/templates"
echo vid >"$h/Studio/videos"
echo lib >"$h/Studio/library"
echo tpl >"$h/Studio/templates/video"
out="$(run_setup "$h")" || fail "blocked sub: script aborted: $out"
check "blocked sub: file at a directory path kept" test "$(cat "$h/Studio/videos")" = vid
check "blocked sub: file as a parent kept" test "$(cat "$h/Studio/library")" = lib
check "blocked sub: nested file as a parent kept" test "$(cat "$h/Studio/templates/video")" = tpl
check "blocked sub: warns for a file at the path" grep -q 'not a directory, left alone' <<<"$out"
check "blocked sub: warns for a blocked parent" grep -q 'cannot create' <<<"$out"
check "blocked sub: unrelated directory still created" test -d "$h/Studio/templates/obs"
check "blocked sub: README still created" test -f "$h/Studio/README.md"
before="$(listing "$h")"
run_setup "$h" >/dev/null || fail "blocked sub: rerun aborted"
check "blocked sub: rerun changes nothing" test "$before" = "$(listing "$h")"

h="$(newhome blocked-ro)"
mkdir -p "$h/Studio/library" "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
chmod 555 "$h/Studio/library"
out="$(run_setup "$h")" || fail "read-only parent: script aborted: $out"
check "read-only parent: warns" grep -q 'cannot create' <<<"$out"
check "read-only parent: directory not created" absent "$h/Studio/library/music"
check "read-only parent: unrelated directory created" test -d "$h/Studio/templates/video/export"
check "read-only parent: link still created" test -L "$h/Studio/raioviajando"
chmod 755 "$h/Studio/library"

h="$(newhome blocked-ro-root)"
mkdir -p "$h/Studio" "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando"
chmod 555 "$h/Studio"
out="$(run_setup "$h")" || fail "read-only workspace: script aborted: $out"
check "read-only workspace: README warning" grep -q 'cannot write' <<<"$out"
check "read-only workspace: link warning" grep -q 'cannot create the link' <<<"$out"
check "read-only workspace: nothing created" test -z "$(ls -A "$h/Studio")"
chmod 755 "$h/Studio"

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
back="$tmp/back\\tslash\\nnl/Raioviajando"
mkdir -p "$back/_Library/sfx"
printf 'id,library_path,x\nS1,f g.wav,y\n' >"$back/_Library/sfx/manifest.csv"
touch "$back/_Library/sfx/f g.wav"
out="$(HOME="$h" RAIOVIAJANDO_DIR="$back" zsh -f -c 'source "$1"; sfx f' _ "$zshfile" 2>&1)"
check "shell: sfx keeps literal backslashes in the folder" test "$out" = "$back/_Library/sfx/f g.wav"
check "shell: that printed path exists" test -f "$out"
check "shell: sfx without argument fails" zfails "$h" 'sfx'
check "shell: newvideo creates a dated project" test -d "$(zrun "$h" 'newvideo my-video && print -r -- $PWD' 2>&1)/export"
check "shell: newvideo refuses an existing project" zfails "$h" 'newvideo my-video'
check "shell: newvideo rejects a bad slug" zfails "$h" 'newvideo "Bad Slug"'

# 9. Integration with the shell module, in throwaway homes. The same chezmoi
# invocation that setup uses applies the targets. The iTerm2 default-profile
# step of the shell module is never run: it writes real preferences.
command -v chezmoi >/dev/null || { echo "chezmoi is required for the integration checks" >&2; exit 1; }
interactive() { HOME="$1" zsh -i -c "$2" 2>"$tmp/stderr"; }
lacks() { ! grep -q -- "$1" <<<"$2"; }
shortcuts='studio raio rlib ep sfx newvideo transcribe'

# 9a. The studio module alone applies the shortcuts file but not the hook, and
# says so instead of promising working shortcuts.
h="$(newhome integration)"
mkdir -p "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando/Episodes/EP001-First One"
mkdir -p "$h/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando/_Library/sfx"
out="$(HOME="$h" "$root/setup" --no-packages studio 2>&1)" || fail "integration: setup studio failed: $out"
check "integration: studio alone applies the shortcuts file" test -f "$h/.config/studio/studio.zsh"
check "integration: studio alone does not write ~/.zshrc" absent "$h/.zshrc"
check "integration: studio alone points to the shell module" grep -q 'shell studio' <<<"$out"
check "integration: studio alone makes no false promise" lacks 'Open a new terminal for the shortcuts' "$out"
check "integration: studio alone does not enable shortcuts" test "$(interactive "$h" 'whence -w ep')" = "ep: none"

# 9b. Once the shell module's files are applied, an interactive zsh loads them.
HOME="$h" chezmoi apply --source "$root" --parent-dirs "$h/.zshrc" "$h/.config/zsh" "$h/.config/studio" >/dev/null 2>&1 ||
  fail "integration: chezmoi apply failed"
res="$(interactive "$h" "for c in $shortcuts; do [[ \"\$(whence -w \$c)\" == \"\$c: function\" ]] || { print MISSING \$c; exit 1; }; done; print ALL-DEFINED")" || true
check "integration: every shortcut is a function in an interactive zsh" grep -q ALL-DEFINED <<<"$res"
res="$(interactive "$h" 'ep 1 && print -r -- "AT:${PWD:t}"')" || true
check "integration: ep works through the real ~/.zshrc" grep -qx 'AT:EP001-First One' <<<"$res"
res="$(interactive "$h" 'rlib sfx && print -r -- "AT:${PWD:t}"')" || true
check "integration: rlib works through the real ~/.zshrc" grep -qx 'AT:sfx' <<<"$res"
out="$(run_setup "$h")"
check "integration: no hook warning once the shell module is applied" lacks 'apply the shell module' "$out"

# 9c. The shell module without studio starts cleanly and defines no shortcut.
h="$(newhome integration-noshell)"
HOME="$h" chezmoi apply --source "$root" --parent-dirs "$h/.zshrc" "$h/.config/zsh" >/dev/null 2>&1 ||
  fail "integration: chezmoi apply without studio failed"
res="$(interactive "$h" 'print STARTED; whence -w ep')" || true
check "integration: shell without studio starts" grep -q STARTED <<<"$res"
check "integration: shell without studio defines no shortcut" grep -q 'ep: none' <<<"$res"
check "integration: shell without studio mentions nothing about studio" lacks studio "$(cat "$tmp/stderr")"

if (( status == 0 )); then
  echo "Studio check passed: $checks checks (setup script and shell shortcuts, paths with spaces)."
fi
exit "$status"
