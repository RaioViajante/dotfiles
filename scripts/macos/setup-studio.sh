#!/bin/bash
# Prepare the local studio workspace. Safe to rerun and non-destructive:
#   - creates only the missing directories of ~/Studio (existing ones, with
#     their contents, are never touched),
#   - writes ~/Studio/README.md only when it does not exist,
#   - links ~/Studio/raioviajando to the Raioviajando folder in iCloud Drive
#     only when that folder exists and nothing occupies the link path.
# It never creates or changes anything inside iCloud Drive. Missing iCloud Drive
# is a warning, not an error. STUDIO_DIR and RAIOVIAJANDO_DIR (absolute paths)
# override the default locations.

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
  if [[ -d "$studio_dir/$dir" ]]; then
    continue
  elif [[ -e "$studio_dir/$dir" || -L "$studio_dir/$dir" ]]; then
    warn "not a directory, left alone: $studio_dir/$dir"
  else
    mkdir -p "$studio_dir/$dir"
    ok "created $studio_dir/$dir"
  fi
done

readme="$studio_dir/README.md"
if [[ ! -e "$readme" && ! -L "$readme" && -d "$studio_dir" ]]; then
  cat >"$readme" <<'EOF'
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
fi

link="$studio_dir/raioviajando"
if [[ ! -d "$raio_dir" ]]; then
  warn "Raioviajando folder not found, no link created: $raio_dir"
  warn "rerun this script once iCloud Drive has synced it"
elif [[ -L "$link" && "$(readlink "$link")" == "$raio_dir" ]]; then
  :
elif [[ -e "$link" || -L "$link" ]]; then
  warn "left alone, something else is at: $link"
else
  ln -s "$raio_dir" "$link"
  ok "linked $link"
fi
