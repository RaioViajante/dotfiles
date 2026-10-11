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

| Module | Kind | Packages (bundles in `brew/`) | Managed files | Automatic steps |
| --- | --- | --- | --- | --- |
| `apps` | install | `apps.Brewfile` | none | none |
| `dev` | install | `shared/node.Brewfile`, `dev.Brewfile` | none | `scripts/macos/setup-rust.sh` |
| `ai` | install | `ai.Brewfile` | none | `scripts/macos/install-ai-clis.sh` |
| `content` | install | `content.Brewfile` | none | none |
| `shell` | configuration | `shared/chezmoi`, `shared/ripgrep`, `shared/nerd-font`, `shell.Brewfile` | `~/.zprofile`, `~/.zshrc`, `~/.config/zsh`, `~/.config/starship.toml`, iTerm2 Dynamic Profile | `scripts/macos/set-iterm-default-profile.sh` (after the files) |
| `git` | configuration | `shared/chezmoi` | `~/.gitconfig`, `~/.config/git` | none |
| `vscode` | configuration | `shared/chezmoi`, `shared/nerd-font`, `vscode.Brewfile` | VS Code `settings.json` | `scripts/macos/install-vscode-extensions.sh` |
| `nvim` | configuration | `shared/chezmoi`, `shared/ripgrep`, `shared/node`, `shared/nerd-font`, `nvim.Brewfile` | `~/.config/nvim` | none |

`./setup --list` prints the same mapping from the script itself. Editors and
the terminal are installed by their configuration modules: `dev` does not
install VS Code, Neovim or iTerm2.

Module documentation: [desktop apps](apps.md), [development tools and
Rust](development.md), [AI tools](ai.md), [content creation](content-creation.md),
[shell and terminal](shell-and-terminal.md), [Git and GitHub accounts](git.md),
[VS Code](vscode.md), [Neovim](neovim.md).

## Commands

```sh
./setup dev                     # one install module
./setup shell git               # configuration modules, with their packages
./setup --no-packages nvim      # configuration only: no packages, no extensions
./setup apps ai content         # several install modules
./setup dev vscode nvim         # install and configuration modules together
./setup all                     # complete setup: every module
./setup --dry-run all           # show what would run, change nothing
./setup --list                  # modules, bundles, managed files and steps
```

`./setup` without a module prints the help and exits with status 2.

## How it works

1. **Packages.** Package membership lives only in `brew/*.Brewfile`; each
   package belongs to one bundle. Packages needed by several modules
   (`chezmoi`, `ripgrep`, `node@24`, the JetBrains Mono Nerd Font) live in
   `brew/shared/` and are included
   once, only for modules that need them. `setup` concatenates the selected
   bundles and runs `brew bundle install --no-upgrade`: missing packages are
   installed, installed ones are not upgraded, and nothing is removed.
2. **Steps after packages**: Rust toolchain (`dev`), AI CLIs (`ai`), VS Code
   extensions (`vscode`). They are skipped with `--no-packages`.
3. **Configuration.** `chezmoi apply --parent-dirs <targets>` applies only the
   selected modules' files from this checkout.
4. **Steps after configuration**: the iTerm2 default profile (`shell`).
5. **Summary.** Each module prints its manual follow-ups. Failures are listed
   and the command exits non-zero; earlier successful parts are kept.

The root `Brewfile` composes every bundle, so `brew bundle --file=Brewfile`
still installs the complete package set, and
`brew bundle check --file=Brewfile` reports what is missing.

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
