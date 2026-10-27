#!/usr/bin/env bash
# ==============================================================================
# Antigravity IDE Linux Installer
# https://github.com/rakib313/antigravity-ide-linux-installer
#
# A complete, automated, distro-agnostic installer for Google Antigravity IDE.
# Compatible with Ubuntu, Linux Mint, Debian, Fedora, Arch Linux, openSUSE, etc.
# Configures:
#   - Safe installation to ~/Applications/antigravity-ide
#   - CLI wrappers in ~/.local/bin (antigravity-ide and agy-ide)
#   - Multi-resolution icon suite (16px to 512px + 1024px)
#   - Freedesktop-compliant .desktop launcher with search keywords
#   - Shell completions for Bash, Zsh, and Fish
#   - URL scheme handler (antigravity-ide://) & workspace MIME registration
#   - File manager right-click integration (Thunar, Nautilus, Nemo, Dolphin)
#   - AppArmor sandbox detection (Ubuntu 24.04+ compatible, 100% rootless on others)
# ==============================================================================
set -euo pipefail

# --- Color formatting ---------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_GREEN="\033[32m"
    C_BLUE="\033[34m"
    C_CYAN="\033[36m"
    C_YELLOW="\033[33m"
    C_RED="\033[31m"
else
    C_RESET=""
    C_BOLD=""
    C_GREEN=""
    C_BLUE=""
    C_CYAN=""
    C_YELLOW=""
    C_RED=""
fi

log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }
log_step()  { echo -e "\n${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }

# --- Usage help ---------------------------------------------------------------
show_help() {
    cat <<EOF_HELP
Antigravity IDE Linux Installer

Usage:
  $0 [options] [/path/to/extracted/bundle | /path/to/archive.tar.gz]

Options:
  -y, --yes          Non-interactive mode (auto-accept defaults)
  -d, --dest <dir>   Installation directory (default: \$HOME/Applications/antigravity-ide)
  -h, --help         Show this help message

If no path is provided, the installer automatically scans current directory
and ~/Downloads for an Antigravity archive or extracted directory.
EOF_HELP
}

AUTO_YES=0
DEST_DIR="${HOME}/Applications/antigravity-ide"
SOURCE_INPUT=""
TEMP_EXTRACT_DIR=""

cleanup() {
    if [ -n "$TEMP_EXTRACT_DIR" ] && [ -d "$TEMP_EXTRACT_DIR" ]; then
        rm -rf "$TEMP_EXTRACT_DIR"
    fi
}
trap cleanup EXIT

# --- Parse arguments ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            AUTO_YES=1
            shift
            ;;
        -d|--dest)
            DEST_DIR="${2:-}"
            if [ -z "$DEST_DIR" ]; then
                log_err "--dest requires a directory path."
                exit 1
            fi
            shift 2
            ;;
        -*)
            log_err "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$SOURCE_INPUT" ]; then
                SOURCE_INPUT="$1"
            else
                log_err "Unexpected argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

echo -e "${C_BOLD}Google Antigravity IDE — Universal Linux Installer${C_RESET}"
echo -e "=================================================="

# --- Distribution detection ---------------------------------------------------
DISTRO_NAME="Linux"
PKG_MGR="apt"
if [ -f /etc/os-release ]; then
    DISTRO_NAME="$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo "Linux")"
    DISTRO_ID="$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo "")"
    DISTRO_LIKE="$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo "")"
    
    if [[ "$DISTRO_ID" == *"fedora"* ]] || [[ "$DISTRO_LIKE" == *"rhel"* ]] || [[ "$DISTRO_LIKE" == *"fedora"* ]]; then
        PKG_MGR="dnf"
    elif [[ "$DISTRO_ID" == *"arch"* ]] || [[ "$DISTRO_LIKE" == *"arch"* ]]; then
        PKG_MGR="pacman"
    elif [[ "$DISTRO_ID" == *"suse"* ]] || [[ "$DISTRO_LIKE" == *"suse"* ]]; then
        PKG_MGR="zypper"
    else
        PKG_MGR="apt"
    fi
