# Content-creation shortcuts (studio module). Sourced by ~/.zshrc when present.
# Everything here is a variable or a function: nothing is created, linked or
# checked until a command runs, so a missing iCloud Drive never breaks startup.

: "${STUDIO_DIR:=$HOME/Studio}"
: "${RAIOVIAJANDO_DIR:=$HOME/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando}"
: "${WHISPER_MODEL_DIR:=$HOME/.local/share/whisper-cpp/models}"
export STUDIO_DIR RAIOVIAJANDO_DIR WHISPER_MODEL_DIR

_studio_need_dir() {
  [[ -d "$2" ]] && return 0
  print -u2 "$1 not found: $2"
  [[ "$2" == "$RAIOVIAJANDO_DIR"* ]] && print -u2 'Is iCloud Drive signed in and the folder downloaded?'
  return 1
}

# studio [subdir]: go to the local workspace.
studio() {
  _studio_need_dir 'studio workspace' "$STUDIO_DIR/${1:-}" && cd -- "$STUDIO_DIR/${1:-}"
}

# raio: go to the Raioviajando folder in iCloud Drive.
raio() {
  _studio_need_dir 'Raioviajando folder' "$RAIOVIAJANDO_DIR" && cd -- "$RAIOVIAJANDO_DIR"
}

# rlib [subdir]: go to the shared library (sfx, music, graphics, templates).
rlib() {
  local dir="$RAIOVIAJANDO_DIR/_Library/${1:-}"
  _studio_need_dir 'shared library' "$dir" && cd -- "$dir"
}

# ep [number|prefix]: go to the episodes folder, or to one episode (ep 1, ep 001).
ep() {
  local episodes="$RAIOVIAJANDO_DIR/Episodes" key
  _studio_need_dir 'Episodes folder' "$episodes" || return 1
  if (( $# == 0 )); then
    cd -- "$episodes"
    return
  fi
  key="$1"
  [[ "$key" == <-> ]] && key="EP${(l:3::0:)key}"
  local -a found
  found=("$episodes"/"$key"*(N/))
  case ${#found} in
    0) print -u2 "no episode matches: $1"; return 1 ;;
    1) cd -- "${found[1]}" ;;
    *) print -u2 "several episodes match $1:"; print -u2 -l -- "${found[@]:t}"; return 1 ;;
  esac
}

# sfx <term>: print paths of sound effects whose manifest row matches the term.
sfx() {
  local dir="$RAIOVIAJANDO_DIR/_Library/sfx"
  (( $# > 0 )) || { print -u2 'usage: sfx <term>'; return 2; }
  [[ -r "$dir/manifest.csv" ]] || { print -u2 "sound-effects manifest not found: $dir/manifest.csv"; return 1; }
  # The directory goes through the environment: awk -v would interpret
  # backslash sequences in it.
  grep -iF -- "$*" "$dir/manifest.csv" | grep -v '^id,' |
    SFX_DIR="$dir" awk -F, '{ print ENVIRON["SFX_DIR"] "/" $2 }'
}

# newvideo <slug>: copy the video template to a new dated project and enter it.
newvideo() {
  if (( $# != 1 )) || [[ ! "$1" =~ '^[a-z0-9][a-z0-9-]*$' ]]; then
    print -u2 'usage: newvideo <slug> (lowercase letters, digits and hyphens)'
    return 2
  fi
  local template="$STUDIO_DIR/templates/video" target="$STUDIO_DIR/videos/$(date +%Y-%m)-$1"
  _studio_need_dir 'video template' "$template" || return 1
  [[ -e "$target" ]] && { print -u2 "already exists: $target"; return 1; }
  mkdir -p -- "$STUDIO_DIR/videos" && cp -R -- "$template" "$target" && cd -- "$target"
}

# transcribe <audio-or-video> [model]: print a transcript with whisper.cpp.
# The model defaults to $WHISPER_MODEL, else ggml-medium.bin in
# $WHISPER_MODEL_DIR. WHISPER_LANG sets the language (default: auto-detect).
# Models are never downloaded; see docs/content-creation.md.
transcribe() {
  (( $# >= 1 && $# <= 2 )) || { print -u2 'usage: transcribe <file> [model]'; return 2; }
  local input="$1" model="${2:-${WHISPER_MODEL:-$WHISPER_MODEL_DIR/ggml-medium.bin}}"
  (( $+commands[whisper-cli] && $+commands[ffmpeg] )) ||
    { print -u2 'needs whisper-cli and ffmpeg: ./setup content'; return 1; }
  [[ -r "$input" ]] || { print -u2 "file not found: $input"; return 1; }
  [[ -r "$model" ]] || { print -u2 "Whisper model not found: $model"; return 1; }
  local tmp rc
  tmp="$(mktemp -d)" || return 1
  ffmpeg -loglevel error -y -i "$input" -ar 16000 -ac 1 -c:a pcm_s16le "$tmp/audio.wav" &&
    whisper-cli -m "$model" -f "$tmp/audio.wav" -l "${WHISPER_LANG:-auto}" -nt
  rc=$?
  rm -rf -- "$tmp"
  return $rc
}
