#!/usr/bin/env bash
# ==============================================================================
# Antigravity IDE Linux Uninstaller
# https://github.com/rakib313/antigravity-ide-linux-installer
#
# Removes all files and integrations installed by install.sh.
# Leaves user data & settings (~/.antigravity-ide) intact.
# ==============================================================================
set -euo pipefail

APP_DIR="${HOME}/Applications/antigravity-ide"

echo "Uninstalling Antigravity IDE..."

# 1. Remove CLI symlinks
rm -f "$HOME/.local/bin/antigravity-ide" "$HOME/.local/bin/agy-ide"

# 2. Remove desktop launcher
rm -f "$HOME/.local/share/applications/antigravity-ide.desktop"

# 3. Remove icons
rm -f "$HOME/.local/share/icons/hicolor/"*"/apps/antigravity-ide.png"

# 4. Remove shell completions
rm -f "$HOME/.local/share/bash-completion/completions/antigravity-ide"
rm -f "$HOME/.local/share/bash-completion/completions/agy-ide"
rm -f "$HOME/.local/share/zsh/site-functions/_antigravity-ide"
rm -f "$HOME/.local/share/zsh/site-functions/_agy-ide"

# 5. Remove MIME package
rm -f "$HOME/.local/share/mime/packages/antigravity-ide.xml"

# 6. Remove File Manager integrations
rm -f "$HOME/.local/share/nemo/actions/antigravity-ide.nemo_action"
rm -f "$HOME/.local/share/kservices5/ServiceMenus/antigravity-ide.desktop"
rm -f "$HOME/.local/share/nautilus-python/extensions/antigravity-ide.py"

if [ -f "$HOME/.config/Thunar/uca.xml" ]; then
    python3 - <<'PY' 2>/dev/null || true
import os
import xml.etree.ElementTree as ET

path = os.path.expanduser("~/.config/Thunar/uca.xml")
if os.path.exists(path):
    tree = ET.parse(path)
    root = tree.getroot()
    changed = False
    for act in list(root.findall("action")):
        if "Antigravity IDE" in (act.findtext("name") or "") or \
           "antigravity-ide" in (act.findtext("unique-id") or ""):
            root.remove(act)
            changed = True
    if changed:
        ET.indent(tree, space="\t", level=0)
        tree.write(path, encoding="utf-8", xml_declaration=True)
PY
fi

# 7. Remove AppArmor profile if installed
PROFILE_PATH="/etc/apparmor.d/userns-antigravity-ide-${USER}"
if [ -f "$PROFILE_PATH" ]; then
    echo "Removing AppArmor profile (sudo)..."
    sudo apparmor_parser -R "$PROFILE_PATH" 2>/dev/null || true
    sudo rm -f "$PROFILE_PATH"
fi

# 8. Refresh desktop and icon databases
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

# 9. Remove application directory
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
fi

echo "Antigravity IDE has been completely uninstalled."
echo "Your settings and extensions in ~/.antigravity-ide have been kept."
