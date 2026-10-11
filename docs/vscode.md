# VS Code

The `vscode` configuration module installs VS Code, applies the managed user
settings and installs the extensions listed in
`manifests/vscode-extensions.txt`.

## Included

- **Packages**: `cask "visual-studio-code"` (`brew/vscode.Brewfile`), the
  shared JetBrains Mono Nerd Font (terminal font) and `chezmoi`.
- **Settings**: `~/Library/Application Support/Code/User/settings.json`
  (managed, kept minimal): Homebrew JDK 25/21 runtimes, Homebrew Python,
  rust-analyzer from rustup, Catppuccin Mocha with Material icons, the Nerd Font
  in the integrated terminal, built-in PHP suggestions off in favour of
  Intelephense, Red Hat telemetry off, Copilot off, no command center.
- **Extensions** (installed by `scripts/macos/install-vscode-extensions.sh`):

  | Area | Extensions |
  | --- | --- |
  | Web | Angular Language Service, Tailwind CSS IntelliSense, ESLint, EditorConfig, Prettier |
  | Java / Spring Boot | Extension Pack for Java, Spring Boot Extension Pack |
  | PHP / Laravel | PHP Intelephense, Laravel (official) |
  | Rust | rust-analyzer |
  | Python | Ruff, Python (with Pylance, debugger and environments) |
  | Containers, config, databases | Container Tools, YAML, SQLTools with MySQL, PostgreSQL and SQLite drivers |
  | Tools and appearance | Claude Code, Catppuccin, Material Icon Theme |

  Extension packs install their own members, which are not listed separately.

## Install and apply

```sh
cd ~/.local/share/chezmoi
./setup vscode                  # app, settings and extensions
./setup --no-packages vscode    # settings only
```

The extension script installs only missing extensions and can be rerun on its
own: `scripts/macos/install-vscode-extensions.sh`.

## Project settings stay in charge

Formatting and linting come from each project: there is no global
`editor.formatOnSave` or default formatter. Prettier, ESLint, Ruff and
EditorConfig read the project's configuration, and workspace settings in
`.vscode/settings.json` override the user settings. Projects can recommend
extensions through `.vscode/extensions.json`.

## Rust

`rust-analyzer.server.path` points to rustup's proxy
(`/opt/homebrew/opt/rustup/bin/rust-analyzer`, installed by the
[dev module](development.md)), so the server follows the project's
`rust-toolchain.toml`. Without the dev module, Rust projects report that the
server is missing.

## Manual steps

- PHP Intelephense recommends disabling the built-in **PHP Language Features**
  extension (Extensions view, search `@builtin php`). The managed settings only
  turn off its suggestions (`php.suggest.basic: false`), because extension
  enablement is not a setting.
- Settings Sync is not enabled by this setup. If you turn it on, exclude
  Settings from sync so it does not compete with chezmoi over `settings.json`.
- Sign in to the Claude Code extension from its panel.

## Customize or omit

Add or remove extension IDs in `manifests/vscode-extensions.txt`; packs and
their members do not need separate entries. Settings changed in the VS Code UI
are overwritten on the next apply; put lasting changes in the managed file or
in workspace settings.

## Limitations

- Extensions installed by hand are not removed by the script.
- The `code` command is found inside the app bundle even when VS Code has not
  added it to PATH.
