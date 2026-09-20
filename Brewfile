# Shell and dotfile management
brew "chezmoi"
brew "starship"
brew "zoxide"
brew "fzf"
brew "eza"
brew "bat"
brew "ripgrep"

# Git and diagnostics
brew "gh"
brew "htop"
brew "nmap"
# Shell linter; also run by CI (.github/workflows/validate.yml).
brew "shellcheck"
# Secret scanner; run over the tree and history before every push.
brew "gitleaks"

# Terminal editor. Neovim with a modular Lua config in dot_config/nvim; fd backs
# its file picker and ripgrep (above) backs its text search.
brew "neovim"
brew "fd"

# JavaScript / TypeScript
brew "node@24"
brew "pnpm"
brew "angular-cli"

# Java / Spring Boot
brew "openjdk@21"
brew "openjdk@25"
brew "maven"

# Database
brew "mysql"

# PHP
brew "php"
brew "composer"

# Python
brew "python@3.14"
# Project/package/environment manager. Homebrew Python stays the default
# interpreter; uv only manages per-project environments and their own Python
# versions (.python-version / pyproject.toml).
brew "uv"
# Python version manager. Installs and switches full interpreter versions
# (pyenv install, pyenv global/local) for cases uv's per-project versions
# don't cover; shell hook lives in tools.zsh.
brew "pyenv"

# macOS Dock management. Used by scripts/macos/apply-preferences.sh to build a
# deterministic Dock; not required at runtime.
brew "dockutil"

# Mac App Store CLI. Used by scripts/macos/install-mas-apps.sh (manual, needs an
# Apple ID signed in to the App Store); not run by `brew bundle`, so a restore
# never blocks on App Store authentication.
brew "mas"

# Applications worth restoring on a development Mac
cask "alt-tab"
cask "docker-desktop"
cask "intellij-idea"
cask "iterm2"
cask "visual-studio-code"
cask "warp"
cask "mysqlworkbench"
cask "postman"
cask "spotify"
cask "discord"
cask "notion"
cask "whatsapp"

# Official AI desktop apps (installed alongside, never instead of, the Claude
# Code and Codex CLIs, which are installed by their own vendors' installers into
# ~/.local/bin). Claude Desktop includes Claude Code. OpenAI folded the
# standalone Codex app into the ChatGPT desktop app (July 2026), so `chatgpt`
# is the official macOS app that exposes Codex; the `codex-app` cask is
# deprecated upstream and intentionally not used. Sign-in stays manual.
cask "claude"
cask "chatgpt"

# Whiteboard / diagram notes. Native macOS Excalidraw client (third-party).
cask "excalidrawz"

# Browsers. Zen is the daily driver; Firefox Developer Edition is for frontend
# work and DevTools; Tor Browser stays independent. No Chrome.
cask "zen"
cask "firefox@developer-edition"
cask "tor-browser"

# Proton ecosystem and VPN. Managed here for reproducibility only: account
# sign-in and the macOS network-extension approval stay manual. Proton Mail
# covers both Mail and Calendar, so no separate Calendar cask is listed.
cask "proton-mail"
cask "proton-pass"
cask "proton-drive"
cask "protonvpn"

# Background IMAP/SMTP bridge for the Proton account, used by the local
# proton-mail-mcp server (~/Developer/proton-mail-mcp) — not a user-facing
# app. Deliberately left out of scripts/macos/apply-preferences.sh's
# dock_apps list, so it never joins the Proton apps in the Dock. Account
# sign-in stays manual, same as the rest of the Proton ecosystem above.
cask "proton-mail-bridge"

# VS Code extensions are not listed here: the canonical list for every platform is
# manifests/vscode-extensions.txt, installed on macOS by
# scripts/macos/install-vscode-extensions.sh (run by chezmoi after this bundle).
