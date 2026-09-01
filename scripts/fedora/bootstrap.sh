#!/bin/bash
# One-time Fedora Workstation bootstrap. Run AFTER `chezmoi apply`.
#
#   "$(chezmoi source-path)/scripts/fedora/bootstrap.sh"
#
# Safe to re-run: every step checks state before changing anything. Steps call
# sudo only where a system change genuinely requires it; do not run the whole
# script as root.
#
# Individual steps can also be run on their own, in order.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../lib.sh"
refuse_root
require_fedora

steps=(
  10-repositories.sh
  20-packages.sh
  30-node.sh
  40-java.sh
  50-docker.sh
  60-vscode-extensions.sh
  70-gnome.sh
)

only="${1:-}"
for step in "${steps[@]}"; do
  if [[ -n "$only" && "$step" != "$only"* ]]; then
    continue
  fi
  printf '\n\033[1;36m########## %s ##########\033[0m\n' "$step" >&2
  bash "$here/$step"
done

cat >&2 <<'DONE'

########## bootstrap complete ##########

Manual steps that this bootstrap deliberately does not perform:
  - GitHub sign-in:     gh auth login --hostname github.com --web --git-protocol ssh
  - SSH key for GitHub: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github
                        gh ssh-key add ~/.ssh/id_ed25519_github.pub
  - Git identity:       git config --file ~/.config/git/local.gitconfig user.name  "..."
                        git config --file ~/.config/git/local.gitconfig user.email "..."
  - Default shell:      chsh -s "$(command -v zsh)"    (then log out/in)
  - docker group:       log out/in so membership takes effect
  - Clipboard Indicator: install from the Extensions app (see 70-gnome.sh)
  - NVIDIA driver + Secure Boot / MOK enrollment: see the workstation-setup repo
DONE
