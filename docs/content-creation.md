# Content creation

The `content` module installs recording, 3D, painting and audio tools from
`brew/content.Brewfile`.

## Included

| Tool | Package | Notes |
| --- | --- | --- |
| OBS Studio | `cask "obs"` | Apple Silicon build; updates itself |
| Blender | `cask "blender"` | Apple Silicon build |
| Krita | `cask "krita"` | official signed macOS build |
| Audacity | `cask "audacity"` | installs as `Audacity 4.app` |
| FFmpeg | `brew "ffmpeg"` | command-line audio and video conversion |

## Install

```sh
cd ~/.local/share/chezmoi
./setup content
```

Skip a tool for one run with, for example,
`HOMEBREW_BUNDLE_CASK_SKIP="blender" ./setup content`, or remove it from
`brew/content.Brewfile`.

## Automatic versus manual

`./setup content` only installs the apps. On first launch, macOS asks OBS for
camera, microphone and screen-recording permission; grant those in System
Settings > Privacy & Security. Scenes, profiles, brushes, add-ons and media
projects are user data and are not managed here.

Project-specific tools stay with their projects: for example Remotion and its
agent skills belong in the video project's own dependencies, not in this
repository.

## Authentication

None of these tools needs an account.

## Limitations

- FFmpeg pulls in a large set of Homebrew dependencies.
- The Krita download page does not state the architecture of its macOS build;
  check with `lipo -archs /Applications/Krita.app/Contents/MacOS/krita` if it
  matters.
