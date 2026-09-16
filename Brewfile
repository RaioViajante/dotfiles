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
# Ships a .pkg installer, so `brew bundle` asks for an admin password once.
cask "microsoft-outlook"

# Whiteboard / diagram notes. Native macOS Excalidraw client (third-party).
cask "excalidrawz"

# Browsers. Zen is the daily driver; Firefox Developer Edition is for frontend
# work and DevTools; Tor Browser stays independent. No Chrome.
cask "zen"
cask "firefox@developer-edition"
cask "tor-browser"

# Proton ecosystem and VPNs. Managed here for reproducibility only: account
# sign-in and the macOS network-extension approval stay manual. Proton Mail
# covers both Mail and Calendar, so no separate Calendar cask is listed.
# Cloudflare WARP also ships a .pkg installer, so `brew bundle` asks for an
# admin password once.
cask "proton-mail"
cask "proton-pass"
cask "proton-drive"
cask "protonvpn"
cask "cloudflare-warp"

# Background IMAP/SMTP bridge for the Proton account, used by the local
# proton-mail-mcp server (~/Developer/proton-mail-mcp) — not a user-facing
# app. Deliberately left out of scripts/macos/apply-preferences.sh's
# dock_apps list, so it never joins the Proton apps in the Dock. Account
# sign-in stays manual, same as the rest of the Proton ecosystem above.
cask "proton-mail-bridge"

# VS Code extensions. Top-level only: extension packs pull in their own members
# (Java, Spring Boot, Pylance, debuggers) automatically, so those are not listed.
# Installed by `brew bundle` through run_onchange_before_20-brew-bundle.sh.tmpl.
vscode "angular.ng-template"
vscode "dbaeumer.vscode-eslint"
vscode "esbenp.prettier-vscode"
vscode "vscjava.vscode-java-pack"
vscode "vmware.vscode-boot-dev-pack"
vscode "ms-python.python"
vscode "ms-azuretools.vscode-containers"

# Editor themes, matching the manual choice on this machine: the Material
# file/folder icon theme and the Catppuccin colour theme (Mocha variant, set in
# the managed settings.json). One of each so the look stays consistent.
vscode "PKief.material-icon-theme"
vscode "catppuccin.catppuccin-vsc"
