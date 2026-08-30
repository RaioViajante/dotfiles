# macOS dotfiles

An explicit, fast, and reproducible macOS development environment. This repository uses chezmoi to manage Zsh, Git, Starship, and tool bootstrapping without large shell frameworks or stored credentials.

## Tools

- macOS, Zsh, and Homebrew
- chezmoi, Git, and GitHub CLI
- Starship, zoxide, fzf, eza, bat, and ripgrep
- Node.js 24, pnpm, and Angular CLI
- Java 21 LTS and Maven
- Docker, Podman, VS Code, and IntelliJ IDEA

Angular CLI and Codex CLI are currently global npm packages and are not installed automatically by the Brewfile. Podman is also excluded from the Brewfile because the current installation did not come from Homebrew.

## Structure

```text
.
├── Brewfile
├── dot_zshrc
├── dot_zprofile
├── dot_gitconfig
├── dot_config/
│   ├── git/ignore
│   ├── starship.toml
│   └── zsh/
│       ├── aliases.zsh
│       ├── completion.zsh
│       ├── dev.zsh
│       ├── functions.zsh
│       ├── options.zsh
│       ├── paths.zsh
│       └── tools.zsh
├── run_once_before_10-install-homebrew.sh.tmpl
├── run_onchange_before_20-brew-bundle.sh.tmpl
├── run_onchange_after_30-local-setup.sh.tmpl
└── scripts/
    ├── check-secrets.sh
    └── macos-defaults.sh
```

Files prefixed with `dot_` are applied to the home directory by chezmoi. `README.md`, `Brewfile`, and `scripts/` remain in the source state through `.chezmoiignore`.

## Automated validation

The `.github/workflows/validate.yml` workflow runs on macOS for every push and pull request. It checks the required structure, Bash/Zsh/Git/Brewfile syntax, secrets, machine-specific paths, and an isolated chezmoi application in a temporary directory.

## Requirements

- A Mac with internet access
- A user allowed to install Homebrew
- Xcode Command Line Tools when requested by the Homebrew installer
- A GitHub account for cloning the repository and configuring Git/SSH

## Installing on a new Mac

The standalone chezmoi installer lets you start without Homebrew:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply RaioViajante
```

If chezmoi is already installed:

```sh
chezmoi init --apply RaioViajante
```

During the first apply, the scripts:

1. install Homebrew when it is missing;
2. apply the Brewfile;
3. apply the dotfiles;
4. create local directories and an empty `local.gitconfig` when needed.

## Local Git identity

The versioned `dot_gitconfig` contains only portable Git behavior. Configure your name and email on each machine in `~/.config/git/local.gitconfig`:

```gitconfig
[user]
    name = YOUR_NAME
    email = YOUR_VERIFIED_OR_NOREPLY_EMAIL
```

Confirm where the identity comes from:

```sh
git config --global --includes --show-origin --get-regexp '^user\.'
```

`~/.config/git/local.gitconfig` is never copied into the source state and must never be committed.

## GitHub CLI and per-machine SSH setup

Authentication and SSH keys are not restored by these dotfiles. On each Mac, sign in through the browser:

```sh
gh auth login --hostname github.com --web --git-protocol ssh --skip-ssh-key
gh auth status
```

If the machine does not have a dedicated key yet, create one with a passphrase and register only its public key:

```sh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_raioviajante
gh ssh-key add ~/.ssh/id_ed25519_raioviajante.pub --type authentication --title "macOS development"
```

Create `~/.ssh/config` locally and set its permissions to `600`:

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_raioviajante
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
```

Validate it with `ssh -T git@github.com`. The SSH config, public/private keys, and GitHub CLI keyring are intentionally excluded from this repository.

To restore the global npm CLIs used in this environment after Node becomes available:

```sh
npm install --global @angular/cli @openai/codex
```

## Using chezmoi

Review and apply incoming changes:

```sh
chezmoi diff
chezmoi apply
chezmoi update
```

`chezmoi update` updates the source repository and applies its changes. To apply configuration without running the Brewfile during that cycle:

```sh
DOTFILES_SKIP_BREW_BUNDLE=1 chezmoi apply
```

Edit a managed configuration:

```sh
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

Add a new configuration:

```sh
chezmoi add ~/.config/tool/config
chezmoi cd
./scripts/check-secrets.sh
git diff --check
```

Never add entire directories such as `.ssh`, `.docker`, `.codex`, or `.config/gh`.

## Brewfile behavior

The Brewfile contains only direct tools and useful applications for restoring the environment. Homebrew resolves their transitive dependencies. The `run_onchange_before_20-brew-bundle.sh.tmpl` script runs `brew bundle` again only when the Brewfile content changes.

Check the Brewfile without installing anything:

```sh
brew bundle check --file="$(chezmoi source-path)/Brewfile"
```

## Secrets policy

The following are never managed or copied into the source state:

- private or public SSH keys;
- GitHub CLI tokens and credentials;
- `.env` files and API keys;
- Codex, Docker, and GitHub CLI authentication files;
- the local Git identity;
- cookies, histories, caches, and keyrings.

`.gitignore` and `.chezmoiignore` are only additional safeguards. Run these checks before every commit:

```sh
./scripts/check-secrets.sh
git diff --check
git status --short
```

## macOS defaults

The defaults are conservative and opt-in:

```sh
./scripts/macos-defaults.sh
```

The script shows file extensions and Finder path/status bars, expands dialogs, and prevents `.DS_Store` files on external volumes. It does not change appearance, wallpaper, or security settings.

## Reverting or unmanaging a file

Review changes with `chezmoi diff` first. To discard an unapplied edit, restore the file in the Git repository. To stop managing a file without deleting it from the home directory:

```sh
chezmoi forget PATH
```

Review the diff before committing or applying changes.
