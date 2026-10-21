# Ubuntu Homelab Environment

This directory contains the complete port of **termux_bootstrap** and **termux_scripting** tailored specifically for **Ubuntu Linux** systems (such as Ubuntu Server, Ubuntu Desktop, Intel NUCs, Raspberry Pi running Ubuntu, or cloud VMs).

---

## Directory Structure

```text
ubuntu/
├── bootstrap/               # System bootstrap (packages, SSH, shell configs, startup motd)
│   ├── bootstrap.sh         # Main entry point to run bootstrap sequence
│   ├── 01-system.sh         # System updates & OS check
│   ├── 02-packages.sh       # APT packages, starship, zoxide, fastfetch, bat
│   ├── 03-ssh.sh            # SSH server user setup
│   ├── 04-directories.sh    # Directory structure initialization
│   ├── 05-config.sh         # Copies configs (.zshrc, .bashrc, .tmux.conf, motd)
│   ├── 06-services.sh       # Systemd service configuration (ssh, cron)
│   ├── 07-env.sh            # Creates .env secrets file
│   ├── 08-opt-packages.sh   # Python, uv, rclone installation
│   ├── config/              # Shell, tmux, SSH configs & startup scripts
│   └── README.md
│
├── scripting/               # Homelab control layer & utilities
│   ├── orchestrator.sh      # Installs CLI into ~/system_scripts/control-layer & PATH
│   ├── control-layer/       # All homelab subcommands (status, app-up, wifi, etc.)
│   ├── github-backup/       # GitHub repository backup tool
│   ├── Tasks.md
│   └── README.md
│
└── README.md
```

---

## What was Adapted from Termux to Ubuntu

1. **Package Management**:
   - Replaced `pkg install` with `apt install`.
   - Mapped packages to Debian/Ubuntu equivalents (e.g. `openssh-server`, `openssh-client`, `cron`, `net-tools`, `batcat`).
   - Integrated official installers for `starship`, `zoxide`, and Astral `uv`.
   - Handled Ubuntu `bat` naming (`batcat` symlinked to `bat`).

2. **Service Management**:
   - Replaced Termux `termux-services` (`sv-enable`, `sv up`) with standard Ubuntu `systemd` (`systemctl enable`, `systemctl restart`).

3. **Hardware & Power Monitoring**:
   - Replaced `termux-battery-status` with direct Linux sysfs `/sys/class/power_supply/BAT*` and `upower` checks.
   - Handled non-battery environments (desktops, mini-PCs, homelab servers, VMs) without errors.
   - Replaced `/sys/class/thermal/thermal_zone0/temp` hardcodes with dynamic zone discovery and `lm-sensors`.

4. **Network & Interfaces**:
   - Replaced hardcoded `wlan0` / `tun0` lookups with dynamic discovery supporting WiFi (`wl*`), Ethernet (`eth*`, `en*`), and Tailscale (`tailscale0` / `tun0` / `tailscale ip -4`).

5. **Storage**:
   - Replaced Android `/data` mountpoint checks with root `/` partition.

6. **Audio & Notifications**:
   - Termux audio playback (`termux-media-player`) was safely dropped as specified.
   - Termux notifications were ported to Linux `notify-send` (if desktop/DBUS session is active) plus persistent logging to `$HOME/logs/ssh_login.log`.

7. **Paths & Portability**:
   - Removed Termux `$PREFIX` paths (`/data/data/com.termux/...`), replacing them with standard Linux FHS paths (`/etc`, `/usr/bin`, `~/.local/bin`, `~/.config`).
   - Fixed Windows/Termux hardcoded paths in `github-backup.py`.

---

## Quick Start on Ubuntu

### 1. Bootstrap the System
```bash
cd ubuntu/bootstrap
bash bootstrap.sh
```

### 2. Install the Homelab Control Layer
```bash
cd ubuntu/scripting
bash orchestrator.sh
source ~/.bashrc   # or source ~/.zshrc
```

### 3. Use the CLI
```bash
homelab status
homelab app-list
homelab app-up melodious
```

