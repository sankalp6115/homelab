# Ubuntu Bootstrap

A clean, automated bootstrap setup for turning a fresh Ubuntu installation (desktop, server, or mini-PC) into a standardized homelab development environment.

## What this setup does

This directory replicates and ports the bootstrap automation from Termux to Ubuntu:

- Updates the Ubuntu system and apt package indices
- Installs core utilities: `git`, `curl`, `wget`, `nano`, `vim`, `openssh-server`, `zsh`, `tmux`, `rsync`, `starship`, `zoxide`, `fastfetch`, `bat`, `jq`, `fzf`, `cron`, etc.
- Configures SSH server access and enables systemd `ssh` service
- Sets up standard project folders (`~/archives`, `~/backups`, `~/logs`, `~/media`, `~/.local/bin`)
- Deploys shell configurations (`.zshrc`, `.bashrc`, `.tmux.conf`, `.nanorc`, `.aliases`)
- Deploys startup and login hooks (`ssh_login.sh`, `motd.sh`, `interface.sh`, `storage_management.sh`, `battery.sh`, `weather.sh`)
- Prepares Python 3 development environment, `rclone`, and `uv`

## Quick start

On a fresh Ubuntu installation:

```bash
cd ubuntu/bootstrap
bash bootstrap.sh
```

## Structure

- `bootstrap.sh`: main orchestrator running each step in sequence
- `01-system.sh`: system update and hardware/kernel summary
- `02-packages.sh`: installs core apt packages, starship prompt, and tools
- `03-ssh.sh`: configures SSH access and permissions
- `04-directories.sh`: creates home and project directories
- `05-config.sh`: installs configuration files and startup scripts
- `06-services.sh`: enables and tests systemd services (SSH, cron)
- `07-env.sh`: initializes secure `.env` secrets file
- `08-opt-packages.sh`: installs Python 3, uv, build tools, and rclone
- `config/`: template configuration files and startup scripts

