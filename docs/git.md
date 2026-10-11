# Git and GitHub accounts

The `git` configuration module applies Git settings and the includes for your
commit identities. No identity is versioned: names and email addresses live
only in untracked files you create. The module installs no software of its own
(`chezmoi` is installed when configuration is applied); Git itself comes from
the Command Line Tools and the GitHub CLI (`gh`) from the
[dev module](development.md). Applying it needs no sign-in and no SSH keys.

## Included

- `~/.gitconfig`: defaults (main branch, fast-forward pulls, histogram diffs,
  zdiff3 conflicts, aliases), `user.useConfigOnly = true` (Git refuses to
  commit rather than guess an identity) and the identity includes below.
- `~/.config/git/ignore`: global ignores (`.DS_Store`, `.env` files, local
  Claude settings).
- `~/.config/git/identity.gitconfig`: your default identity. Created once
  with instructions in comments (mode 600), never overwritten or committed.
- `~/.config/git/local.gitconfig`: created the same way and included last, so
  its values win everywhere; use it for per-machine settings such as
  credential helpers or signing keys.

## Apply

```sh
cd ~/.local/share/chezmoi
./setup git                     # installs chezmoi if missing, then applies
./setup --no-packages git       # applies only (chezmoi must be installed)
```

Existing identity and local files are kept as they are on every apply.

## Commit identity versus SSH authentication

Two separate mechanisms are involved:

- **Commit identity** (`user.name`, `user.email`) comes from untracked files,
  read in this order (later wins):
  1. `~/.config/git/identity.gitconfig`: the default for every repository;
  2. `~/.gitconfig-personal` for repositories under `~/Developer/personal/`, or
     `~/.gitconfig-college` under `~/Developer/college/`;
  3. `~/.config/git/local.gitconfig`: per-machine overrides.

  A missing file is skipped. With no identity at all, `git commit` stops with
  "Author identity unknown" instead of inventing one.
- **SSH authentication** decides which GitHub account a push or clone uses. It
  is chosen by the remote's host alias in `~/.ssh/config`.

### Identity files (manual)

Set the default identity, for example a GitHub noreply address:

```sh
git config --file ~/.config/git/identity.gitconfig user.name "NAME"
git config --file ~/.config/git/identity.gitconfig user.email "EMAIL"
```

Create the per-account files by hand; they hold only a `[user]` section and
are never committed:

```sh
git config --file ~/.gitconfig-personal user.name "PERSONAL_NAME"
git config --file ~/.gitconfig-personal user.email "PERSONAL_EMAIL"
git config --file ~/.gitconfig-college user.name "COLLEGE_NAME"
git config --file ~/.gitconfig-college user.email "COLLEGE_EMAIL"
chmod 600 ~/.gitconfig-personal ~/.gitconfig-college
```

Inside a repository, `git config user.email` shows the identity in effect. Git
skips an include whose file is missing.

### SSH keys and host aliases (manual)

Each account has its own key. Private keys stay on the machine that created
them. Create a key only if it does not exist yet:

```sh
[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -C "personal $(hostname -s)"
[[ -f ~/.ssh/id_ed25519_github_college ]] || ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_github_college -C "college $(hostname -s)"
```

`~/.ssh/config` is local and not managed here. It defines one alias per
account; `IdentitiesOnly yes` makes each alias offer only its own key:

```sshconfig
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes

Host github-college
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_college
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
```

Register each public key on its own account, in GitHub's web settings
(Settings > SSH and GPG keys) or with `gh`, which uploads to the active
account:

```sh
gh auth login --hostname github.com --web --git-protocol ssh --scopes admin:public_key
gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication --title "$(hostname -s)"
```

For the second account, sign in again, add its key, then switch back:

```sh
gh auth login --hostname github.com --web --git-protocol ssh --scopes admin:public_key
gh ssh-key add ~/.ssh/id_ed25519_github_college.pub --type authentication --title "$(hostname -s)"
gh auth switch --hostname github.com --user PERSONAL_GITHUB_USERNAME
```

Test each alias separately. GitHub closes the connection with exit status 1
even after a successful login, so read the message: it must say
`Hi <username>! You've successfully authenticated, but GitHub does not provide
shell access.` with the matching account.

```sh
ssh -T github-personal
```

```sh
ssh -T github-college
```

Clone through the alias that matches the account, into the matching directory:

```sh
git clone github-personal:OWNER/REPO.git ~/Developer/personal/REPO
git clone github-college:OWNER/REPO.git ~/Developer/college/REPO
```

A plain `git@github.com:` remote uses the default key (`~/.ssh/id_ed25519`, the
personal account). Existing remotes do not need rewriting unless they must
authenticate as the other account.

## Credential helpers

HTTPS remotes can use the GitHub CLI as a credential helper. `gh auth setup-git`
writes it to `~/.gitconfig`, which chezmoi manages, so keep it in the local
file instead:

```sh
git config --file ~/.config/git/local.gitconfig --add credential.https://github.com.helper ""
git config --file ~/.config/git/local.gitconfig --add credential.https://github.com.helper "!$(command -v gh) auth git-credential"
```

The empty first value resets helpers inherited from system configuration.
SSH remotes do not use credential helpers.

## Authentication

`gh auth login` and the SSH key registration are interactive and stay manual.
Tokens, keys and the identity files never enter this repository.

## Troubleshooting

- `git config user.email` shows the default identity in a college repository:
  check that the repository is under `~/Developer/college/` and that
  `~/.gitconfig-college` exists. An email set in `local.gitconfig` overrides
  every identity file.
- `Author identity unknown`: no identity file applies to this repository; set
  one as shown above.
- `Permission denied (publickey)`: the remote uses the wrong alias or the key
  is not registered on that account; compare with `ssh -T github-college`.
