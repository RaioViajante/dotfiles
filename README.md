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
├── private_Library/.../Code/User/settings.json # VS Code settings (macOS only)
├── manifests/
│   ├── fedora-packages.txt         # curated dnf packages
│   └── vscode-extensions.txt       # curated VS Code extensions
├── scripts/
│   ├── lib.sh                      # shared bash helpers
│   ├── check-secrets.sh            # pre-commit secret scan
│   ├── macos/
│   │   ├── apply-preferences.sh    # opt-in Dock + Finder personalization (dockutil)
│   │   ├── macos-defaults.sh       # opt-in macOS file-handling defaults
│   │   └── register-jdks.sh        # symlink Homebrew JDKs into /Library/Java
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
Starship, zoxide, Git behaviour and identity (noreply email), editor conventions.

**macOS-specific:** Homebrew (`Brewfile` packages + `vscode` extensions,
`dot_zprofile`, brew run scripts), `openjdk@25` `JAVA_HOME` with the `jdk()`
`java_home` switcher, VS Code app-bundle `PATH`, the macOS VS Code
`settings.json` (`java.configuration.runtimes` + Python interpreter + Material
Icon Theme + Catppuccin Mocha colour theme), `scripts/macos/macos-defaults.sh`,
`scripts/macos/register-jdks.sh`, `scripts/macos/apply-preferences.sh`.

**Fedora-specific:** `manifests/fedora-packages.txt`, everything under
`scripts/fedora/`, fnm + pnpm + SDKMAN shell integration, the Linux VS Code
`settings.json`.

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
  builds the Dock (contents + position bottom / always visible / no-recents /
  minimize-to-app, via `dockutil`; icon size left at the macOS default) and sets
  a few Finder view options. It is idempotent, needs no `sudo`, and is
  intentionally kept out of `chezmoi apply` so a routine update never rearranges
  the Dock.
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
