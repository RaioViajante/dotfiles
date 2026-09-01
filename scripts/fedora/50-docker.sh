#!/bin/bash
# Docker Engine CE for Fedora, from the official Docker CE repository.
# Requires scripts/fedora/10-repositories.sh to have run first.
#
# This does not install Docker Desktop, does not touch Podman, never exposes a
# TCP socket and never changes permissions on /var/run/docker.sock.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root
require_fedora

target_user="$(id -un)"

[[ -f /etc/yum.repos.d/docker-ce.repo ]] || die "Docker CE repository missing; run 10-repositories.sh first"

dnf_install_missing \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

for unit in docker.service containerd.service; do
  if systemctl is-enabled --quiet "$unit"; then
    ok "$unit already enabled"
  else
    log "enabling $unit"
    sudo systemctl enable --now "$unit"
  fi
done

if id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
  ok "user '$target_user' is already in the 'docker' group"
  docker_group_changed=0
else
  log "adding user '$target_user' to the 'docker' group"
  sudo usermod -aG docker "$target_user"
  docker_group_changed=1
fi

cat >&2 <<'WARNING'

SECURITY NOTE
  Membership in the 'docker' group is effectively root on this host: any
  member can start a container that mounts the whole filesystem. Treat it
  the same as passwordless sudo.

WARNING

if [[ "${docker_group_changed}" == 1 ]]; then
  warn "log out and back in (or run 'newgrp docker') before 'docker' works without sudo"
else
  ok "docker should already work without sudo in a fresh login session"
fi
