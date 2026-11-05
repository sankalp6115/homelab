# Ubuntu Homelab Environment

This directory contains the port of the homelab environment tailored specifically for **Ubuntu Linux** systems (such as Ubuntu Server, Ubuntu Desktop, Intel NUCs, Raspberry Pi running Ubuntu, WSL, or cloud VMs).

---

## Directory Structure

```text
ubuntu/
├── bootstrap/               # System bootstrap (packages, SSH, shell configs, login motd)
│   ├── bootstrap.sh         # Main entry point to run bootstrap sequence
│   ├── 01-system.sh         # System updates & OS check
│   ├── 02-packages.sh       # APT packages, starship, zoxide, fastfetch, bat
│   ├── 03-ssh.sh            # SSH server user setup
│   ├── 04-directories.sh    # Directory structure initialization
│   ├── 05-config.sh         # Copies configs (.zshrc, .bashrc, .tmux.conf, motd)
│   ├── 06-services.sh       # Systemd service configuration (ssh, cron)
│   ├── 07-env.sh            # Creates .env secrets file
│   ├── 08-opt-packages.sh   # Python, uv, rclone installation
│   ├── config/              # Shell, tmux, SSH configs & startup banners
│   └── README.md
│
├── control-layer/           # Homelab control layer CLI & subcommands
│   ├── orchestrator.sh      # Installs CLI into ~/system_scripts/control-layer & PATH
│   ├── homelab.sh           # Main unified CLI
│   ├── app-port-map.ini     # App-to-port mapping registry
│   └── *.sh                 # Commands: status, app-*, battery, wifi, storage, ports, etc.
│
├── github-backup/           # GitHub repository backup tool
│   ├── github-backup.py
│   └── .env.example
│
└── README.md
```

---

## What was Adapted from Termux to Ubuntu

1. **Package Management**:
   - Replaced `pkg install` with `apt install`.
   - Mapped packages to Debian/Ubuntu equivalents (`openssh-server`, `openssh-client`, `cron`, `net-tools`, `batcat`).
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
   - Desktop notifications via `notify-send` (if desktop/DBUS session is active) plus persistent logging to `$HOME/logs/ssh_login.log`.

7. **Paths & Portability**:
   - Removed Termux `$PREFIX` paths, replacing them with standard Linux FHS paths (`/etc`, `/usr/bin`, `~/.local/bin`, `~/.config`).
   - Unified config root to `~/.config/homelab`.

---

## Quick Start on Ubuntu

### 1. Bootstrap the System
```bash
cd ubuntu/bootstrap
bash bootstrap.sh
```

### 2. Install the Homelab Control Layer
```bash
cd ubuntu/control-layer
bash orchestrator.sh
source ~/.bashrc   # or source ~/.zshrc
```

### 3. Use the CLI
```bash
homelab status
homelab app-list
homelab app-up melodious
```
