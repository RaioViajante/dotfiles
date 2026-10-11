# Setup and modules

The `setup` command installs and applies explicitly selected modules. Nothing is
installed unless you name a module, and `chezmoi apply` on its own only applies
dotfiles; it never installs packages.

## Prerequisites

- An Apple Silicon Mac (paths assume Homebrew at `/opt/homebrew`).
- The Xcode Command Line Tools: `xcode-select --install`. `setup` stops with
  this hint when they are missing and a module needs packages.
- An administrator account: the Homebrew installer and some casks (`.pkg`
  installers such as Google Drive or Docker Desktop's helper) ask for your
  password.
- Homebrew is installed by `setup` with the official installer if it is
  missing.

## Get the repository

```sh
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init RaioViajante
cd ~/.local/share/chezmoi
./setup --help
```

`chezmoi init` only clones the repository to `~/.local/share/chezmoi`. All
commands below run from that directory.

## Modules

| Module | Kind | Software (bundles in `brew/`) | Software steps | Managed files | Configuration steps |
| --- | --- | --- | --- | --- | --- |
| `apps` | install | `apps.Brewfile` | none | none | none |
| `dev` | install | `shared/node`, `dev.Brewfile` | `scripts/macos/setup-rust.sh` | none | none |
| `ai` | install | `ai.Brewfile` | `scripts/macos/install-ai-clis.sh` | none | none |
| `content` | install | `content.Brewfile` | none | none | none |
| `shell` | configuration | `shared/ripgrep`, `shared/nerd-font`, `shell.Brewfile` | none | `~/.zprofile`, `~/.zshrc`, `~/.config/zsh`, `~/.config/starship.toml`, iTerm2 Dynamic Profile | `scripts/macos/set-iterm-default-profile.sh` |
| `git` | configuration | none | none | `~/.gitconfig`, `~/.config/git` | none |
| `vscode` | configuration | `shared/nerd-font`, `vscode.Brewfile` | `scripts/macos/install-vscode-extensions.sh` | VS Code `settings.json` | none |
| `nvim` | configuration | `shared/ripgrep`, `shared/node`, `shared/nerd-font`, `nvim.Brewfile` | none | `~/.config/nvim` | none |

Applying configuration in the default mode also installs `shared/chezmoi`.
`./setup --list` prints the same mapping from the script itself. Editors and
the terminal belong to their configuration modules: `dev` does not install VS
Code, Neovim or iTerm2.

Module documentation: [desktop apps](apps.md), [development tools and
Rust](development.md), [AI tools](ai.md), [content creation](content-creation.md),
[shell and terminal](shell-and-terminal.md), [Git and GitHub accounts](git.md),
[VS Code](vscode.md), [Neovim](neovim.md).

## Modes

| Mode | Software (packages, Rust toolchain, AI CLIs, VS Code extensions) | Managed files, Git includes, iTerm2 default |
| --- | --- | --- |
| default | installed for the selected modules | applied for the selected configuration modules |
| `--packages-only` | installed for the selected modules | never written |
| `--no-packages` | never installed | applied for the selected configuration modules |

`--packages-only` and `--no-packages` cannot be combined. Modules with nothing
to do in the chosen mode are listed as skipped (for example `git` has no
software, and `apps` has no configuration); a selection with nothing to do at
all fails. `--packages-only` leaves existing shell files untouched; the AI CLI
step also reverts any edit a vendor installer makes to them.

## Commands

| Goal | Command |
| --- | --- |
| Software of one module | `./setup dev` (install modules have no configuration) |
| Software of a configuration module, no settings | `./setup --packages-only vscode` |
| Software of several modules | `./setup --packages-only apps dev ai content` |
| All software, no configuration | `./setup --packages-only all` |
| Configuration of one module | `./setup --no-packages shell` |
| Configuration of several modules | `./setup --no-packages shell git vscode nvim` |
| All configuration, no software | `./setup --no-packages all` (skips apps, dev, ai and content) |
| Software and configuration of one module | `./setup nvim` |
| Install and configuration modules together | `./setup dev vscode nvim` |
| Complete setup | `./setup all` |
| Preview any of the above | `./setup --dry-run --packages-only all` |
| List modules | `./setup --list` |

`./setup` without a module prints the help and exits with status 2.

## How it works

1. **Plan.** `setup` prints the mode, the modules that install software, the
   modules that apply configuration and every skipped module. `--dry-run`
   stops after printing each package and step it would run.
2. **Software.** Package membership lives only in `brew/*.Brewfile`; each
   package belongs to one bundle. Packages used by several modules (`chezmoi`,
   `ripgrep`, `node@24`, the JetBrains Mono Nerd Font) live in `brew/shared/`
   and are included once, only when a selected module needs them. `setup`
   concatenates the bundles and runs `brew bundle install --no-upgrade`:
   missing packages are installed, installed ones are not upgraded, and nothing
   is removed. Then the software steps run: Rust toolchain (`dev`), AI CLIs
   (`ai`), VS Code extensions (`vscode`).
3. **Configuration.** `chezmoi apply --parent-dirs <targets>` applies only the
   selected modules' files from this checkout, then the configuration steps
   run (the iTerm2 default profile for `shell`).
4. **Summary.** Each module prints its manual follow-ups. Failures are listed
   and the command exits non-zero; earlier successful parts are kept.

`setup` finds Homebrew from `$HOMEBREW_PREFIX`, `brew` itself or
`/opt/homebrew`, and puts it on PATH for its own process only; it never edits
shell startup files. The root `Brewfile` composes every bundle, so
`brew bundle --file=Brewfile` still installs the complete package set and
`brew bundle check --file=Brewfile` reports what is missing (it does not run
the software steps).

## Using modules with your own shell

Every module works without the `shell` module: the setup scripts resolve their
tools themselves, VS Code settings use absolute paths, and Neovim adds the
toolchains it needs to its own environment. To use the tools from your own
interactive shell, add the entries for the modules you installed, for example
to `~/.zprofile`:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"                   # Homebrew
export PATH="$HOMEBREW_PREFIX/opt/node@24/bin:$PATH"        # dev, nvim: keg-only Node
export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$HOME/.cargo/bin:$PATH"  # dev: rustup proxies, cargo install
export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"  # dev: Java 25
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$HOME/.kimi-code/bin:$PATH"   # ai: Claude Code, Codex, Kimi Code
```

The managed `shell` module sets the same entries in `~/.config/zsh/paths.zsh`.

## Reruns and updates

Reruns are safe: installed packages, toolchains, extensions and AI CLIs are
skipped, and chezmoi rewrites only files that differ. To pick up repository
changes:

```sh
chezmoi update                  # pull and apply all managed files (no packages)
./setup dev                     # install packages added to a module since
```

Upgrades stay manual (`brew upgrade`, `rustup update`); the vendor-installed AI
CLIs follow their own update mechanisms ([AI tools](ai.md)).

## Customize or omit components

- Remove or add a package in its `brew/*.Brewfile`; CI rejects a package listed
  in two bundles.
- Skip packages for one run without editing a bundle:

  ```sh
  HOMEBREW_BUNDLE_CASK_SKIP="spotify whatsapp" ./setup apps
  HOMEBREW_BUNDLE_BREW_SKIP="mysql" ./setup dev
  ```

- Leave a configuration module out by not selecting it; each module only
  touches its own files. A new managed file must be added to a module in
  `setup` (`module_targets`); CI fails when a managed file has no module.

## Authentication

`setup` never signs in to anything. Apps, the App Store, GitHub and the AI
tools are signed in by hand; see each module's documentation.

## Troubleshooting

- **"Command Line Tools not found"**: run `xcode-select --install`, then rerun.
- **`brew bundle` errors**: the summary names the bundles; rerun after fixing
  the cause (network, a cask asking for a password, Gatekeeper approval).
- **`chezmoi: warning: config file template has changed`**: run `chezmoi init`
  once; it asks no questions.
- **Which files would change?** `chezmoi diff` before `./setup`.

## Repository layout and checks

```text
.
├── setup                 # modular install and configuration command
├── Brewfile              # composes brew/*.Brewfile
├── brew/                 # package bundles per module (shared/ for common ones)
├── manifests/            # Mac App Store apps and VS Code extensions
├── docs/                 # documentation per module
├── dot_gitconfig, dot_zprofile, dot_zshrc
├── dot_config/           # git, nvim, starship.toml, zsh
├── private_Library/      # VS Code settings and iTerm2 Dynamic Profile
├── scripts/              # check-*.sh, lib.sh, macos/ setup steps and helpers
└── .github/              # CI workflow and README assets
```

chezmoi applies files prefixed `dot_` under `$HOME` and maps `private_Library/`
to `~/Library/`. `README.md`, `setup`, `Brewfile`, `brew/`, `docs/`,
`manifests/`, `scripts/` and `.github/` stay in the source directory through
`.chezmoiignore`.

`.gitignore` excludes local SSH keys, credential files and per-machine Git
overrides; shell history and application data are outside the managed source.
Before committing, run:

```sh
./scripts/check-secrets.sh
./scripts/check-modules.sh
./scripts/check-docs.sh
git diff --check
```

`.github/workflows/validate.yml` runs these and more on macOS: structure, Zsh
and Bash syntax, ShellCheck, chezmoi rendering and a repeated isolated apply,
manifests, setup modules and modes, documentation links and commands, the
iTerm2 profile, secret patterns, language and whitespace.
