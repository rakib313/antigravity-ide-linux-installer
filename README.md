# Antigravity IDE — Linux Installer & Packaging Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://www.kernel.org)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Debian Package](https://img.shields.io/badge/Package-.deb%20Builder-crimson.svg)](build-deb.sh)

A complete, automated, and human-friendly installer and Debian packager for **Google Antigravity IDE** on Linux.

Antigravity IDE ships for Linux as an unmanaged raw `.tar.gz` archive. This repository turns that raw archive into a first-class, fully integrated desktop application—complete with application menu launchers, sharp icons, terminal CLI commands, shell completions, and file manager context menus.

---

## Features

- 🚀 **Smart Auto-Detection**: Automatically detects `.tar.gz` archives or extracted folders in your current directory or `~/Downloads`.
- 🛡️ **Safe & Non-Destructive**: Never moves or deletes your original downloaded archive.
- ⚡ **True CLI Wrapper**: Symlinks `antigravity-ide` and `agy-ide` to the VS Code/Node CLI runner so flags like `--version`, `--diff`, `--wait`, and multi-window reuse work properly.
- 🎨 **Multi-Resolution Icons**: Generates crisp, pixel-perfect icons across all standard Linux sizes (`16x16` up to `512x512` and `1024x1024`) so panel launchers, Whisker Menu, taskbar items, and Alt-Tab window switchers look razor-sharp.
- ⌨️ **Shell Auto-Completions**: Installs native `<TAB>` completions for both **Bash** and **Zsh**.
- 📂 **Multi-Desktop Context Menus**: Auto-detects your desktop environment and installs "Open in Antigravity IDE" right-click actions for:
  - **XFCE** (Thunar Custom Action)
  - **GNOME** (Nautilus Python Extension)
  - **Cinnamon** (Nemo Action)
  - **KDE Plasma** (Dolphin ServiceMenu)
- 🔗 **Deep Linking & Workspace MIME**: Registers the `antigravity-ide://` URL protocol handler and `application/x-antigravity-ide-workspace`.
- 🔒 **Kernel Sandbox Intelligence**: Automatically inspects `kernel.apparmor_restrict_unprivileged_userns`. Runs **100% rootless** (zero `sudo` required) on Linux Mint, Debian, Arch, and Fedora. On Ubuntu 24.04+, cleanly configures an AppArmor exception profile.
- 📦 **Native Debian Package Generator**: Includes `build-deb.sh` to package Antigravity into a standard `.deb` file for system-wide installation.

---

## Quickstart

### Method 1: Interactive One-Liner (Recommended)

1. Download the Antigravity IDE Linux archive from Google to your `~/Downloads` folder.
2. Run the installer directly from your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/rakib313/antigravity-ide-linux-installer/main/install.sh | bash
```

The script will scan for the downloaded archive, prompt for confirmation, and configure everything automatically.

---

### Method 2: Git Clone & Local Run

Clone the repository and run the installer:

```bash
git clone https://github.com/rakib313/antigravity-ide-linux-installer.git
cd antigravity-ide-linux-installer
./install.sh
```

You can also explicitly pass the path to your extracted directory or archive:

```bash
./install.sh ~/Downloads/"Antigravity IDE.tar.gz"
# or
./install.sh ~/Downloads/"Antigravity IDE"
```

#### Non-Interactive (Automation / Scripts):
```bash
./install.sh -y /path/to/archive.tar.gz
```

---

### Method 3: Build a Native `.deb` Package

If you prefer installing via your system package manager (`apt`, `dpkg`, or GDebi):

```bash
./build-deb.sh ~/Downloads/"Antigravity IDE.tar.gz"
```

This generates `antigravity-ide_<version>_amd64.deb`. Install it with:

```bash
sudo apt install ./antigravity-ide_*.deb
```

---

## What Gets Configured

| Component | Target Location | Description |
| :--- | :--- | :--- |
| **Application Core** | `~/Applications/antigravity-ide/` | Full user-local install (isolated, no root needed) |
| **Terminal CLI** | `~/.local/bin/antigravity-ide`<br>`~/.local/bin/agy-ide` | Points to CLI wrapper script (`bin/antigravity-ide`) |
| **Desktop Launcher** | `~/.local/share/applications/antigravity-ide.desktop` | Freedesktop launcher with window matching and search keywords |
| **Icon Suite** | `~/.local/share/icons/hicolor/<size>/apps/` | Standard resolutions (`16px`, `24px`, `32px`, `48px`, `64px`, `128px`, `256px`, `512px`) |
| **Shell Completions** | `~/.local/share/bash-completion/completions/`<br>`~/.local/share/zsh/site-functions/` | Tab completions for command flags and arguments |
| **MIME / Protocol** | `~/.local/share/mime/packages/antigravity-ide.xml` | Associates `antigravity-ide://` URL scheme and workspaces |
| **Uninstaller** | `~/Applications/antigravity-ide/uninstall.sh` | Clean single-command uninstaller |

---

## Uninstallation

To remove the user-local installation and all associated desktop integrations:

```bash
# If cloned repository is available:
./uninstall.sh

# Or directly from the installed directory:
~/Applications/antigravity-ide/uninstall.sh
```

*(Your personal settings, user data, and extensions in `~/.antigravity-ide` are safely preserved).*

If you installed via `.deb`, simply use:
```bash
sudo apt remove antigravity-ide
```

---

## Troubleshooting & Tips

### 1. Terminal command not found (`antigravity-ide: command not found`)
Ensure `~/.local/bin` is in your `$PATH`. Check by running:
```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "OK" || echo "Missing"
```
If missing, add this to your `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 2. Large workspace file watcher error
If you work on large projects and see a file watching notification, increase your Linux inotify limit:
```bash
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.d/40-max-user-watches.conf
sudo sysctl --system
```

---

## License

Distributed under the [MIT License](LICENSE).

---

## Acknowledgments

Inspired by community work around raw tarball packaging on modern Linux distributions.
