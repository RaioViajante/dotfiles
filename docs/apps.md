# Desktop apps

The `apps` module installs everyday desktop apps from `brew/apps.Brewfile`.
Developer apps (Docker Desktop, IntelliJ IDEA, Postman, MySQL Workbench,
Firefox Developer Edition) belong to the [dev module](development.md); AI apps
to the [ai module](ai.md); content creation apps to the
[content module](content-creation.md).

## Included

| Group | Apps |
| --- | --- |
| Productivity | AltTab, Notion, Obsidian, Google Drive, ExcalidrawZ |
| Communication and media | Discord, WhatsApp, Spotify |
| Browsers | Zen, Tor Browser |
| Proton | Proton Mail, Proton Pass, Proton Drive, Proton VPN, Proton Mail Bridge |
| Tooling | `dockutil` (used by `scripts/macos/apply-preferences.sh`) |

Obsidian installs the app only; vaults and their `.obsidian` settings are user
data and never live in this repository.

## Install

```sh
cd ~/.local/share/chezmoi
./setup apps
```

Omit apps for one run with `HOMEBREW_BUNDLE_CASK_SKIP="spotify whatsapp"
./setup apps`, or remove them from `brew/apps.Brewfile`.

## Manual installs

These have no usable Homebrew package:

- **TeamSpeak 6** (beta, with screen sharing): download the Apple Silicon build
  from <https://teamspeak.com/en/downloads/>. The `teamspeak-client@beta` cask
  is disabled because it fails Gatekeeper checks, so it is not used.
- **Proton Authenticator**: App Store only, and `mas` cannot resolve it. Open
  `macappstore://apps.apple.com/app/id6741758667` while signed in to the App
  Store.

## Automatic versus manual

`./setup apps` installs the apps. Everything else is manual:

- Sign in to each app; Proton VPN also asks you to approve its network
  extension in System Settings.
- Google Drive installs from a `.pkg` and asks for an administrator password.
- Optional macOS preferences, never run by `setup` or `chezmoi apply`:

  ```sh
  scripts/macos/macos-defaults.sh       # file-handling defaults (extensions, save dialogs)
  scripts/macos/apply-preferences.sh    # dark mode, accent colour, Dock and Finder
  scripts/macos/setup-startup.sh        # Proton VPN and Notion login items, MySQL service
  ```

  `apply-preferences.sh` rebuilds the Dock from the apps that are installed and
  skips missing ones. `setup-startup.sh` starts MySQL only when the dev module
  installed it.

## Authentication

Every app keeps its own sign-in. No credentials, browser profiles or app data
are stored in this repository.

## Limitations

- Casks that update themselves (for example Google Drive and Obsidian) may
  report a newer version than Homebrew records; that is expected.
- Peripheral software and the wallpaper are not managed.
