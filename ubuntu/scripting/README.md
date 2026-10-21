# homelab_scripting for Ubuntu

A collection of shell scripts for managing a self-hosted homelab running on **Ubuntu Linux**. Provides a unified `homelab` CLI to monitor system health, manage Python-based apps, sync music, and back up GitHub repositories — all from the terminal.

---

## Overview

```bash
homelab status          # Full system dashboard (CPU, RAM, storage, battery, network, services)
homelab app-list        # List all apps and their running state
homelab app-up <app>    # Start an app
homelab app-down <app>  # Stop an app
homelab app-restart <app> # Restart an app
homelab app-logs <app>  # Attach to the app's tmux session
homelab battery         # Detailed power/battery report
homelab wifi            # WiFi/Ethernet connection status
homelab storage         # Storage usage for root partition
homelab ports           # Active Python listening ports
homelab music-sync      # Sync songs from rclone remote → melodious
```

All commands are available globally after running `orchestrator.sh` once. The scripts are installed to `~/system_scripts/control-layer/` which is added to `$PATH`.

---

## Requirements

| Tool | Purpose | Ubuntu Package |
|---|---|---|
| `bash` | Shell runtime | Built-in |
| `jq` | JSON parsing | `jq` |
| `tmux` | App process management | `tmux` |
| `rclone` | Music sync from remote storage | `rclone` |
| `python3` / `uv` | Running homelab apps | `python3`, `python3-pip`, `uv` |
| `git` | Repo update command | `git` |
| `iproute2` / `net-tools` | IP and network info | `iproute2`, `net-tools` |

Install via apt on Ubuntu:
```bash
sudo apt update && sudo apt install -y jq tmux rclone git python3 python3-pip iproute2 net-tools
```

---

## Installation

Run the orchestrator from this folder:

```bash
cd ubuntu/scripting
bash orchestrator.sh
source ~/.bashrc   # or source ~/.zshrc
```

What `orchestrator.sh` does:
- Creates `~/system_scripts/control-layer/`
- Copies every script from `control-layer/` as `homelab-<name>` (and `homelab` for the main CLI)
- Copies `app-port-map.ini` and companion configuration files
- Syncs the `github-backup/` folder to `~/system_scripts/github-backup/`
- Adds `~/system_scripts/control-layer` to `$PATH` in both `~/.bashrc` and `~/.zshrc` (idempotent)
- Cleans up stale files from previous installs

---

## Commands Reference

- `homelab status`: Full dashboard including hostname, uptime, CPU, RAM, storage, battery, temperature, services (`ssh`, `tailscaled`, `syncthing`, `tmux`), network IPs, and open ports.
- `homelab app-list`: Table of configured apps in `app-port-map.ini` with colored running/stopped indicator.
- `homelab app-up <app>`: Starts an app by invoking its `start.sh`.
- `homelab app-down <app>`: Finds running process by port and stops it.
- `homelab app-restart <app>`: Stops and relaunches the app.
- `homelab app-logs <app>`: Attaches to the app's tmux session (`Ctrl+B D` to detach).
- `homelab app-status <app>`: Checks status and PID for a specific app.
- `homelab battery`: Queries `/sys/class/power_supply` or upower. Works on laptops and handles AC-powered servers gracefully.
- `homelab wifi`: Network information (SSID, Gateway, IP, Link Speed, Frequency).
- `homelab storage`: Reports root partition usage.
- `homelab ports`: Scans Python processes running with `--port`.
- `homelab music-sync`: Dry-run preview and sync of songs via `rclone`, updates database, restarts player.
- `homelab update`: Pulls updates from git.

