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

# Password manager and VPN. Managed here for reproducibility only: account
# sign-in and the macOS network-extension approval for Proton VPN stay manual.
cask "bitwarden"
cask "protonvpn"

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

# File/folder icon theme. The only editor theme managed automatically; keep it
# the single icon theme so icons stay consistent.
vscode "PKief.material-icon-theme"
