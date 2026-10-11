# AI tools

The `ai` module installs AI desktop apps and terminal coding agents. Agents stay
in the terminal; no editor AI plugins are configured (the VS Code Claude Code
extension is part of the [VS Code module](vscode.md)).

## Included

| Tool | Source | Updates |
| --- | --- | --- |
| Claude Desktop | `cask "claude"` (`brew/ai.Brewfile`) | the app updates itself |
| ChatGPT desktop (includes Codex) | `cask "chatgpt"` | the app updates itself |
| OpenCode | `brew "opencode"` | `brew upgrade opencode` |
| Claude Code CLI (`claude`) | official installer, `https://claude.ai/install.sh` | the native install updates itself |
| Codex CLI (`codex`) | official installer, `https://chatgpt.com/codex/install.sh` | rerun the installer (see vendor docs) |
| Kimi Code CLI (`kimi`) | official installer, `https://code.kimi.com/kimi-code/install.sh` | the installer ships its own updater (see vendor docs) |

OpenAI folded the standalone Codex app into the ChatGPT desktop app, so the
deprecated `codex-app` cask is not used. Kimi Code is Moonshot's current
terminal agent; the older `kimi-cli` package is a different product and is not
installed.

## Install

```sh
cd ~/.local/share/chezmoi
./setup ai
```

This installs the bundle, then runs `scripts/macos/install-ai-clis.sh`, which:

- skips any CLI whose command is already available, from any install method;
- downloads each official installer to a temporary file before running it;
- keeps the installers from editing shell startup files: it puts
  `~/.local/bin` and `~/.kimi-code/bin` on PATH for its own run, and reverts
  any edit to `~/.zshrc`, `~/.zprofile`, `~/.zshenv` or the bash files;
- reports installed, skipped and failed CLIs and exits non-zero on any failure.

Rerun `scripts/macos/install-ai-clis.sh` (or `./setup ai`) to retry a failed
CLI; installed ones are skipped. `ai` is software only, so
`./setup --packages-only ai` is equivalent.

The CLIs live in `~/.local/bin` (Claude Code, Codex) and `~/.kimi-code/bin`
(Kimi Code). The [shell module](shell-and-terminal.md) puts both on PATH; with
your own shell, add them yourself
([entries](setup.md#using-modules-with-your-own-shell)).

## Manual steps

- **Kimi desktop app**: download it from
  <https://www.kimi.com/en/products/download>. The `kimi` cask is not used
  because it could not be verified as the same build.
- **Optional Claude Code settings**: `scripts/macos/setup-claude-config.sh`
  adds missing theme, TUI and iTerm2 status-hook settings to
  `~/.claude/settings.json` without overwriting existing values.

## Authentication

Sign in interactively: open each desktop app, and run `claude`, `codex`,
`kimi` and `opencode` once to follow their login prompts. No tokens or account
data are read, written or stored by this repository.

## MCP servers

Custom MCP servers live in their own repositories. Each repository owns its
installation, credentials and the instructions for registering it with an
agent. This repository installs no MCP servers and stores no MCP configuration.

## Limitations

- The installer tests replace vendor downloads with local stand-ins for the
  failure cases; real installs depend on the vendors' current installers and
  network availability.
- A CLI installed through another method (for example Homebrew or npm) counts
  as installed and is left alone.

## Troubleshooting

- `failed: Kimi Code` with a curl error: a network problem reaching
  `code.kimi.com`; rerun `scripts/macos/install-ai-clis.sh`.
- `installer edited ~/.zshrc; restored it`: expected and harmless; setup never
  edits shell files, so add the PATH entries above yourself if you do not use
  the shell module.
