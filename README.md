# Antigravity IDE — Universal Linux Installer & Packaging Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Mint%20%7C%20Debian%20%7C%20Fedora%20%7C%20Arch-orange.svg)](https://www.kernel.org)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Debian Package](https://img.shields.io/badge/Package-.deb%20Builder-crimson.svg)](build-deb.sh)
[![Arch Linux](https://img.shields.io/badge/Arch-PKGBUILD-blue.svg)](packaging/arch/PKGBUILD)

A complete, automated, and **distro-agnostic** installer and packager for **Google Antigravity IDE** on Linux.

Antigravity IDE ships for Linux as an unmanaged raw `.tar.gz` archive. This repository turns that raw archive into a first-class, fully integrated desktop application—complete with application menu launchers, sharp icons, terminal CLI commands, shell completions, and file manager context menus across all major Linux distributions.

---

## Distribution Support Matrix

| Distribution | Status | Installation Method | Root / Sudo Required | Desktop & Context Menu Integration |
| :--- | :---: | :--- | :---: | :--- |
| **Linux Mint** | ✅ **100% Tested** | `./install.sh` or `.deb` | ❌ None (100% Rootless) | **Thunar** (XFCE), **Nemo** (Cinnamon) |
| **Ubuntu 24.04+** | ✅ **Supported** | `./install.sh` or `.deb` | ⚠️ 1-time AppArmor profile | **Nautilus** (GNOME) |
| **Debian 12+** | ✅ **Supported** | `./install.sh` or `.deb` | ❌ None (100% Rootless) | **Nautilus**, **XFCE**, **KDE** |
| **Fedora 39+** | ✅ **Supported** | `./install.sh` | ❌ None (100% Rootless) | **Nautilus**, **Dolphin** (KDE 5 & 6) |
| **Arch / Manjaro** | ✅ **Supported** | `./install.sh` or `PKGBUILD` | ❌ None (100% Rootless) | **All Desktops** |
| **openSUSE** | ✅ **Supported** | `./install.sh` | ❌ None (100% Rootless) | **Dolphin**, **GNOME** |

---

## Features

- 🌐 **Distro-Agnostic**: Automatically detects your distribution family (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE) and adapts commands accordingly.
- 🚀 **Smart Auto-Detection**: Searches your current directory and `~/Downloads` for `Antigravity IDE` directories or `.tar.gz` archives.
- 🛡️ **Safe & Non-Destructive**: Copies files safely using `cp -a` without deleting or modifying your original download.
- ⚡ **True CLI Wrapper**: Symlinks `antigravity-ide` and `agy-ide` to the official VS Code/Node CLI runner (`bin/antigravity-ide`) so `--version`, `--diff`, `--wait`, and multi-window reuse work properly.
- 🎨 **Multi-Resolution Icons**: Generates crisp, pixel-perfect icons across all standard Linux sizes (`16x16` up to `512x512` and `1024x1024`) so panel launchers, Whisker Menu, taskbar items, and Alt-Tab window switchers look razor-sharp.
- ⌨️ **Shell Auto-Completions**: Installs native `<TAB>` completions for **Bash**, **Zsh**, and **Fish**.
- 📂 **Multi-Desktop Context Menus**: Auto-detects your desktop environment and installs "Open in Antigravity IDE" right-click actions for:
  - **XFCE** (Thunar Custom Action in `uca.xml`)
  - **GNOME** (Nautilus Python Extension with runtime introspection)
  - **Cinnamon** (Nemo Action)
  - **KDE Plasma 5 & 6** (Dolphin dual ServiceMenu paths)
- 🔗 **Deep Linking & Workspace MIME**: Registers the `antigravity-ide://` URL protocol handler and `application/x-antigravity-ide-workspace`.
- 🔒 **Kernel Sandbox Intelligence**: Automatically inspects `kernel.apparmor_restrict_unprivileged_userns`. Runs **100% rootless** on Linux Mint, Debian, Arch, and Fedora. On Ubuntu 24.04+, cleanly configures an AppArmor exception profile.
- 📦 **Packaging Tools Included**:
  - `build-deb.sh` for Debian, Ubuntu, and Linux Mint (`.deb`).
  - `packaging/arch/PKGBUILD` for Arch Linux and Manjaro.

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

You can also explicitly specify the path to your extracted directory or archive:

```bash
./install.sh ~/Downloads/"Antigravity IDE.tar.gz"
# or
./install.sh ~/Downloads/"Antigravity IDE"
```

#### Non-Interactive (Automation / CI):
```bash
./install.sh -y /path/to/archive.tar.gz
```

---

### Method 3: Build a Native Debian Package (`.deb`)

*(For Ubuntu, Debian, Linux Mint, Pop!_OS)*

```bash
./build-deb.sh ~/Downloads/"Antigravity IDE.tar.gz"
```

This generates `antigravity-ide_<version>_amd64.deb`. Install it with:

```bash
sudo apt install ./antigravity-ide_*.deb
```

---

### Method 4: Build on Arch Linux (`PKGBUILD`)

*(For Arch Linux, Manjaro, EndeavourOS)*

1. Copy your downloaded `Antigravity IDE.tar.gz` into `packaging/arch/`.
2. Build and install via `makepkg`:
```bash
cd packaging/arch
makepkg -si
```

---

## What Gets Configured

| Component | Target Location | Description |
| :--- | :--- | :--- |
| **Application Core** | `~/Applications/antigravity-ide/` | Full user-local install (isolated, no root needed) |
| **Terminal CLI** | `~/.local/bin/antigravity-ide`<br>`~/.local/bin/agy-ide` | Points to CLI wrapper script (`bin/antigravity-ide`) |
| **Desktop Launcher** | `~/.local/share/applications/antigravity-ide.desktop` | Freedesktop launcher with window matching and search keywords |
| **Icon Suite** | `~/.local/share/icons/hicolor/<size>/apps/` | Standard resolutions (`16px`, `24px`, `32px`, `48px`, `64px`, `128px`, `256px`, `512px`) |
| **Shell Completions** | `~/.local/share/bash-completion/completions/`<br>`~/.local/share/zsh/site-functions/`<br>`~/.local/share/fish/vendor_completions.d/` | Tab completions for command flags and arguments |
| **MIME / Protocol** | `~/.local/share/mime/packages/antigravity-ide.xml` | Associates `antigravity-ide://` URL scheme and workspaces |
| **Uninstaller** | `~/Applications/antigravity-ide/uninstall.sh` | Clean single-command uninstaller |

---

## Optional: GNOME (Nautilus) Right-Click Extension

In GNOME desktop environments, top-level right-click menu integration requires the Nautilus Python library. Install it using your distribution's package manager before running the installer:

* **Ubuntu / Debian / Linux Mint**:
  ```bash
  sudo apt install python3-nautilus
  ```
* **Fedora**:
  ```bash
  sudo dnf install nautilus-python
  ```
* **Arch Linux / Manjaro**:
  ```bash
  sudo pacman -S python-nautilus
  ```
* **openSUSE**:
  ```bash
  sudo zypper in python3-nautilus
  ```

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
