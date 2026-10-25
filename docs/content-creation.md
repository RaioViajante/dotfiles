# Content creation

The `content` module installs recording, 3D, painting, game development and
audio/video tools from `brew/content.Brewfile` plus Descript's official
installer.

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

## Authentication

Descript requires an account. CapCut can be used without signing in, but some
features require an account. Authentication stays outside this repository.

## Limitations

- FFmpeg pulls in a large set of Homebrew dependencies.
- The Krita download page does not state the architecture of its macOS build;
  check with `lipo -archs /Applications/Krita.app/Contents/MacOS/krita` if it
  matters.
