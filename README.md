# dotfiles

Personal development environment for **Apple Silicon macOS**, managed with
[chezmoi](https://chezmoi.io). The repository contains shell, Git, prompt,
editor and terminal configuration, a Homebrew package list, and setup scripts.
Credentials and machine state stay local.

## Setup

Install the Xcode Command Line Tools (`xcode-select --install`) if they are
missing. The standalone chezmoi installer works before Homebrew is available:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply RaioViajante
```

The first apply installs Homebrew if needed, runs `brew bundle` for the formulae
and casks in `Brewfile`, installs extensions from
`manifests/vscode-extensions.txt`, applies the dotfiles, and creates local
configuration directories. `dot_gitconfig` supplies a public GitHub noreply
identity; optional per-machine overrides live in the untracked
`~/.config/git/local.gitconfig`.

Register the Homebrew JDKs once so `java_home`, VS Code and IntelliJ can find
them (requires an administrator password):

```sh
"$(chezmoi source-path)/scripts/macos/register-jdks.sh"
```

Verify the applied state:

```sh
chezmoi diff
brew bundle check --file="$(chezmoi source-path)/Brewfile"
```

## Managed configuration

- `Brewfile` installs CLI tools, language runtimes, editors and desktop apps.
  Node 24 and pnpm come from Homebrew; Java 25 is the shell default, with Java
  21 available through the `jdk` function. Homebrew Python is the default;
  `uv` and `pyenv` are available for project-specific versions.
- `dot_zprofile`, `dot_zshrc` and `dot_config/zsh/` set Homebrew paths, shell
  options, completion, aliases and helpers. `tools.zsh` integrates Starship,
  zoxide and other installed tools; `completion.zsh` loads fzf bindings.
- `dot_gitconfig` sets Git behavior and a GitHub noreply identity.
  GitHub authentication uses a local SSH key, created manually below.
- `dot_config/nvim/` contains the modular Neovim configuration and pinned
  plugin lockfile. VS Code user settings and the extension manifest cover the
  GUI editor. VS Code remains the primary editor; Neovim is the terminal editor
  and `EDITOR` fallback when `code` is absent.
- `dot_config/starship.toml` configures the prompt. The iTerm2 Dynamic Profile
  under `private_Library/` configures the terminal. Both are applied by chezmoi.
- `scripts/macos/` contains optional macOS preference, startup and service
  helpers. The `run_*` templates handle Homebrew and post-apply setup.

`README.md`, `Brewfile`, `manifests/`, `scripts/` and `.github/` stay in the
chezmoi source directory through `.chezmoiignore`. Files prefixed `dot_` are
applied under `$HOME`; `private_Library/` maps to `~/Library/`.

## Repository layout

```text
.
├── .chezmoi.toml.tmpl, .chezmoiignore
├── Brewfile
├── dot_gitconfig, dot_zprofile, dot_zshrc
├── dot_config/
│   ├── nvim/                  # Neovim modules and plugin lockfile
│   ├── starship.toml          # prompt
│   └── zsh/                   # paths, completion, aliases, tools, JDK helper
├── private_Library/          # VS Code settings and iTerm2 Dynamic Profile
├── manifests/                # Mac App Store apps and VS Code extensions
├── scripts/
│   ├── check-secrets.sh, lib.sh
│   └── macos/                # optional setup helpers
└── run_*.sh.tmpl             # Homebrew and post-apply hooks
```

## Updating

```sh
chezmoi update          # pull and apply the latest source
chezmoi diff            # inspect pending changes
chezmoi apply           # apply local source changes
```

To apply configuration without re-running `brew bundle` or the VS Code
extension installer:

```sh
DOTFILES_SKIP_BREW_BUNDLE=1 chezmoi apply
```

After changing `.chezmoi.toml.tmpl`, run `chezmoi init` once to refresh the
chezmoi configuration. It asks no questions.

## Editor setup

Neovim uses [lazy.nvim](https://github.com/folke/lazy.nvim). On first launch,
run `nvim`, let plugins install, then restart so the installed language servers
attach. `:checkhealth` reports any remaining issues. Mason installs the
configured language servers and formatters; `lazy-lock.json` pins plugins.
After `:Lazy update`, record the lockfile with
`chezmoi re-add ~/.config/nvim/lazy-lock.json` before committing.

The iTerm2 profile is written to
`~/Library/Application Support/iTerm2/DynamicProfiles/raioviajante.json`.
iTerm2 loads it automatically; set it as the default in Settings → Profiles
once. VS Code settings live in
`~/Library/Application Support/Code/User/settings.json`.

## Manual steps

- Sign in to GitHub and apps separately. SSH keys, tokens, browser profiles,
  Docker data and app credentials are never copied into this repository.
- Create one GitHub SSH key per Mac and register its public half:

  ```sh
  ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_github
  gh auth login --hostname github.com --web --git-protocol ssh
  ```

  If `gh auth login` did not upload the public key, run
  `gh ssh-key add ~/.ssh/id_ed25519_github.pub --type authentication --title "$(hostname)"`.

- Set zsh as the login shell with `chsh -s "$(command -v zsh)"`, then log out
  and back in.
- Run `"$(chezmoi source-path)/scripts/macos/macos-defaults.sh"` for
  conservative file-handling defaults and
  `"$(chezmoi source-path)/scripts/macos/apply-preferences.sh"` for the
  optional appearance, Dock and Finder setup. The latter is kept outside
  `chezmoi apply` so routine updates do not rearrange the Dock.
- Run `"$(chezmoi source-path)/scripts/macos/setup-startup.sh"` for the
  configured Login Items and Homebrew MySQL service. Mac App Store apps require
  an Apple ID sign-in, then
  `"$(chezmoi source-path)/scripts/macos/install-mas-apps.sh"`.
- `scripts/macos/setup-claude-config.sh` merges the configured Claude Code
  settings. `scripts/macos/setup-proton-mcp.sh` registers the separately managed
  Proton Mail MCP server when its prerequisites are present. Neither stores
  credentials in this repository.
- Docker Desktop and the desktop apps in `Brewfile` still require their own
  first launch and sign-in. The macOS wallpaper and peripheral software are not
  managed here.

## Security and validation

`.gitignore` excludes local SSH keys, credential files and per-machine Git
overrides. Shell history and application data are outside the managed source.
The versioned Git identity is a public GitHub noreply address. Before
committing, run:

```sh
./scripts/check-secrets.sh
git diff --check
git status --short
```

`.github/workflows/validate.yml` checks the repository on macOS: structure,
Zsh and Bash syntax, ShellCheck, chezmoi rendering and an isolated repeated
apply, manifests, iTerm2 JSON, secret patterns, language and whitespace.

## License

[MIT](LICENSE).
