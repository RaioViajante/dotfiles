# Development tools and Rust

The `dev` module installs language runtimes, databases, developer CLIs and
developer apps from `brew/dev.Brewfile`, plus Node.js from
`brew/shared/node.Brewfile`, and sets up Rust. Editors come from their own
modules: [VS Code](vscode.md) and [Neovim](neovim.md).

## Included

| Area | Packages |
| --- | --- |
| GitHub and checks | `gh`, `gitleaks`, `shellcheck`, `htop`, `nmap` |
| JavaScript / TypeScript | `node@24` (shared), `pnpm`, `angular-cli`, `vercel` |
| Java / Spring Boot | `openjdk@21`, `openjdk@25`, `maven` |
| Python | `python@3.14`, `uv` |
| PHP | `php`, `composer` |
| Database | `mysql` |
| Rust | `rustup` (stable toolchain with rustfmt, clippy and rust-analyzer) |
| App Store | `mas` (for Xcode, see below) |
| Apps | Docker Desktop, IntelliJ IDEA, Postman, MySQL Workbench, Firefox Developer Edition |

## Install

```sh
cd ~/.local/share/chezmoi
./setup dev
```

This installs the packages and runs `scripts/macos/setup-rust.sh`. The shell
PATH entries for these tools (keg-only Node and rustup, the JDKs) come from the
[shell module](shell-and-terminal.md).

## Rust

Rust comes from Homebrew's `rustup` formula (keg-only; the rustup book lists
`brew install rustup` as a supported method). `setup-rust.sh`:

- installs the `stable` toolchain with the minimal profile plus `rustfmt`,
  `clippy` and `rust-analyzer`;
- on reruns only adds missing components: it never updates a toolchain and never
  changes an existing default;
- installs no cargo utilities.

rust-analyzer has one source: the rustup component, reached through the
`rust-analyzer` proxy in `$(brew --prefix rustup)/bin`. Neovim enables it from
PATH and VS Code's rust-analyzer extension uses the same proxy; Mason and the
extension's bundled server are not used.

Projects choose their own toolchain with `rust-toolchain.toml` or
`rust-toolchain`; the proxies (`cargo`, `rustc`, `rust-analyzer`) honour them,
also from subdirectories. Install a project's pinned toolchain once from the
project directory:

```sh
rustup toolchain install        # no arguments: the toolchain the project selects
```

rustup 1.29 still installs a missing pinned toolchain on first use but marks
that behaviour as deprecated, so prefer the explicit command. Upgrade the
default toolchain with `rustup update stable` when you want to.

## Java

Java 25 is the shell default and `jdk 21` switches the current shell. Register
the Homebrew JDKs once so `/usr/libexec/java_home`, IntelliJ and VS Code find
them (asks for an administrator password):

```sh
scripts/macos/register-jdks.sh
```

## Python, Node and PHP

- Homebrew Python is the default interpreter; `uv` manages per-project
  environments and Python versions (`.python-version`, `pyproject.toml`).
  pyenv is intentionally not part of the setup.
- Node 24 is keg-only and put on PATH by the shell module; `pnpm` comes from
  Homebrew.

## MySQL

The `mysql` formula runs as a Homebrew service. Start it with
`brew services start mysql` (or the `mysql-start` alias from the shell module,
or `scripts/macos/setup-startup.sh`). No credentials are stored here.

## Xcode (App Store)

Xcode is listed in `manifests/mas-apps.txt`. After signing in to the App Store
with your Apple ID:

```sh
scripts/macos/install-mas-apps.sh
```

The script only downloads apps from your purchase history and skips installed
ones. The Command Line Tools are enough for everything else in this repository.

## Authentication

- GitHub CLI and SSH keys: see [Git and GitHub accounts](git.md).
- Docker Desktop, IntelliJ IDEA and Postman ask for their own sign-in or
  license on first launch. Docker Desktop also installs a privileged helper.

## Customize or omit

Edit `brew/dev.Brewfile`, or skip items for one run:
`HOMEBREW_BUNDLE_CASK_SKIP="intellij-idea" ./setup dev`. Skipping `rustup`
makes the Rust step fail with a clear message; remove that step from
`module_steps` in `setup` if you drop Rust entirely.

## Troubleshooting

- `rustup not found`: rerun `./setup dev`, or check that
  `/opt/homebrew/opt/rustup/bin` is on PATH (open a new terminal).
- A project reports a missing toolchain: run `rustup toolchain install` in the
  project directory.
