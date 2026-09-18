# dotfiles

An explicit, fast, reproducible development environment for **macOS** and
**Fedora Workstation**, managed with [chezmoi](https://chezmoi.io). No large
shell frameworks, no stored credentials.

This repository is the *executable* half of the setup: shell, prompt, Git
defaults, editor settings, package manifests and idempotent bootstrap scripts.
Machine architecture — disks, dual boot, Secure Boot, NVIDIA, recovery — lives
in the separate **workstation-setup** repository and is not duplicated here.

## Supported systems

| Platform | Package manager | Node | Java | Shell integration |
| --- | --- | --- | --- | --- |
| macOS (Apple Silicon) | Homebrew (`Brewfile`) | `node@24` (Homebrew) | `openjdk@25` default + `openjdk@21` (Homebrew) | Homebrew paths, `java_home` |
| Fedora Workstation | `dnf` + curated manifest | fnm + Node 24 LTS | SDKMAN (Temurin 25 / 21) | fnm, pnpm, SDKMAN |

Everything shared between the two is written once; platform differences are
isolated in small chezmoi templates keyed on `.chezmoi.os`.

## Layout

```text
.
├── .chezmoi.toml.tmpl              # chezmoi config (no prompts)
├── .chezmoiignore                  # keeps README/Brewfile/scripts/manifests in source only
├── Brewfile                        # macOS package manifest (packages + VS Code extensions)
├── dot_zshrc / dot_zprofile        # Zsh entry points
├── dot_gitconfig                   # Git behaviour + shared identity (noreply email)
├── dot_config/
│   ├── starship.toml               # shared prompt
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
│   │   ├── integrations.zsh.tmpl   # fnm / pnpm / SDKMAN / fzf  (per OS)
│   │   └── tools.zsh               # zoxide + starship          (shared)
│   └── Code/User/settings.json.tmpl   # VS Code settings        (Linux only)
├── private_Library/.../Code/User/settings.json     # VS Code settings   (macOS only)
├── private_Library/.../iTerm2/DynamicProfiles/raioviajante.json # iTerm2 profile (macOS only)
├── manifests/
│   ├── fedora-packages.txt         # curated dnf packages
│   └── vscode-extensions.txt       # curated VS Code extensions
├── scripts/
│   ├── lib.sh                      # shared bash helpers
│   ├── check-secrets.sh            # pre-commit secret scan
│   ├── macos/
│   │   ├── apply-preferences.sh    # opt-in appearance + Dock + Finder personalization
│   │   ├── macos-defaults.sh       # opt-in macOS file-handling defaults
│   │   ├── register-jdks.sh        # symlink Homebrew JDKs into /Library/Java
│   │   └── setup-proton-mcp.sh     # register proton-mail in Claude Code / Codex
│   └── fedora/                     # idempotent Fedora bootstrap (run after apply)
│       ├── bootstrap.sh            # runs 10..70 in order
│       ├── 10-repositories.sh      # RPM Fusion, VS Code, Docker CE repos
│       ├── 20-packages.sh          # dnf install from the manifest
│       ├── 30-node.sh              # fnm, Node 24, Corepack, pnpm, Angular CLI
│       ├── 40-java.sh              # SDKMAN, Temurin 25 + 21, Maven
│       ├── 50-docker.sh            # Docker Engine CE + group
│       ├── 60-vscode-extensions.sh # VS Code + curated extensions
│       └── 70-gnome.sh             # gsettings preferences + shortcuts
├── run_once_before_10-install-homebrew.sh.tmpl   # macOS only
├── run_onchange_before_20-brew-bundle.sh.tmpl    # macOS only
└── run_onchange_after_30-local-setup.sh.tmpl     # both: local dirs + git identity stub
```

Files prefixed `dot_` are applied to `$HOME`. `README.md`, `Brewfile`,
`manifests/`, `scripts/` and `.github/` stay in the chezmoi source state
(`.chezmoiignore`).

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

### Fedora Workstation

```sh
sudo dnf install -y git chezmoi
chezmoi init --apply RaioViajante
```

This clones the source to `~/.local/share/chezmoi` and applies the
configuration. `chezmoi apply` never calls `sudo`. To keep the working copy
under `~/Developer` instead, clone it there and symlink chezmoi's source path
before `init`:

```sh
git clone git@github.com:RaioViajante/dotfiles.git ~/Developer/dotfiles
ln -s ~/Developer/dotfiles ~/.local/share/chezmoi
chezmoi init --apply
```

Then run the one-time system bootstrap:

```sh
"$(chezmoi source-path)/scripts/fedora/bootstrap.sh"
```

It is idempotent — safe to re-run — and each step can also be run alone
(`bootstrap.sh 30` runs only `30-node.sh`). It installs the external
repositories, the curated package set, the Node and Java toolchains, Docker
Engine CE, VS Code with the curated extensions, and the GNOME preferences.

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

On Fedora, re-run `"$(chezmoi source-path)/scripts/fedora/bootstrap.sh"` (or a
single step) to pick up manifest or toolchain changes.

## What is shared vs platform-specific

**Shared:** Zsh options, history, completion, aliases, helper functions,
Starship, zoxide, Git behaviour and identity (noreply email), editor conventions,
the Neovim configuration (`dot_config/nvim/`).

**macOS-specific:** Homebrew (`Brewfile` packages + `vscode` extensions,
`dot_zprofile`, brew run scripts), `openjdk@25` `JAVA_HOME` with the `jdk()`
`java_home` switcher, VS Code app-bundle `PATH`, the macOS VS Code
`settings.json` (`java.configuration.runtimes` + Python interpreter + Material
Icon Theme + Catppuccin Mocha colour theme), the iTerm2 Dynamic Profile
`raioviajante`, `scripts/macos/macos-defaults.sh`,
`scripts/macos/register-jdks.sh`, `scripts/macos/apply-preferences.sh`.

**Fedora-specific:** `manifests/fedora-packages.txt`, everything under
`scripts/fedora/`, fnm + pnpm + SDKMAN shell integration, the Linux VS Code
`settings.json`.

## Neovim

A modular Lua configuration in `dot_config/nvim/`, shared between both platforms.
Installed by the `Brewfile` on macOS and `manifests/fedora-packages.txt` on
Fedora. VS Code stays the primary editor; Neovim is the terminal editor and the
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

## Manual steps (never automated)

- GitHub sign-in: `gh auth login --hostname github.com --web --git-protocol ssh`
- SSH key creation and registration (one dedicated key per machine):

  ```sh
  ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_github
  gh ssh-key add ~/.ssh/id_ed25519_github.pub --type authentication --title "fedora"
  ```

- Default shell: `chsh -s "$(command -v zsh)"` then log out / in
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
  interface). The current image is
  `~/Library/Mobile Documents/com~apple~CloudDocs/wallhaven-m9rogm.jpg` (iCloud
  Drive); set it again from **System Settings -> Wallpaper** on a new machine.
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
- `docker` group: log out / in after the bootstrap adds you
- Clipboard Indicator: install from the GNOME Extensions app
- Secure Boot / MOK enrollment, firmware, disks, monitor layout: **workstation-setup**

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

Membership in the `docker` group is effectively root on the host — the Docker
bootstrap prints this warning explicitly.

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

`.github/workflows/validate.yml` runs on macOS and Linux for every push and PR:
repository structure, rendered Zsh/Bash syntax, ShellCheck, chezmoi template and
manifest validation, secret and machine-path scan, a Portuguese-text language
audit, a trailing-whitespace check, and an isolated `chezmoi apply` per platform.

## License

[MIT](LICENSE).
