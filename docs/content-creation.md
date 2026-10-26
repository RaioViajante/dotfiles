# Content creation

The `content` module installs recording, 3D, painting, game development,
audio/video and speech-to-text tools from `brew/content.Brewfile` plus
Descript's official installer.

## Included

| Tool | Package | Notes |
| --- | --- | --- |
| OBS Studio | `cask "obs"` | Apple Silicon build; updates itself |
| Blender | `cask "blender"` | Apple Silicon build |
| Krita | `cask "krita"` | official signed macOS build |
| Godot | `cask "godot"` | game engine (GDScript); imports `.blend` files through Blender |
| Audacity | `cask "audacity"` | installs as `Audacity 4.app` |
| Descript | `scripts/macos/install-descript.sh` | official current installer; updates itself |
| CapCut | `cask "capcut"` | video editor and image design app |
| FFmpeg | `brew "ffmpeg"` | command-line audio and video conversion |
| whisper.cpp | `brew "whisper.cpp"` | local speech-to-text (`whisper-cli`); formerly named `whisper-cpp`; needs a model, see below |

## Install

```sh
cd ~/.local/share/chezmoi
./setup content
```

Skip a tool for one run with, for example,
`HOMEBREW_BUNDLE_CASK_SKIP="blender" ./setup content`, or remove it from
`brew/content.Brewfile`. The Descript step skips an existing current install;
run `scripts/macos/install-descript.sh` directly when needed.

## Automatic versus manual

`./setup content` installs the Homebrew packages, then installs Descript from
its official current macOS installer. The Homebrew cask is intentionally not
used because it can install the retired `114.x-release` desktop build, which no
longer loads the current Descript web application. On first launch, macOS asks
OBS for camera, microphone and screen-recording permission; grant those in
System Settings > Privacy & Security. Scenes, profiles, brushes, add-ons,
accounts and media projects are user data and are not managed here.

Project-specific tools stay with their projects: for example Remotion and its
agent skills belong in the video project's own dependencies, not in this
repository.

## Classification

| Tool | Class | How |
| --- | --- | --- |
| OBS Studio, Blender, Krita, Godot, Audacity, CapCut | automatic | `./setup content` (Homebrew casks) |
| FFmpeg, whisper.cpp | automatic | `./setup content` (Homebrew formulas) |
| Descript | automatic | official installer, not the cask (see above) |
| Shure MOTIV Mix | manual | download from Shure's website; see below |
| Whisper models | manual | download one yourself; see below |
| `yt-dlp`, `exiftool`, `imagemagick`, `sox`, `mediainfo` | optional | not installed or declared; add a `brew` line to `brew/content.Brewfile` only if a workflow needs one |

## Shure MOTIV Mix

Shure MOTIV Mix is installed from Shure's own installer, not Homebrew. The
`shureplus-motiv` cask is a different, older application (ShurePlus MOTIV
Desktop, an Intel build that needs Rosetta); it does not replace MOTIV Mix and
is deliberately not declared. Grant microphone access when macOS asks.

## Whisper models

`whisper-cli` needs a ggml model file. Models are hundreds of megabytes to
several gigabytes, so `setup` never downloads one. Keep them outside Git and
outside iCloud Drive, for example in:

```sh
mkdir -p ~/.local/share/whisper-cpp/models
curl -L -o ~/.local/share/whisper-cpp/models/ggml-medium.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin
shasum -a 256 ~/.local/share/whisper-cpp/models/ggml-medium.bin
```

The `ggml-medium.bin` used for the first episode has SHA-256
`6c14d5adee5f86394037b4e4e8b59f1673b6cee10e3cf0b11bbdbee79c156208`; compare
your download with it, or with the checksum published by the whisper.cpp
project, before relying on it.

## Authentication

Descript requires an account. CapCut can be used without signing in, but some
features require an account. Authentication stays outside this repository.

## Limitations

- FFmpeg pulls in a large set of Homebrew dependencies.
- CapCut is a cask. If it was installed by hand, Homebrew refuses to overwrite
  the app and `setup` reports a failure for it; remove the manual copy first or
  adopt it with `brew install --cask --adopt capcut`.
- The Krita download page does not state the architecture of its macOS build;
  check with `lipo -archs /Applications/Krita.app/Contents/MacOS/krita` if it
  matters.
