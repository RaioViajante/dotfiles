#!/bin/bash
# Node.js toolchain for Fedora: fnm + Node 24 LTS + Corepack + pnpm + Angular CLI.
# Shell integration lives in dot_config/zsh/integrations.zsh; this script never
# edits shell rc files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root

FNM_DIR="$HOME/.local/share/fnm"
FNM_BIN="$FNM_DIR/fnm"
NODE_MAJOR=24
export PNPM_HOME="$HOME/.local/share/pnpm"

# --- fnm ----------------------------------------------------------------
if [[ -x "$FNM_BIN" ]]; then
  ok "fnm already installed ($("$FNM_BIN" --version))"
else
  log "installing fnm to $FNM_DIR (--skip-shell: no rc file changes)"
  curl -fsSL https://fnm.vercel.app/install \
    | bash -s -- --install-dir "$FNM_DIR" --skip-shell
fi
[[ -x "$FNM_BIN" ]] || die "fnm installation failed"

# Activate fnm for this script only.
eval "$("$FNM_BIN" env --shell bash)"

# --- Node 24 LTS ------------------------------------------------------
if "$FNM_BIN" list | grep -qE "v${NODE_MAJOR}\."; then
  ok "Node ${NODE_MAJOR}.x already installed"
else
  log "installing the latest Node ${NODE_MAJOR} LTS"
  "$FNM_BIN" install "$NODE_MAJOR"
fi
"$FNM_BIN" use "$NODE_MAJOR"
"$FNM_BIN" default "$("$FNM_BIN" current)"
log "active Node: $(node --version)  npm: $(npm --version)  default: $("$FNM_BIN" current)"

# --- Corepack + pnpm ------------------------------------------------
log "enabling Corepack and activating the latest stable pnpm"
corepack enable
corepack prepare pnpm@latest --activate
mkdir -p "$PNPM_HOME"
export PATH="$PNPM_HOME:$PNPM_HOME/bin:$PATH"
log "pnpm: $(pnpm --version)"

# --- Angular CLI (global, via pnpm) -------------------------------
if pnpm list -g 2>/dev/null | grep -q '@angular/cli'; then
  ok "Angular CLI already installed globally"
else
  log "installing @angular/cli globally with pnpm"
  pnpm add -g @angular/cli
fi

if has ng; then
  ng config -g cli.packageManager pnpm >/dev/null
  ng config -g cli.analytics false >/dev/null
  ok "Angular CLI configured (package manager: pnpm, analytics: disabled)"
else
  warn "ng is not on PATH yet; open a new shell (integrations.zsh adds \$PNPM_HOME)"
fi

cat >&2 <<'NOTE'
Node toolchain ready.
Project-local tools stay project-local: TypeScript, ESLint, Prettier, the
Tailwind CLI, the Nest CLI, Vite, Yarn and Bun are NOT installed globally.
Add them per project with `pnpm add -D ...` and run them with `pnpm exec ...`.
NOTE
