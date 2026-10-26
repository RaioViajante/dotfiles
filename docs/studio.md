# Studio

The `studio` module is a configuration module for content creation. It installs
no software (the tools come from the [`content` module](content-creation.md));
it adds shell shortcuts, a local workspace and a link to the Raioviajando
folder in iCloud Drive.

## What it does

| Part | Where | Behavior |
| --- | --- | --- |
| Shell shortcuts | `~/.config/studio/studio.zsh` | managed by chezmoi; loaded by the hook the `shell` module puts in `~/.zshrc` (see [Install](#install)) |
| Local workspace | `~/Studio` | missing directories are created; existing ones are never touched |
| iCloud link | `~/Studio/raioviajando` | symlink to the Raioviajando folder, created only when that folder exists |

`scripts/macos/setup-studio.sh` creates the workspace and the link. It is safe
to rerun, never writes inside iCloud Drive and never replaces anything: an
existing file, directory or link at any of its paths is left alone with a
warning. If iCloud Drive or the Raioviajando folder is missing, it warns and
skips the link instead of creating a broken one; rerun it after the folder has
synced. Nothing assumes a user name: every path starts from `$HOME`.

## Install

```sh
cd ~/.local/share/chezmoi
./setup --no-packages shell studio    # shortcuts and workspace, shortcuts active
./setup --profile content-creation    # shell, git, content and studio together
```

The shortcuts are loaded by `~/.zshrc`, and `~/.zshrc` belongs to the `shell`
module, not to `studio`. A hook there sources `~/.config/studio/studio.zsh`
when that file exists. So `./setup studio` on its own applies the shortcuts file
and prepares the workspace, but nothing loads the file until the `shell` module
has applied the current `~/.zshrc`: on a fresh machine, or on one set up before
this module existed, the shortcuts stay unavailable. `studio` never edits
`~/.zshrc`; `setup-studio.sh` only reads it and warns when the hook is missing.
Without the `shell` module, source the file yourself from your own startup file.

`studio` has no software, so `--no-packages` makes no difference to it. With
`--packages-only`, a selection that contains only `studio` has nothing to do and
fails, like `git`. The tools themselves come from `./setup content`. After the
`shell` module is applied, open a new terminal to load the shortcuts.

## Workspace layout

```
~/Studio/
├── videos/              one project per video (YYYY-MM-slug)
├── library/             local material reused across videos
│   └── music, overlays, logos, sounds, fonts
├── templates/
│   ├── video/           raw, assets, edit, export; copied by newvideo
│   └── obs/             exported OBS scenes and profiles
└── raioviajando         link to the iCloud Drive folder
```

The iCloud folder holds the episodes and the shared library:

```
Raioviajando/
├── Episodes/            one folder per episode, never touched by these tools
└── _Library/            sfx, music, graphics, templates (shared, verified copies)
```

The dotfiles never create, move or modify anything inside it. Media, licensed
music and Whisper models stay out of Git (see
[Keep outside version control](#keep-outside-version-control)).

## Shortcuts

| Command | What it does |
| --- | --- |
| `studio [subdir]` | go to `~/Studio` or one of its folders |
| `raio` | go to the Raioviajando folder in iCloud Drive |
| `rlib [subdir]` | go to the shared library, for example `rlib sfx` |
| `ep [number]` | go to the episodes folder, or to one episode: `ep 1` and `ep 001` both enter `EP001-*` |
| `sfx <term>` | print the paths of sound effects whose manifest row matches the term |
| `newvideo <slug>` | copy `templates/video` to `videos/YYYY-MM-slug` and go there; refuses an existing project |
| `transcribe <file> [model]` | print a transcript with whisper.cpp (needs FFmpeg and a model) |

Every command checks its directory first. With iCloud Drive unavailable, the
shell still starts normally and a command prints what is missing, for example
`Episodes folder not found: ...`, and returns an error.

### Settings

| Variable | Default | Purpose |
| --- | --- | --- |
| `STUDIO_DIR` | `~/Studio` | local workspace |
| `RAIOVIAJANDO_DIR` | `~/Library/Mobile Documents/com~apple~CloudDocs/Raioviajando` | iCloud folder |
| `WHISPER_MODEL_DIR` | `~/.local/share/whisper-cpp/models` | where `transcribe` looks for models |
| `WHISPER_MODEL` | `$WHISPER_MODEL_DIR/ggml-medium.bin` | model used by `transcribe` |
| `WHISPER_LANG` | `auto` | language passed to `whisper-cli` |

Set them before the shell loads the module, for example in `~/.zprofile`. The
setup script reads `STUDIO_DIR` and `RAIOVIAJANDO_DIR` too; both must be
absolute paths, and the script refuses relative ones because a relative link
target would be broken.

## Workflows

Start a video:

```sh
newvideo my-topic        # ~/Studio/videos/2026-10-my-topic, from the template
```

Transcribe a recording (the model is a manual download, see
[content-creation.md](content-creation.md#whisper-models)):

```sh
transcribe narration.wav > narration.txt
WHISPER_LANG=pt transcribe narration.wav
```

Find a sound effect and open the shared library:

```sh
sfx bell
rlib sfx
```

## Manual steps

- Add `~/Studio` and the Raioviajando folder to the Finder sidebar by dragging
  them in; macOS has no stable command for this, so it is not scripted.
- Keep the Raioviajando folder downloaded (Finder, Keep Downloaded) when you
  need it offline; with Optimize Mac Storage, files can be evicted from disk.
- Install Shure MOTIV Mix and download a Whisper model by hand
  ([content-creation.md](content-creation.md)).

## Keep outside version control

Large media, personal recordings, licensed music (for example Mixkit tracks),
Whisper models and app data never belong in this repository. The `studio`
module only adds scripts and paths.

## Limitations

- The module assumes iCloud Drive's default location; use `RAIOVIAJANDO_DIR`
  for another one.
- `sfx` reads the library's `manifest.csv` and matches any column, so a short
  term can match several rows.
- Shortcuts are zsh functions; they are not available in other shells.
