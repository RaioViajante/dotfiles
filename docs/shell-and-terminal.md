# Shell and terminal

The `shell` configuration module installs the terminal tools and applies the
zsh, Starship and iTerm2 configuration.

## Included

- **Packages**: `starship`, `zoxide`, `fzf`, `eza`, `bat` and iTerm2
  (`brew/shell.Brewfile`), plus the shared `ripgrep`, `chezmoi` and JetBrains
  Mono Nerd Font (`brew/shared/nerd-font.Brewfile`, also used by the vscode
  and nvim modules).
- **Managed files**:
  - `~/.zprofile`: Homebrew environment for login shells.
  - `~/.zshrc` and `~/.config/zsh/`: options, PATH, completion, aliases,
    functions, editor variables and tool initialisation.
  - `~/.config/starship.toml`: the prompt (ASCII symbols, no Nerd Font needed).
  - `~/Library/Application Support/iTerm2/DynamicProfiles/raioviajante.json`:
    the iTerm2 profile (JetBrainsMono Nerd Font Mono 14).
- **Step**: `scripts/macos/set-iterm-default-profile.sh` makes that profile the
  iTerm2 default.

## Install and apply

```sh
cd ~/.local/share/chezmoi
./setup shell                   # packages, files and the default profile
./setup --packages-only shell   # tools, iTerm2 and font; shell files untouched
./setup --no-packages shell     # files and the default profile only
```

`~/.zshrc` also loads `~/.config/studio/studio.zsh` when the optional
[studio module](studio.md) has been applied; without it nothing changes. This
hook is owned by this module, so re-applying it
(`./setup --no-packages shell studio`) is what activates the studio shortcuts on
a machine configured before that module existed.

Set zsh as the login shell if it is not already (`chsh -s /bin/zsh`), then open
a new terminal.

## PATH

`~/.config/zsh/paths.zsh` adds, when present: `~/.local/bin` (Claude Code,
Codex), `~/.kimi-code/bin`, Docker Desktop's `~/.docker/bin`, the VS Code
`code` command, Homebrew MySQL, keg-only `node@24`, the keg-only `rustup` bin
and `~/.cargo/bin`, and the Homebrew JDK (Java 25 by default). Each entry is
guarded, so missing tools are skipped. Tool installers are kept from adding
their own PATH lines (see [AI tools](ai.md)).

The other modules do not need this module. If you keep your own shell
configuration, add the entries listed in
[Using modules with your own shell](setup.md#using-modules-with-your-own-shell)
and skip `./setup shell` (or install only its tools with
`./setup --packages-only shell`).

## iTerm2 default profile

The script reads the profile GUID from the managed Dynamic Profile and writes
only iTerm2's `Default Bookmark Guid` preference; other profiles and
preferences stay as they are. It does nothing when the default is already set,
and skips iTerm2 setups that load preferences from a custom folder (set the
default in iTerm2 > Settings > Profiles there). Restart iTerm2 for new windows
to use the profile.

## Customize

- Shell behaviour: edit the files under `dot_config/zsh/` in the repository,
  then `chezmoi apply ~/.config/zsh` (or `./setup --no-packages shell`).
- Per-machine shell tweaks that should not be committed belong outside the
  managed files; chezmoi overwrites local edits to managed files on apply.
- Font: change `Normal Font` in the Dynamic Profile JSON (a PostScript name
  such as `JetBrainsMonoNFM-Regular 14`).

## Limitations and troubleshooting

- Glyphs show as boxes: the Nerd Font is missing; rerun `./setup shell`.
- Dynamic Profiles reload automatically, but iTerm2 only picks up a new default
  profile after a restart. Changing the profile in iTerm2's settings does not
  write back to the managed JSON.
- Startup time: `time zsh -i -c exit` should stay well under a second; tool
  initialisation is limited to Starship and zoxide.
