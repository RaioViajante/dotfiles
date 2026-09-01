#!/bin/bash
# Apply intentional GNOME preferences with gsettings/dconf. Idempotent.
#
# Not handled here (hardware- or firmware-specific, see workstation-setup):
# monitor layout, monitors.xml, GDM, NVIDIA display settings, themes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
refuse_root

has gsettings || die "gsettings not found (install GNOME first)"
if ! gsettings get org.gnome.desktop.interface enable-hot-corners >/dev/null 2>&1; then
  die "no usable GNOME session bus; run this from a GNOME terminal"
fi

# --- Desktop behaviour ------------------------------------------------
log "applying GNOME desktop preferences"
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.mutter dynamic-workspaces true
gsettings set org.gnome.mutter workspaces-only-on-primary true
gsettings set org.gnome.desktop.session idle-delay "uint32 900"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
ok "desktop preferences applied"

# --- Custom keyboard shortcuts -------------------------------------
# Adopt any pre-existing binding that already uses one of our key combos so we
# never create a duplicate; preserve every unrelated custom shortcut.
log "configuring custom keyboard shortcuts"
python3 - <<'PY'
import ast, subprocess

BASE = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
LIST_SCHEMA = "org.gnome.settings-daemon.plugins.media-keys"
CK_SCHEMA = "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"

DESIRED = [
    ("Open Ptyxis",             "ptyxis --new-window", "<Control><Alt>t",  "dotfiles-ptyxis"),
    ("Open Files",              "nautilus --new-window", "<Super>e",       "dotfiles-nautilus"),
    ("Open Visual Studio Code", "code --new-window",     "<Super><Shift>c", "dotfiles-vscode"),
]

def get(*a): return subprocess.check_output(["gsettings", "get", *a]).decode().strip()
def sset(*a): subprocess.check_call(["gsettings", "set", *a])

raw = get(LIST_SCHEMA, "custom-keybindings")
paths = [] if raw in ("@as []", "[]") else [str(p) for p in ast.literal_eval(raw)]

desired_paths = [f"{BASE}/{slug}/" for *_, slug in DESIRED]
desired_bindings = {binding for _, _, binding, _ in DESIRED}

kept = []
for p in paths:
    if p in desired_paths:
        continue
    try:
        current_binding = get(f"{CK_SCHEMA}:{p}", "binding").strip("'")
    except subprocess.CalledProcessError:
        current_binding = ""
    if current_binding in desired_bindings:
        for k in ("name", "command", "binding"):
            subprocess.call(["dconf", "reset", f"{p}{k}"])
        continue
    kept.append(p)

final = kept + desired_paths
sset(LIST_SCHEMA, "custom-keybindings",
     "[" + ", ".join(f"'{p}'" for p in final) + "]")

for name, command, binding, slug in DESIRED:
    p = f"{BASE}/{slug}/"
    sset(f"{CK_SCHEMA}:{p}", "name", name)
    sset(f"{CK_SCHEMA}:{p}", "command", command)
    sset(f"{CK_SCHEMA}:{p}", "binding", binding)
PY
ok "shortcuts: Ctrl+Alt+T Ptyxis, Super+E Files, Super+Shift+C VS Code"

# --- GNOME extensions -----------------------------------------------
# Background Logo ships with Fedora.
if gnome-extensions list 2>/dev/null | grep -qx 'background-logo@fedorahosted.org'; then
  gnome-extensions enable background-logo@fedorahosted.org || true
fi

# Clipboard Indicator preferences (applied whether or not it is installed yet).
log "setting Clipboard Indicator preferences"
dconf write /org/gnome/shell/extensions/clipboard-indicator/history-size 15
dconf write /org/gnome/shell/extensions/clipboard-indicator/cache-size 5
dconf write /org/gnome/shell/extensions/clipboard-indicator/cache-only-favorites true
dconf write /org/gnome/shell/extensions/clipboard-indicator/enable-keybindings false

CLIP_UUID="clipboard-indicator@tudmotu.com"
if gnome-extensions list 2>/dev/null | grep -qx "$CLIP_UUID"; then
  gnome-extensions enable "$CLIP_UUID" || true
  ok "Clipboard Indicator is installed and enabled"
else
  cat >&2 <<'NOTE'

Clipboard Indicator is not installed. It is a third-party extension and is not
packaged by Fedora, so installation is left manual (no unofficial downloaders):

  1. open "Extensions" (gnome-extensions-app) or https://extensions.gnome.org
  2. install "Clipboard Indicator" (clipboard-indicator@tudmotu.com)
  3. log out and back in

The preferences above will apply automatically once it is installed.
Clipboard history can briefly hold sensitive data; use its Private Mode when needed.
NOTE
fi