fi
log_info "Detected OS: ${C_BOLD}${DISTRO_NAME}${C_RESET} (package manager: ${PKG_MGR})"

# --- Source auto-detection ----------------------------------------------------
find_source() {
    local candidates=()

    # Search current directory and ~/Downloads
    for search_dir in "." "${HOME}/Downloads"; do
        [ -d "$search_dir" ] || continue
        # 1. Extracted directories
        for d in "$search_dir"/[Aa]ntigravity* "$search_dir"/*[Aa]ntigravity*[Ii][Dd][Ee]*; do
            if [ -d "$d" ] && [ -f "$d/antigravity-ide" ]; then
                candidates+=("$d")
            fi
        done
        # 2. Compressed archives
        for f in "$search_dir"/[Aa]ntigravity*.tar.gz "$search_dir"/*[Aa]ntigravity*[Ii][Dd][Ee]*.tar.gz; do
            if [ -f "$f" ]; then
                candidates+=("$f")
            fi
        done
    done

    if [ ${#candidates[@]} -eq 0 ]; then
        return 1
    fi

    echo "${candidates[0]}"
    return 0
}

if [ -z "$SOURCE_INPUT" ]; then
    log_info "No source path specified. Searching current directory and ~/Downloads..."
    DETECTED="$(find_source || true)"
    if [ -n "$DETECTED" ]; then
        log_info "Discovered Antigravity package: ${C_BOLD}${DETECTED}${C_RESET}"
        if [ "$AUTO_YES" -eq 1 ]; then
            SOURCE_INPUT="$DETECTED"
        else
            read -r -p "Install from this location? [Y/n] " ans
            case "${ans:-Y}" in
                [Yy]*|"") SOURCE_INPUT="$DETECTED" ;;
                *)
                    log_err "Installation aborted by user."
                    exit 1
                    ;;
            esac
        fi
    else
        log_err "Could not automatically locate an Antigravity IDE archive or extracted folder."
        echo "Please provide the path to your downloaded Antigravity IDE:"
        echo "  $0 /path/to/\"Antigravity IDE.tar.gz\""
        echo "  $0 /path/to/extracted/\"Antigravity IDE\""
        exit 1
    fi
fi

# Resolve source path
if [ ! -e "$SOURCE_INPUT" ]; then
    log_err "Source path does not exist: $SOURCE_INPUT"
    exit 1
fi
SOURCE_INPUT="$(cd "$(dirname "$SOURCE_INPUT")" && pwd)/$(basename "$SOURCE_INPUT")"

# --- Extraction if archive ----------------------------------------------------
BUNDLE_DIR=""
if [ -f "$SOURCE_INPUT" ]; then
    log_step "Extracting archive: $(basename "$SOURCE_INPUT")"
    TEMP_EXTRACT_DIR="$(mktemp -d -t antigravity-install-XXXXXX)"
    tar -xzf "$SOURCE_INPUT" -C "$TEMP_EXTRACT_DIR"
    
    FOUND_BIN="$(find "$TEMP_EXTRACT_DIR" -maxdepth 2 -name "antigravity-ide" -type f | head -n 1)"
    if [ -z "$FOUND_BIN" ]; then
        log_err "Could not find 'antigravity-ide' binary inside archive."
        exit 1
    fi
    BUNDLE_DIR="$(dirname "$FOUND_BIN")"
elif [ -d "$SOURCE_INPUT" ]; then
    if [ -f "$SOURCE_INPUT/antigravity-ide" ]; then
        BUNDLE_DIR="$SOURCE_INPUT"
    else
        FOUND_BIN="$(find "$SOURCE_INPUT" -maxdepth 2 -name "antigravity-ide" -type f | head -n 1)"
        if [ -n "$FOUND_BIN" ]; then
            BUNDLE_DIR="$(dirname "$FOUND_BIN")"
        else
            log_err "Could not find 'antigravity-ide' executable in $SOURCE_INPUT"
            exit 1
        fi
    fi
fi

# --- Metadata inspection ------------------------------------------------------
PACKAGE_JSON="$BUNDLE_DIR/resources/app/package.json"
IDE_VERSION="Unknown"
if [ -f "$PACKAGE_JSON" ]; then
    IDE_VERSION="$(grep -o '"version": "[^"]*"' "$PACKAGE_JSON" | cut -d'"' -f4 || echo "Unknown")"
fi
log_ok "Bundle verified: Antigravity IDE version ${C_BOLD}${IDE_VERSION}${C_RESET}"

# --- 1. Copy Application Core -------------------------------------------------
log_step "Installing core files to: $DEST_DIR"
mkdir -p "$(dirname "$DEST_DIR")"
if [ -d "$DEST_DIR" ]; then
    log_info "Replacing previous installation at $DEST_DIR..."
    rm -rf "$DEST_DIR"
fi
mkdir -p "$DEST_DIR"
cp -a "$BUNDLE_DIR/." "$DEST_DIR/"
log_ok "Application files successfully copied."

# --- 2. CLI Symlinks ----------------------------------------------------------
log_step "Configuring terminal commands"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

if [ -f "$DEST_DIR/bin/antigravity-ide" ]; then
    ln -sf "$DEST_DIR/bin/antigravity-ide" "$BIN_DIR/antigravity-ide"
    ln -sf "$DEST_DIR/bin/antigravity-ide" "$BIN_DIR/agy-ide"
    log_ok "Created CLI symlinks: ${BIN_DIR}/antigravity-ide and ${BIN_DIR}/agy-ide"
else
    ln -sf "$DEST_DIR/antigravity-ide" "$BIN_DIR/antigravity-ide"
    log_warn "bin/antigravity-ide wrapper not found; linked raw binary."
fi

# Check PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log_warn "$BIN_DIR is not currently in your \$PATH."
    log_info "Add this line to your shell configuration file (~/.bashrc, ~/.zshrc):"
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# --- 3. Icon Suite Generation -------------------------------------------------
log_step "Installing multi-resolution icon suite"
ICON_SRC="$DEST_DIR/resources/app/resources/linux/code.png"
if [ -f "$ICON_SRC" ]; then
    ICON_BASE_DIR="${HOME}/.local/share/icons/hicolor"
    mkdir -p "$ICON_BASE_DIR"

    if command -v convert >/dev/null 2>&1; then
        for sz in 16 24 32 48 64 128 256 512; do
            sz_dir="$ICON_BASE_DIR/${sz}x${sz}/apps"
            mkdir -p "$sz_dir"
            convert "$ICON_SRC" -resize "${sz}x${sz}" "$sz_dir/antigravity-ide.png"
        done
        mkdir -p "$ICON_BASE_DIR/1024x1024/apps"
        install -m644 "$ICON_SRC" "$ICON_BASE_DIR/1024x1024/apps/antigravity-ide.png"
        log_ok "Generated crisp multi-resolution icons (16px to 512px + 1024px)."
    elif command -v magick >/dev/null 2>&1; then
        for sz in 16 24 32 48 64 128 256 512; do
            sz_dir="$ICON_BASE_DIR/${sz}x${sz}/apps"
            mkdir -p "$sz_dir"
            magick "$ICON_SRC" -resize "${sz}x${sz}" "$sz_dir/antigravity-ide.png"
        done
        mkdir -p "$ICON_BASE_DIR/1024x1024/apps"
        install -m644 "$ICON_SRC" "$ICON_BASE_DIR/1024x1024/apps/antigravity-ide.png"
        log_ok "Generated crisp multi-resolution icons with ImageMagick."
    else
        sz_dir="$ICON_BASE_DIR/512x512/apps"
        mkdir -p "$sz_dir"
        install -m644 "$ICON_SRC" "$sz_dir/antigravity-ide.png"
        log_warn "ImageMagick not installed; installed base icon to 512x512."
    fi
    gtk-update-icon-cache -f -t "$ICON_BASE_DIR" 2>/dev/null || true
else
    log_warn "Icon file not found at $ICON_SRC; launcher will use generic icon."
fi

# --- 4. AppArmor / Sandbox Check ---------------------------------------------
log_step "Checking Chromium sandbox security"
EXEC_LINE="\"$DEST_DIR/antigravity-ide\" %F"
USERNS_RESTRICTED="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)"

if [ "$USERNS_RESTRICTED" = "1" ]; then
    log_info "Kernel restricts unprivileged user namespaces (Ubuntu 24.04+ detected)."
    PROFILE_NAME="userns-antigravity-ide-${USER}"
    PROFILE_PATH="/etc/apparmor.d/${PROFILE_NAME}"
    PROFILE_BODY="abi <abi/4.0>,
include <tunables/global>

profile ${PROFILE_NAME} \"$DEST_DIR/antigravity-ide\" flags=(unconfined) {
  userns,
  include if exists <local/${PROFILE_NAME}>
}
"
    APPLY_AA=0
    if [ "$AUTO_YES" -eq 1 ]; then
        APPLY_AA=1
    else
        echo "A one-time AppArmor profile can be installed to enable the Chromium sandbox (requires sudo)."
        read -r -p "Install AppArmor profile? [Y/n] " ans
        case "${ans:-Y}" in
            [Yy]*|"") APPLY_AA=1 ;;
            *) APPLY_AA=0 ;;
        esac
    fi

    if [ "$APPLY_AA" -eq 1 ] && echo "$PROFILE_BODY" | sudo tee "$PROFILE_PATH" >/dev/null \
       && sudo apparmor_parser -r "$PROFILE_PATH" 2>/dev/null; then
        log_ok "AppArmor sandbox profile active: $PROFILE_PATH"
    else
        log_warn "AppArmor profile skipped; adding --no-sandbox fallback to desktop launcher."
        EXEC_LINE="\"$DEST_DIR/antigravity-ide\" --no-sandbox %F"
    fi
else
    log_ok "User namespaces enabled; Chromium sandbox runs securely without root/sudo."
fi

# --- 5. Desktop Launcher ------------------------------------------------------
log_step "Installing Desktop Launcher"
DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
DESKTOP_FILE="$DESKTOP_DIR/antigravity-ide.desktop"

cat > "$DESKTOP_FILE" <<DESK_EOF
[Desktop Entry]
Name=Antigravity IDE
Comment=Code editor
GenericName=Text Editor
Exec=$EXEC_LINE
Icon=antigravity-ide
Terminal=false
Type=Application
StartupNotify=true
StartupWMClass=antigravity-ide
Categories=Development;IDE;
MimeType=text/plain;inode/directory;application/x-antigravity-ide-workspace;x-scheme-handler/antigravity-ide;
Keywords=vscode;code;antigravity;ide;editor;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec="$DEST_DIR/antigravity-ide" --new-window %F
Icon=antigravity-ide
DESK_EOF

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
log_ok "Desktop entry installed: $DESKTOP_FILE"

# --- 6. Shell Auto-Completions (Bash, Zsh, Fish) ------------------------------
log_step "Installing shell completions"

# Bash
BASH_COMP_DIR="${HOME}/.local/share/bash-completion/completions"
if [ -f "$DEST_DIR/resources/completions/bash/antigravity-ide" ]; then
    mkdir -p "$BASH_COMP_DIR"
    cp "$DEST_DIR/resources/completions/bash/antigravity-ide" "$BASH_COMP_DIR/antigravity-ide"
    ln -sf "antigravity-ide" "$BASH_COMP_DIR/agy-ide"
    log_ok "Bash completion installed."
fi

# Zsh
ZSH_COMP_DIR="${HOME}/.local/share/zsh/site-functions"
if [ -f "$DEST_DIR/resources/completions/zsh/_antigravity-ide" ]; then
    mkdir -p "$ZSH_COMP_DIR"
    cp "$DEST_DIR/resources/completions/zsh/_antigravity-ide" "$ZSH_COMP_DIR/_antigravity-ide"
    ln -sf "_antigravity-ide" "$ZSH_COMP_DIR/_agy-ide"
    log_ok "Zsh completion installed."
fi

# Fish
FISH_COMP_DIR="${HOME}/.local/share/fish/vendor_completions.d"
mkdir -p "$FISH_COMP_DIR"
cat > "$FISH_COMP_DIR/antigravity-ide.fish" <<'FISH_EOF'
complete -c antigravity-ide -s d -l diff -d "Compare two files" -r
complete -c antigravity-ide -s a -l add -d "Add folder to last active window" -r
complete -c antigravity-ide -s g -l goto -d "Open file at line and column" -r
complete -c antigravity-ide -s n -l new-window -d "Open a new window"
complete -c antigravity-ide -s r -l reuse-window -d "Force opening in current window"
complete -c antigravity-ide -s w -l wait -d "Wait for files to close"
complete -c antigravity-ide -s v -l version -d "Print version"
complete -c antigravity-ide -s h -l help -d "Print help"
complete -c antigravity-ide -l install-extension -d "Install VSIX extension" -r
complete -c antigravity-ide -l list-extensions -d "List installed extensions"
complete -c antigravity-ide -l disable-gpu -d "Disable GPU acceleration"
complete -c agy-ide -w antigravity-ide
FISH_EOF
ln -sf "antigravity-ide.fish" "$FISH_COMP_DIR/agy-ide.fish" 2>/dev/null || true
log_ok "Fish completion installed."

# --- 7. MIME & Protocol Handlers ----------------------------------------------
log_step "Registering MIME types and URL protocols"
MIME_DIR="${HOME}/.local/share/mime/packages"
mkdir -p "$MIME_DIR"
cat > "$MIME_DIR/antigravity-ide.xml" <<'MIME_XML_EOF'
<?xml version="1.0" encoding="utf-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-antigravity-ide-workspace">
    <comment>Antigravity IDE Workspace</comment>
    <glob pattern="*.antigravity-workspace"/>
  </mime-type>
</mime-info>
MIME_XML_EOF

update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true
xdg-mime default antigravity-ide.desktop x-scheme-handler/antigravity-ide 2>/dev/null || true
xdg-mime default antigravity-ide.desktop application/x-antigravity-ide-workspace 2>/dev/null || true
log_ok "Registered antigravity-ide:// and .antigravity-workspace handlers."

# --- 8. File Manager Integration (Distro-Agnostic) ----------------------------
log_step "Configuring file manager right-click integration"

# XFCE / Thunar
THUNAR_UCA="${HOME}/.config/Thunar/uca.xml"
if [ -f "$THUNAR_UCA" ]; then
    python3 - <<'PY' 2>/dev/null || true
import os
import xml.etree.ElementTree as ET

path = os.path.expanduser("~/.config/Thunar/uca.xml")
if os.path.exists(path):
    tree = ET.parse(path)
    root = tree.getroot()
    exists = any("Antigravity IDE" in (a.findtext("name") or "") for a in root.findall("action"))
    if not exists:
        act = ET.SubElement(root, "action")
        ET.SubElement(act, "icon").text = "antigravity-ide"
        ET.SubElement(act, "name").text = "Open in Antigravity IDE"
        ET.SubElement(act, "submenu").text = ""
        ET.SubElement(act, "unique-id").text = "antigravity-ide-action"
        ET.SubElement(act, "command").text = "antigravity-ide %F"
        ET.SubElement(act, "description").text = "Open folder or file in Antigravity IDE"
        ET.SubElement(act, "range").text = ""
        ET.SubElement(act, "patterns").text = "*"
        ET.SubElement(act, "directories")
        ET.SubElement(act, "other-files")
        ET.SubElement(act, "text-files")
        ET.indent(tree, space="\t", level=0)
        tree.write(path, encoding="utf-8", xml_declaration=True)
PY
    log_ok "Added 'Open in Antigravity IDE' action to Thunar (XFCE)."
fi

# Cinnamon / Nemo
if command -v nemo >/dev/null 2>&1; then
    NEMO_DIR="${HOME}/.local/share/nemo/actions"
    mkdir -p "$NEMO_DIR"
    cat > "$NEMO_DIR/antigravity-ide.nemo_action" <<NEMO_EOF
[Nemo Action]
Name=Open in Antigravity IDE
Comment=Open file or directory in Antigravity IDE
Exec=antigravity-ide %F
Icon-Name=antigravity-ide
Selection=Any
Extensions=any;
Dependencies=antigravity-ide;
NEMO_EOF
    log_ok "Added Nemo (Cinnamon) action."
fi

# KDE Plasma 5 & Plasma 6 / Dolphin
if command -v dolphin >/dev/null 2>&1 || [ -d "${HOME}/.local/share/kservices5" ] || [ -d "${HOME}/.local/share/kio" ]; then
    # Support both KDE Plasma 6 (~/.local/share/kio/servicemenus) and Plasma 5 (~/.local/share/kservices5/ServiceMenus)
    for kde_sub in "kio/servicemenus" "kservices5/ServiceMenus"; do
        KDE_DIR="${HOME}/.local/share/$kde_sub"
        mkdir -p "$KDE_DIR"
        cat > "$KDE_DIR/antigravity-ide.desktop" <<KDE_EOF
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;all/allfiles;
Actions=openInAntigravityIDE;
X-KDE-Priority=TopLevel

[Desktop Action openInAntigravityIDE]
Name=Open in Antigravity IDE
Icon=antigravity-ide
Exec=antigravity-ide %F
KDE_EOF
    done
    log_ok "Added Dolphin (KDE Plasma 5 & 6) ServiceMenu."
fi

# GNOME / Nautilus (Distro-Agnostic via Python GObject-Introspection check)
if command -v nautilus >/dev/null 2>&1; then
    HAS_NAUTILUS_PYTHON=0
    if python3 -c "import gi; gi.require_version('Nautilus', '4.0')" 2>/dev/null || \
       python3 -c "import gi; gi.require_version('Nautilus', '3.0')" 2>/dev/null; then
        HAS_NAUTILUS_PYTHON=1
    fi

    if [ "$HAS_NAUTILUS_PYTHON" -eq 1 ]; then
        NAUTILUS_DIR="${HOME}/.local/share/nautilus-python/extensions"
        mkdir -p "$NAUTILUS_DIR"
        cat > "$NAUTILUS_DIR/antigravity-ide.py" <<'NAUTILUS_PYEOF'
import os, subprocess
from urllib.parse import unquote, urlparse
import gi
for _v in ("4.1", "4.0", "3.0"):
    try:
        gi.require_version("Nautilus", _v); break
    except ValueError: pass
from gi.repository import GObject, Nautilus
BINARY = os.path.expanduser("~/.local/bin/antigravity-ide")
def _lp(fi):
    p = urlparse(fi.get_uri())
    return unquote(p.path) if p.scheme == "file" else None
class OpenInAntigravity(GObject.GObject, Nautilus.MenuProvider):
    def get_file_items(self, files):
        paths = [p for p in (_lp(f) for f in files) if p]
        if not paths: return []
        item = Nautilus.MenuItem(name="Antigravity::open_files", label="Open in Antigravity IDE")
        item.connect("activate", lambda *_: subprocess.Popen([BINARY, *paths], start_new_session=True))
        return [item]
    def get_background_items(self, folder):
        path = _lp(folder)
        if not path: return []
        item = Nautilus.MenuItem(name="Antigravity::open_folder", label="Open in Antigravity IDE")
        item.connect("activate", lambda *_: subprocess.Popen([BINARY, path], start_new_session=True))
        return [item]
NAUTILUS_PYEOF
        log_ok "Added Nautilus (GNOME) extension."
    else
        log_info "Nautilus detected. To enable top-level right-click menu, install the Python binding:"
        case "$PKG_MGR" in
            dnf)    log_info "  sudo dnf install nautilus-python" ;;
            pacman) log_info "  sudo pacman -S python-nautilus" ;;
            zypper) log_info "  sudo zypper in python3-nautilus" ;;
            *)      log_info "  sudo apt install python3-nautilus" ;;
        esac
    fi
fi

# --- 9. Uninstaller Deployment -----------------------------------------------
log_step "Writing uninstaller"
UNINSTALL_SCRIPT="$DEST_DIR/uninstall.sh"
cat > "$UNINSTALL_SCRIPT" <<'UNINSTALL_SH_EOF'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Uninstalling Antigravity IDE..."
rm -f "$HOME/.local/bin/antigravity-ide" "$HOME/.local/bin/agy-ide"
rm -f "$HOME/.local/share/applications/antigravity-ide.desktop"
rm -f "$HOME/.local/share/icons/hicolor/"*"/apps/antigravity-ide.png"
rm -f "$HOME/.local/share/bash-completion/completions/antigravity-ide"
rm -f "$HOME/.local/share/bash-completion/completions/agy-ide"
rm -f "$HOME/.local/share/zsh/site-functions/_antigravity-ide"
rm -f "$HOME/.local/share/zsh/site-functions/_agy-ide"
rm -f "$HOME/.local/share/fish/vendor_completions.d/antigravity-ide.fish"
rm -f "$HOME/.local/share/fish/vendor_completions.d/agy-ide.fish"
rm -f "$HOME/.local/share/mime/packages/antigravity-ide.xml"
rm -f "$HOME/.local/share/nemo/actions/antigravity-ide.nemo_action"
rm -f "$HOME/.local/share/kservices5/ServiceMenus/antigravity-ide.desktop"
rm -f "$HOME/.local/share/kio/servicemenus/antigravity-ide.desktop"
rm -f "$HOME/.local/share/nautilus-python/extensions/antigravity-ide.py"

if [ -f "$HOME/.config/Thunar/uca.xml" ]; then
    python3 - <<'PY' 2>/dev/null || true
import os, xml.etree.ElementTree as ET
p = os.path.expanduser("~/.config/Thunar/uca.xml")
if os.path.exists(p):
    t = ET.parse(p)
    r = t.getroot()
    ch = False
    for a in list(r.findall("action")):
        if "Antigravity IDE" in (a.findtext("name") or "") or "antigravity-ide" in (a.findtext("unique-id") or ""):
            r.remove(a); ch = True
    if ch:
        ET.indent(t, space="\t", level=0)
        t.write(p, encoding="utf-8", xml_declaration=True)
PY
fi

PROFILE_PATH="/etc/apparmor.d/userns-antigravity-ide-${USER}"
if [ -f "$PROFILE_PATH" ]; then
    echo "Removing AppArmor profile (sudo)..."
    sudo apparmor_parser -R "$PROFILE_PATH" 2>/dev/null || true
    sudo rm -f "$PROFILE_PATH"
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

rm -rf "$APP_DIR"
echo "Antigravity IDE uninstalled successfully."
UNINSTALL_SH_EOF
chmod +x "$UNINSTALL_SCRIPT"
log_ok "Uninstaller ready at $UNINSTALL_SCRIPT"

# --- Finished -----------------------------------------------------------------
echo
echo -e "${C_BOLD}${C_GREEN}Installation Complete!${C_RESET}"
echo -e "--------------------------------------------------------"
echo -e "Installed path : ${DEST_DIR}"
echo -e "CLI commands   : ${C_BOLD}antigravity-ide${C_RESET} or ${C_BOLD}agy-ide${C_RESET}"
echo -e "Desktop menu   : Look for ${C_BOLD}Antigravity IDE${C_RESET} under Development"
echo -e "Uninstall script: ${UNINSTALL_SCRIPT}"
echo -e "--------------------------------------------------------"
