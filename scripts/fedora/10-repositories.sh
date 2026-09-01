#!/bin/bash
# Enable the external DNF repositories this environment depends on:
#   - RPM Fusion (free + nonfree)   NVIDIA driver, multimedia codecs
#   - Microsoft Visual Studio Code  official RPM build
#   - Docker CE                     upstream Docker Engine
#
# Idempotent: existing repositories and keys are left untouched.
# The NVIDIA driver itself and Secure Boot / MOK enrollment are NOT handled
# here; see the workstation-setup repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root
require_fedora

fedora_release="$(rpm -E %fedora)"

# --- RPM Fusion ------------------------------------------------------------
if rpm -q rpmfusion-free-release >/dev/null 2>&1 \
   && rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
  ok "RPM Fusion already enabled"
else
  log "enabling RPM Fusion (free + nonfree)"
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_release}.noarch.rpm"
fi

# --- Visual Studio Code ---------------------------------------------------
if [[ -f /etc/yum.repos.d/vscode.repo ]]; then
  ok "VS Code repository already present"
else
  log "adding the Microsoft VS Code repository"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-gpg
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
fi

# --- Docker CE ----------------------------------------------------------
if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
  ok "Docker CE repository already present"
else
  log "adding the Docker CE repository"
  curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo \
    | sudo tee /etc/yum.repos.d/docker-ce.repo >/dev/null
fi

ok "external repositories ready"
