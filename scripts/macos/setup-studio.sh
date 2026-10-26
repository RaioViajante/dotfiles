#!/bin/bash
# Prepare the local studio workspace. Safe to rerun and non-destructive:
#   - creates only the missing directories of ~/Studio (existing ones, with
#     their contents, are never touched),
#   - writes ~/Studio/README.md only when it does not exist,
#   - links ~/Studio/raioviajando to the Raioviajando folder in iCloud Drive
#     only when that folder exists and nothing occupies the link path.
# Anything that cannot be done (a file where a directory is expected, a
# read-only parent, a missing iCloud folder) is a warning, never an error, and
# never stops the remaining steps. The script only reads ~/.zshrc, to warn when
# it does not load the shortcuts; the shell module owns that file. It never
# creates or changes anything inside iCloud Drive. STUDIO_DIR and
# RAIOVIAJANDO_DIR (absolute paths) override the default locations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

refuse_root

studio_dir="${STUDIO_DIR:-$HOME/Studio}"
raio_dir="${RAIOVIAJANDO_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando}"

# A relative link target would resolve against the link's own directory and
# break, so overrides must be absolute.
[[ "$studio_dir" == /* && "$raio_dir" == /* ]] ||
  die "STUDIO_DIR and RAIOVIAJANDO_DIR must be absolute paths"

dirs=(
  videos
  library/music library/overlays library/logos library/sounds library/fonts
  templates/obs
  templates/video/raw templates/video/assets templates/video/edit templates/video/export
)

for dir in "${dirs[@]}"; do
  target="$studio_dir/$dir"
  if [[ -d "$target" ]]; then
    continue
  elif [[ -e "$target" || -L "$target" ]]; then
    warn "not a directory, left alone: $target"
  elif mkdir -p "$target" 2>/dev/null; then
    ok "created $target"
  else
    warn "cannot create $target (a parent is not a directory, or not writable)"
  fi
done

readme="$studio_dir/README.md"
if [[ -d "$studio_dir" && ! -e "$readme" && ! -L "$readme" ]]; then
  if cat 2>/dev/null >"$readme" <<'EOF'; then
# Studio

Local content-creation workspace, one folder per video.

- `videos/`: one project per video, named `YYYY-MM-slug` (`newvideo <slug>`).
- `library/`: local material reused across videos (music, overlays, logos,
  sounds, fonts).
- `templates/`: `video/` is copied for each new project; `obs/` holds exported
  OBS scenes and profiles.
- `raioviajando`: link to the Raioviajando folder in iCloud Drive (episodes and
  the shared `_Library`), present when that folder exists.
EOF
    ok "created $readme"
  else
    warn "cannot write $readme"
  fi
fi

link="$studio_dir/raioviajando"
if [[ ! -d "$raio_dir" ]]; then
  warn "Raioviajando folder not found, no link created: $raio_dir"
  warn "rerun this script once iCloud Drive has synced it"
elif [[ ! -d "$studio_dir" ]]; then
  warn "no link created, the workspace is not a directory: $studio_dir"
elif [[ -L "$link" && "$(readlink "$link")" == "$raio_dir" ]]; then
  :
elif [[ -e "$link" || -L "$link" ]]; then
  warn "left alone, something else is at: $link"
elif ln -s "$raio_dir" "$link" 2>/dev/null; then
  ok "linked $link"
else
  warn "cannot create the link $link"
fi

# The shortcuts are loaded by ~/.zshrc, which belongs to the shell module. Say
# so instead of promising them; ~/.zshrc itself is never touched here.
if ! grep -qs '\.config/studio/studio\.zsh' "$HOME/.zshrc"; then
  warn "$HOME/.zshrc does not load the studio shortcuts yet; apply the shell module too:"
  warn "  ./setup --no-packages shell studio   (or ./setup --profile content-creation)"
fi
