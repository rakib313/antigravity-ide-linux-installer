#!/usr/bin/env bash
# ==============================================================================
# Antigravity IDE — Native Debian Package (.deb) Generator
# https://github.com/rakib313/antigravity-ide-linux-installer
#
# Builds a standard, redistributable .deb package from an Antigravity IDE tarball
# or extracted folder using standard `dpkg-deb`.
# ==============================================================================
set -euo pipefail

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_GREEN="\033[32m"
    C_CYAN="\033[36m"
    C_RED="\033[31m"
else
    C_RESET=""
    C_BOLD=""
    C_GREEN=""
    C_CYAN=""
    C_RED=""
fi

log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

if ! command -v dpkg-deb >/dev/null 2>&1; then
    log_err "'dpkg-deb' is required to build Debian packages. Install it via: sudo apt install dpkg"
    exit 1
fi

SOURCE_INPUT="${1:-}"
TEMP_EXTRACT_DIR=""

cleanup() {
    if [ -n "$TEMP_EXTRACT_DIR" ] && [ -d "$TEMP_EXTRACT_DIR" ]; then
        rm -rf "$TEMP_EXTRACT_DIR"
    fi
}
trap cleanup EXIT

# Auto-detect if no argument provided
if [ -z "$SOURCE_INPUT" ]; then
    for search_dir in "." "${HOME}/Downloads"; do
        [ -d "$search_dir" ] || continue
        for d in "$search_dir"/[Aa]ntigravity* "$search_dir"/*[Aa]ntigravity*[Ii][Dd][Ee]*; do
            if [ -d "$d" ] && [ -f "$d/antigravity-ide" ]; then
                SOURCE_INPUT="$d"
                break 2
            fi
        done
        for f in "$search_dir"/[Aa]ntigravity*.tar.gz "$search_dir"/*[Aa]ntigravity*[Ii][Dd][Ee]*.tar.gz; do
            if [ -f "$f" ]; then
                SOURCE_INPUT="$f"
                break 2
            fi
        done
    done
fi

if [ -z "$SOURCE_INPUT" ] || [ ! -e "$SOURCE_INPUT" ]; then
    log_err "Please provide the path to the Antigravity IDE archive or folder."
    echo "Usage: $0 /path/to/\"Antigravity IDE.tar.gz\""
    exit 1
fi

BUNDLE_DIR=""
if [ -f "$SOURCE_INPUT" ]; then
    log_info "Extracting archive: $(basename "$SOURCE_INPUT")..."
    TEMP_EXTRACT_DIR="$(mktemp -d -t antigravity-deb-build-XXXXXX)"
    tar -xzf "$SOURCE_INPUT" -C "$TEMP_EXTRACT_DIR"
    FOUND_BIN="$(find "$TEMP_EXTRACT_DIR" -maxdepth 2 -name "antigravity-ide" -type f | head -n 1)"
    if [ -z "$FOUND_BIN" ]; then
        log_err "Could not find 'antigravity-ide' in archive."
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
            log_err "Could not find 'antigravity-ide' in $SOURCE_INPUT"
            exit 1
        fi
    fi
fi

# Extract version
PACKAGE_JSON="$BUNDLE_DIR/resources/app/package.json"
IDE_VERSION="1.0.0"
if [ -f "$PACKAGE_JSON" ]; then
    IDE_VERSION="$(grep -o '"version": "[^"]*"' "$PACKAGE_JSON" | cut -d'"' -f4 || echo "1.0.0")"
fi

PKG_NAME="antigravity-ide"
ARCH="amd64"
DEB_FILENAME="${PKG_NAME}_${IDE_VERSION}_${ARCH}.deb"
STAGING_DIR="$(pwd)/build/deb-staging"

log_info "Preparing package ${C_BOLD}${PKG_NAME} (v${IDE_VERSION}) [${ARCH}]${C_RESET}..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/DEBIAN"
mkdir -p "$STAGING_DIR/opt/$PKG_NAME"
mkdir -p "$STAGING_DIR/usr/bin"
mkdir -p "$STAGING_DIR/usr/share/applications"
mkdir -p "$STAGING_DIR/usr/share/mime/packages"
mkdir -p "$STAGING_DIR/usr/share/bash-completion/completions"
mkdir -p "$STAGING_DIR/usr/share/zsh/vendor-completions"

# 1. Copy Application files to /opt/antigravity-ide
log_info "Copying files to staging directory..."
cp -a "$BUNDLE_DIR/." "$STAGING_DIR/opt/$PKG_NAME/"

# 2. Binary symlinks
ln -sf "/opt/$PKG_NAME/bin/antigravity-ide" "$STAGING_DIR/usr/bin/antigravity-ide"
ln -sf "/opt/$PKG_NAME/bin/antigravity-ide" "$STAGING_DIR/usr/bin/agy-ide"

# 3. Desktop entry
cat > "$STAGING_DIR/usr/share/applications/antigravity-ide.desktop" <<'DESK_EOF'
[Desktop Entry]
Name=Antigravity IDE
Comment=Code editor
GenericName=Text Editor
Exec=/opt/antigravity-ide/antigravity-ide %F
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
Exec=/opt/antigravity-ide/antigravity-ide --new-window %F
Icon=antigravity-ide
DESK_EOF

# 4. Multi-resolution Icons
ICON_SRC="$BUNDLE_DIR/resources/app/resources/linux/code.png"
if [ -f "$ICON_SRC" ]; then
    if command -v convert >/dev/null 2>&1; then
        for sz in 16 24 32 48 64 128 256 512; do
            sz_dir="$STAGING_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps"
            mkdir -p "$sz_dir"
            convert "$ICON_SRC" -resize "${sz}x${sz}" "$sz_dir/antigravity-ide.png"
        done
        mkdir -p "$STAGING_DIR/usr/share/icons/hicolor/1024x1024/apps"
        install -m644 "$ICON_SRC" "$STAGING_DIR/usr/share/icons/hicolor/1024x1024/apps/antigravity-ide.png"
    else
        mkdir -p "$STAGING_DIR/usr/share/icons/hicolor/512x512/apps"
        install -m644 "$ICON_SRC" "$STAGING_DIR/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png"
    fi
fi

# 5. Completions
if [ -f "$BUNDLE_DIR/resources/completions/bash/antigravity-ide" ]; then
    cp "$BUNDLE_DIR/resources/completions/bash/antigravity-ide" "$STAGING_DIR/usr/share/bash-completion/completions/antigravity-ide"
    ln -sf "antigravity-ide" "$STAGING_DIR/usr/share/bash-completion/completions/agy-ide"
fi
if [ -f "$BUNDLE_DIR/resources/completions/zsh/_antigravity-ide" ]; then
    cp "$BUNDLE_DIR/resources/completions/zsh/_antigravity-ide" "$STAGING_DIR/usr/share/zsh/vendor-completions/_antigravity-ide"
    ln -sf "_antigravity-ide" "$STAGING_DIR/usr/share/zsh/vendor-completions/_agy-ide"
fi

# 6. MIME info
cat > "$STAGING_DIR/usr/share/mime/packages/antigravity-ide.xml" <<'MIME_EOF'
<?xml version="1.0" encoding="utf-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-antigravity-ide-workspace">
    <comment>Antigravity IDE Workspace</comment>
    <glob pattern="*.antigravity-workspace"/>
  </mime-type>
</mime-info>
MIME_EOF

# Calculate Installed-Size in KB
INSTALLED_SIZE="$(du -sk "$STAGING_DIR" | cut -f1)"

# 7. Control file
cat > "$STAGING_DIR/DEBIAN/control" <<CTRL_EOF
Package: $PKG_NAME
Version: $IDE_VERSION
Section: devel
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_SIZE
Depends: libc6, libsecret-1-0, libx11-6, libxkbfile1, libgtk-3-0, libnss3
Maintainer: Rakib <58782592+rakib313@users.noreply.github.com>
Homepage: https://github.com/rakib313/antigravity-ide-linux-installer
Description: Google Antigravity IDE
 Google Antigravity agent control surface and code editor.
CTRL_EOF

# Maintainer scripts
cat > "$STAGING_DIR/DEBIAN/postinst" <<'POSTINST_EOF'
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
    update-mime-database /usr/share/mime 2>/dev/null || true
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
exit 0
POSTINST_EOF
chmod 755 "$STAGING_DIR/DEBIAN/postinst"

cat > "$STAGING_DIR/DEBIAN/postrm" <<'POSTRM_EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
    update-mime-database /usr/share/mime 2>/dev/null || true
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
exit 0
POSTRM_EOF
chmod 755 "$STAGING_DIR/DEBIAN/postrm"

# Build package
log_info "Building Debian package with dpkg-deb..."
dpkg-deb --build --root-owner-group "$STAGING_DIR" "$DEB_FILENAME"

# Cleanup staging
rm -rf "$STAGING_DIR"

log_ok "Successfully created: ${C_BOLD}${DEB_FILENAME}${C_RESET}"
echo
echo "To install this package on your system, run:"
echo "  sudo apt install ./$DEB_FILENAME"
echo "  # or: sudo dpkg -i ./$DEB_FILENAME"
