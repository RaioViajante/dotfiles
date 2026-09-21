# dotfiles

An explicit, fast, reproducible development environment for **macOS** and
**Windows 11**, managed with [chezmoi](https://chezmoi.io). No large
shell frameworks, no stored credentials.

This repository is the *executable* half of the setup: shell, prompt, Git
defaults, editor settings, package manifests and idempotent bootstrap scripts.
Machine architecture — disks, dual boot, Secure Boot, NVIDIA, recovery — lives
in the separate **workstation-setup** repository and is not duplicated here.

## Supported systems

| Platform | Package manager | Node | Java | Shell integration |
| --- | --- | --- | --- | --- |
| macOS (Apple Silicon) | Homebrew (`Brewfile`) | `node@24` (Homebrew) | `openjdk@25` default + `openjdk@21` (Homebrew) | Homebrew paths, `java_home` |
| Windows 11 (x64) | `winget` + curated manifest | fnm + Node 24 LTS | winget Temurin 25 default + 21, `jdk` switcher | PowerShell 7, fnm, zoxide, Starship |

Everything shared between the platforms is written once; platform differences
are isolated in small chezmoi templates keyed on `.chezmoi.os` and, for Windows,
in source paths that only exist there (`Documents/`, `AppData/`).

## Layout

```text
.
├── .chezmoi.toml.tmpl              # chezmoi config (no prompts)
├── .chezmoiignore                  # keeps README/Brewfile/scripts/manifests in source only; per-OS targets
├── .gitattributes                  # LF everywhere, including Windows checkouts
├── Brewfile                        # macOS package manifest (formulae and casks)
├── dot_zshrc / dot_zprofile        # Zsh entry points
├── dot_gitconfig                   # Git behaviour + shared identity (noreply email)
├── dot_config/
│   ├── starship.toml.tmpl          # shared prompt (scan_timeout is per OS)
│   ├── nvim/                        # Neovim, modular Lua config      (shared)
│   │   ├── init.lua                 # entry point: leader keys, module loading
│   │   ├── lua/config/             # options, keymaps, autocmds, lazy bootstrap
│   │   ├── lua/plugins/            # one file per concern, auto-imported by lazy
│   │   └── lazy-lock.json          # pinned plugin versions
│   ├── zsh/
│   │   ├── options.zsh             # history + shell options   (shared)
│   │   ├── paths.zsh.tmpl          # PATH                       (per OS)
│   │   ├── completion.zsh          # completion + macOS fzf     (shared)
│   │   ├── aliases.zsh             # aliases                    (shared)
│   │   ├── functions.zsh           # helper functions          (shared)
│   │   ├── dev.zsh.tmpl            # EDITOR/PAGER + macOS jdk() (per OS)
│   │   └── tools.zsh               # zoxide + starship          (shared)
├── Documents/PowerShell/Microsoft.PowerShell_profile.ps1   # PowerShell 7 profile (Windows only)
├── AppData/
│   ├── Roaming/Code/User/settings.json.tmpl        # VS Code settings   (Windows only)
│   └── Local/nvim/                 # Neovim on Windows: one include stub per shared file
├── private_Library/.../Code/User/settings.json     # VS Code settings   (macOS only)
├── private_Library/.../iTerm2/DynamicProfiles/raioviajante.json # iTerm2 profile (macOS only)
├── manifests/
│   ├── mas-apps.txt                # Mac App Store apps (macOS)
│   ├── windows-packages.txt        # curated winget packages (Windows)
│   └── vscode-extensions.txt       # canonical VS Code extensions (all platforms)
├── scripts/
│   ├── lib.sh                      # shared bash helpers
│   ├── check-secrets.sh            # pre-commit secret scan
│   ├── windows/                    # idempotent Windows bootstrap (PowerShell 7)
│   │   ├── bootstrap.ps1           # runs 10..50 in order (-Only, -DryRun)
│   │   ├── lib.ps1                 # shared helpers
│   │   ├── 10-packages.ps1         # winget packages from the manifest
│   │   ├── 20-runtimes.ps1         # fnm + Node 24, pnpm, Rust, uv Python, Maven, Composer
│   │   ├── 30-vscode-extensions.ps1 # extensions from the manifest
│   │   ├── 40-neovim.ps1           # plugins, Tree-sitter parsers, Mason tools
│   │   └── 50-terminal.ps1         # Windows Terminal baseline
│   ├── macos/
│   │   ├── apply-preferences.sh    # opt-in appearance + Dock + Finder personalization
│   │   ├── install-vscode-extensions.sh # extensions from the manifest (run by chezmoi)
│   │   ├── macos-defaults.sh       # opt-in macOS file-handling defaults
│   │   ├── register-jdks.sh        # symlink Homebrew JDKs into /Library/Java
│   │   ├── setup-startup.sh        # Login Items + Homebrew MySQL service
│   │   ├── install-mas-apps.sh     # Mac App Store apps from manifests/mas-apps.txt
│   │   ├── setup-claude-config.sh  # merge-only safe Claude Code settings
│   │   └── setup-proton-mcp.sh     # register proton-mail in Claude Code / Codex
├── run_once_before_10-install-homebrew.sh.tmpl   # macOS only
├── run_onchange_before_20-brew-bundle.sh.tmpl    # macOS only
├── run_onchange_after_25-vscode-extensions.sh.tmpl # macOS only: extensions from the manifest
├── run_onchange_after_30-local-setup.sh.tmpl     # macOS: local dirs + git identity stub
└── run_onchange_after_30-local-setup.ps1.tmpl    # Windows: git identity stub + bootstrap hint
```

Files prefixed `dot_` are applied to `$HOME`. `README.md`, `Brewfile`,
`manifests/`, `scripts/` and `.github/` stay in the chezmoi source state
(`.chezmoiignore`). On Windows the Zsh files, `dot_config/nvim` (Neovim lives in
`%LOCALAPPDATA%\nvim` there) and the shell run scripts are ignored; on macOS the
`Documents/` and `AppData/` trees are ignored.

## Bootstrap

### macOS

The standalone chezmoi installer works without Homebrew:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply RaioViajante
```

First apply: installs Homebrew if missing → `brew bundle` (packages, casks and
the curated VS Code extensions) → applies dotfiles → creates local dirs. The Git
identity in `dot_gitconfig` works immediately.

Then, once, register the Homebrew JDKs with macOS (admin password required):

```sh
"$(chezmoi source-path)/scripts/macos/register-jdks.sh"
```

### Windows 11

Prerequisites (one time, by hand):

- Windows 11 x64 with `winget` (App Installer), signed in with your own account.
- PowerShell 7, Git and chezmoi, installed from a normal Windows PowerShell prompt:

  ```powershell
  winget install --id Microsoft.PowerShell --source winget
  winget install --id Git.Git --source winget
  winget install --id twpayne.chezmoi --source winget
  ```

- WSL 2 with Ubuntu, from an elevated prompt (may need a reboot):
  `wsl --install -d Ubuntu-24.04`. Docker Desktop uses the WSL 2 backend and owns
  the Docker engine: never install `docker.io` or Docker Engine inside Ubuntu.
  Ubuntu under WSL is Windows infrastructure only; it is not managed by these
  dotfiles.

Then, from PowerShell 7 (`pwsh`), in a normal (non-elevated) session:

```powershell
git clone https://github.com/RaioViajante/dotfiles.git $HOME\dotfiles
& $HOME\dotfiles\scripts\windows\bootstrap.ps1        # packages, runtimes, extensions
chezmoi init --source $HOME\dotfiles --apply           # configuration files
& $HOME\dotfiles\scripts\windows\bootstrap.ps1        # second pass: Neovim state, terminal
```

`chezmoi init --source` records the working copy as chezmoi's source directory, so
later `chezmoi diff` / `chezmoi apply` work without extra flags. The bootstrap is
idempotent; `-DryRun` reports without changing anything, `-Only 40` runs one step,
and `-InstallBuildTools` also installs the Visual Studio Build Tools that Rust needs
for linking (large, shows an elevation prompt). Installers that need elevation
request it themselves; do not run the bootstrap as administrator.

Design notes:

- **Packages:** `manifests/windows-packages.txt` lists human-readable winget IDs
  (never a raw `winget export`); only missing packages are installed and no patch
  versions are pinned, except the two JDK majors. `msstore:` entries are Store
  product IDs. Docker Desktop is installed per user with `--backend=wsl-2`.
- **Node:** fnm installs Node 24 and the bootstrap puts fnm's stable
  `aliases\default` junction on the User `PATH`, so GUI programs (VS Code, IDEs)
  find Node without loading the PowerShell profile. The temporary
  `fnm_multishells` paths are never persisted. pnpm comes from Corepack.
- **Python:** `uv` installs Python 3.14 and its `python.exe` shims in `~\.local\bin`.
- **Java:** winget installs Temurin 25 (machine default) and 21. Run `jdk 21` /
  `jdk 25` in PowerShell to switch the current session only (`jdk` alone lists
  them); no machine `PATH` rewrite, no SDKMAN. VS Code's
  `java.configuration.runtimes` is generated when chezmoi renders the settings
  template, by discovering the installed JDKs, so no patch-specific path is
  committed. Re-run `chezmoi apply` after a JDK upgrade to refresh it.
- **Rust:** `rustup` with the MSVC toolchain. Linking needs the Visual Studio
  Build Tools C++ workload (`-InstallBuildTools`); the bootstrap warns if it is missing.
- **Maven / Composer:** not in winget; installed from Apache and getcomposer.org
  with the published checksum verified before use.
- **Windows Terminal:** not managed by chezmoi. Terminal rewrites its
  `settings.json` and the file is per-machine state, so `50-terminal.ps1` only
  ensures three keys (default profile = PowerShell 7, font =
  JetBrainsMono Nerd Font, starting directory = home) and backs up the file first.
- **Starship:** the shared config is a template; only `scan_timeout` differs
  (500 ms on Windows, where shorter timeouts produce scan-timeout warnings).
- **Line endings:** `.gitattributes` forces LF, so Windows checkouts stay
  compatible with WSL, chezmoi and CI.
- **Project location:** `C:\Users\<you>\Developer` is the primary directory for
  Windows-native work. Projects that become strongly Linux/filesystem dependent
  may later live inside the Ubuntu WSL filesystem; nothing here moves them.

### macOS restore order

1. Install macOS and the Xcode Command Line Tools (`xcode-select --install`).
2. Run the chezmoi one-liner above (Homebrew, every formula, cask and VS Code
   extension in the `Brewfile`, then the dotfiles).
3. Run the opt-in scripts in `scripts/macos/` (`register-jdks.sh`,
   `macos-defaults.sh`, `apply-preferences.sh`, `setup-proton-mcp.sh`).
4. Do the manual steps below (sign-ins, SSH key, Mac App Store apps).
5. Verify: `chezmoi diff` (empty), `brew bundle check --file="$(chezmoi source-path)/Brewfile"`.

Official AI desktop apps are in the `Brewfile`: `claude` (Claude Desktop, which
includes Claude Code) and `chatgpt` (the ChatGPT desktop app, which now hosts
Codex; the standalone Codex app was discontinued). The Claude Code and Codex
CLIs are installed separately with their vendors' installers.

## Update workflow

```sh
chezmoi update          # git pull + apply
chezmoi diff            # preview pending changes
chezmoi apply           # apply
```

Apply configuration without re-running the Brewfile (macOS):

```sh
DOTFILES_SKIP_BREW_BUNDLE=1 chezmoi apply
```

After pulling a change that touches `.chezmoi.toml.tmpl`, run `chezmoi init`
once (it asks nothing).

On Windows, re-run `scripts\windows\bootstrap.ps1` (or `-Only <step>`) to pick
up manifest or toolchain changes.

## What is shared vs platform-specific

**Shared:** Zsh options, history, completion, aliases, helper functions,
Starship, zoxide, Git behaviour and identity (noreply email), editor conventions,
the Neovim configuration (`dot_config/nvim/`, also applied on Windows through
`AppData/Local/nvim/` include stubs), the VS Code extension list
(`manifests/vscode-extensions.txt`).

**macOS-specific:** Homebrew (`Brewfile` packages + `vscode` extensions,
`dot_zprofile`, brew run scripts), `openjdk@25` `JAVA_HOME` with the `jdk()`
`java_home` switcher, VS Code app-bundle `PATH`, the macOS VS Code
`settings.json` (`java.configuration.runtimes` + Python interpreter + Material
Icon Theme + Catppuccin Mocha colour theme), the iTerm2 Dynamic Profile
`raioviajante`, `scripts/macos/macos-defaults.sh`,
`scripts/macos/register-jdks.sh`, `scripts/macos/apply-preferences.sh`.

**Windows-specific:** `manifests/windows-packages.txt`, everything under
`scripts/windows/`, the PowerShell 7 profile (a native port of the shared aliases
and helpers, with the same fnm / zoxide / Starship integrations, plus the `jdk`
switcher), the Windows VS Code `settings.json` template, and the `AppData/Local/nvim`
stubs. The profile drops the built-in `gc`, `gp` and `gl` aliases so the git
shortcuts of the same name work. macOS-only `jdk()`, Podman `pods`, zsh
key bindings and fzf key bindings (Ctrl-T / Ctrl-R / Alt-C) are not ported;
`proj` and `FZF_DEFAULT_OPTS` are. `extract` supports tar, tar.gz/bz2/xz, zip and
7z through Windows' bundled bsdtar and a bare `.gz` through .NET; a bare `.bz2`
reports "unsupported archive" because stock Windows has no tool for it.

## Neovim

A modular Lua configuration in `dot_config/nvim/`, shared between all platforms.
Installed by the `Brewfile` on macOS and `manifests/windows-packages.txt` on Windows. VS Code stays the primary editor; Neovim is the terminal editor and the
`EDITOR` fallback when `code` is absent.

- **Plugin manager:** [lazy.nvim](https://github.com/folke/lazy.nvim),
  bootstrapped on the first launch. Plugin versions are pinned in
  `lazy-lock.json` (committed).
- **Layout:** `init.lua` sets the leader key (space) and loads `lua/config/`
  (options, keymaps, autocmds, lazy bootstrap); every file in `lua/plugins/` is
  auto-imported, one concern per file.
- **Language servers and formatters** install through Mason on the first launch
  (`:Mason` to inspect). Covered: TypeScript / JavaScript / Angular, HTML / CSS,
  JSON, ESLint, PHP (Intelephense), Python (Pyright + Ruff), Java (jdtls, basic),
  Lua, Bash and YAML; formatting on save via `stylua`, `prettierd`, `black`,
  `isort` and `shfmt`.
- **First launch:** run `nvim`, let lazy install everything, then restart once so
  the freshly installed servers attach. `:checkhealth` reports the rest.
- **Theme:** Catppuccin Mocha, matching VS Code and the iTerm2 profile. The
  terminal font (Monaco) is not a Nerd Font, so plugin glyphs fall back to ASCII;
  install a Nerd Font and set `vim.g.have_nerd_font = true` in `init.lua` for
  icons.
- **After `:Lazy update`:** re-stage the lockfile with
  `chezmoi re-add ~/.config/nvim/lazy-lock.json`, then commit.
- **Windows:** Neovim reads `%LOCALAPPDATA%\nvim`, not `~/.config/nvim`. Each
  shared file has a one-line stub under `AppData/Local/nvim/` that `include`s it,
  so the configuration exists once; add a stub when you add a file (CI checks the
  required entry points). After `:Lazy update` on Windows, copy
  `%LOCALAPPDATA%\nvim\lazy-lock.json` over `dot_config/nvim/lazy-lock.json` and commit.
  Tree-sitter parsers are compiled with Zig (`zig.zig`), so no Visual Studio
  developer environment is needed. `40-neovim.ps1` installs them **one at a time**
  with the config bypassed: the config's own `ensure_installed` starts every build at
  once, and concurrent cold-cache Zig runs deadlock. Plugins, parsers and Mason
  tools are rebuilt state, never committed. Expected `:checkhealth` warnings, left
  alone on purpose: no Python `neovim` provider, no `tree-sitter` CLI, no
  `vim.pack` lockfile.

## Manual steps (never automated)

Windows (in addition to the applicable items below):

- Sign-ins are always manual: GitHub (`gh auth login --hostname github.com --web
  --git-protocol ssh`), Proton, Discord, Spotify, JetBrains, Postman, Notion,
  Claude, ChatGPT, Docker Hub. VS Code Settings Sync stays off.
- SSH key creation and registration (one key per machine, never automated).
- WSL 2 and the Ubuntu distribution (elevated `wsl --install`, possible reboot),
  then Docker Desktop's first launch and Settings -> Resources -> WSL Integration
  for `Ubuntu-24.04`. Keep "start at login" off; Kubernetes and Windows containers
  stay disabled.
- Windows Terminal must have been opened once before `50-terminal.ps1` can find
  its settings file.
- Intentionally not installed: Bitwarden (Proton Pass is the password manager),
  any native database server (databases run in Docker), Podman, Docker Engine
  inside WSL.
- Intentionally not managed: Windows Terminal's full settings, browser
  profiles, SSH keys, credentials, Docker/WSL state, and application data.

- GitHub sign-in: `gh auth login --hostname github.com --web --git-protocol ssh`
- SSH key creation and registration (one dedicated key per machine):

  ```sh
  ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_github
  gh ssh-key add ~/.ssh/id_ed25519_github.pub --type authentication --title "$(hostname)"
  ```

- Default shell: `chsh -s "$(command -v zsh)"` then log out / in
- Xcode Command Line Tools (macOS): required for Homebrew, `git` and `clang`.
  `chezmoi apply` checks `xcode-select -p` and prints install instructions
  (`xcode-select --install`) if missing, then re-check by re-running
  `chezmoi apply`. This machine also has the full `Xcode.app` installed from
  the Mac App Store (`open 'macappstore://apps.apple.com/app/id497799835'`,
  Adam ID read from `Xcode.app`'s own metadata); that is only needed for
  iOS/macOS app development, not for this setup, and Apple does not ship a
  Homebrew cask for it, so it stays a manual install like Proton Authenticator
  below.
- macOS JDK registration: `"$(chezmoi source-path)/scripts/macos/register-jdks.sh"`
  (needs an admin password once, to symlink the Homebrew JDKs into
  `/Library/Java/JavaVirtualMachines` so `java_home`, VS Code and IntelliJ find
  them). `chezmoi apply` never calls `sudo`, so this stays a manual step.
- macOS desktop personalization: `"$(chezmoi source-path)/scripts/macos/apply-preferences.sh"`
  sets the global appearance (Dark mode + Purple accent), builds the Dock
  (contents + position bottom / always visible / no-recents / minimize-to-app,
  via `dockutil`; icon size left at the macOS default) and a few Finder view
  options. It is idempotent, needs no `sudo`, and is intentionally kept out of
  `chezmoi apply` so a routine update never rearranges the Dock. Log out / in
  once afterwards for the accent colour to reach every UI element.
- iTerm2 profile: `chezmoi apply` writes the Dynamic Profile
  `~/Library/Application Support/iTerm2/DynamicProfiles/raioviajante.json`
  (font, window size, transparency, blur, colours). iTerm2 loads it live, but
  does not make it the default automatically: open **Settings -> Profiles**,
  select `raioviajante`, then **Other Actions -> Set as Default** once. On a
  machine that already has a hand-made profile of the same name, delete that one
  first so there is no duplicate.
- Wallpaper: not automated (the macOS wallpaper store is not a stable public
  interface) and no image is stored in this public repository. Pick one from
  **System Settings -> Wallpaper**.
- Login Items and background services: `"$(chezmoi source-path)/scripts/macos/setup-startup.sh"`
  (ProtonVPN and Notion Login Items, Homebrew `mysql` service). Apps that manage
  their own startup (Proton Mail Bridge, AltTab) are set inside those apps.
- Mac App Store apps: sign in to the App Store with your own Apple ID, then run
  `"$(chezmoi source-path)/scripts/macos/install-mas-apps.sh"` (never purchases).
- Claude Code settings: `"$(chezmoi source-path)/scripts/macos/setup-claude-config.sh"`
  adds the theme, TUI mode and iTerm2 status hooks if missing; credentials and
  per-project trust are never managed.
- Docker Desktop: not managed (it rewrites its own settings). After the first
  launch keep "start at login" off; nothing else is customised.
- Peripheral software (Logitech, Razer) is intentionally not managed here.
- Proton Authenticator: no Homebrew cask exists yet and Proton ships macOS
  builds only through the Mac App Store (no standalone `.dmg`/`.pkg`), so it is
  not in the Brewfile. Install it from the App Store
  (`open 'macappstore://apps.apple.com/app/id6741758667'`), signed in with your
  own Apple ID. Once `/Applications/Proton Authenticator.app` exists,
  `apply-preferences.sh` picks it up in the Dock like any other app; add a
  Homebrew cask to the Brewfile if Proton ever ships one.
- Proton Mail MCP server (Claude Code / Codex):
  `"$(chezmoi source-path)/scripts/macos/setup-proton-mcp.sh"` registers the
  `proton-mail` MCP server at user/global scope in both clients, so it is
  available from any working directory instead of only inside
  `~/Developer/proton-mail-mcp`. That repo is managed on its own (not by this
  one); the script only checks that it exists, is built
  (`pnpm install && pnpm run build`), and that Proton Mail Bridge is
  installed, then wires up the MCP registration. It is idempotent, needs no
  `sudo`, stores no secrets, and reports (instead of silently overwriting) if
  a differing registration already exists. Proton account sign-in and Bridge
  pairing stay manual, same as the rest of the Proton ecosystem.

## Security model

Never managed, never copied into the source state, blocked by `.gitignore` and
`.chezmoiignore` as defence in depth:

- private or public SSH keys, `known_hosts`, `authorized_keys`
- Secure Boot / MOK key material
- GitHub CLI tokens, `.npmrc` / `.netrc` / Docker auth, `.env` files, API keys
- `~/.config/git/local.gitconfig` (optional per-machine Git overrides)
- the real `monitors.xml` and other hardware-specific state
- clipboard history, shell history, caches, keyrings

The versioned Git identity is a `github.com` noreply address, which is public by
design; the real personal address must never appear.

Run before every commit:

```sh
./scripts/check-secrets.sh
git diff --check
git status --short
```

## Relationship to workstation-setup

| Repository | Scope |
| --- | --- |
| **dotfiles** (this repo) | executable user environment: shell, prompt, Git, editor, package manifests, idempotent bootstrap scripts, CI |
| **workstation-setup** | machine architecture: hardware, disk layout, dual boot, Secure Boot, NVIDIA, storage, networking, recovery |

If a fact is about *this hardware*, it belongs in workstation-setup. If it is a
reproducible user-level configuration step, it belongs here.

## CI

`.github/workflows/validate.yml` runs on macOS and Ubuntu for every push and PR.
The Ubuntu runner is only a lint host (repository structure, ShellCheck, secret
and machine-path scan, a Portuguese-text language audit and a trailing-whitespace
check); Linux is not a supported dotfiles target. The macOS job additionally
renders Zsh/Bash syntax, validates the chezmoi templates and manifests, and runs
an isolated `chezmoi apply`.
A separate Windows job checks PowerShell syntax, that the profile loads without any
optional tool installed, the Windows manifests, and an isolated `chezmoi apply`
(including that no Unix-only target is written and the settings are valid JSONC).

## License

[MIT](LICENSE).
