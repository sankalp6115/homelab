# ~/.zshrc - Homelab Environment

# PATH additions
export PATH="$HOME/.local/bin:$HOME/system_scripts/control-layer:$PATH"

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# Aliases
alias python='python3'
alias pip='pip3'
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi

CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"

if [[ -f "$HOME/.aliases" ]]; then
    . "$HOME/.aliases"
fi

# SSH Login hook
if [[ -o interactive && -n "${SSH_CLIENT:-}" ]]; then
    SSH_SCRIPT="$CONFIG_ROOT/scripts/ssh_login.sh"
    if [[ -f "$SSH_SCRIPT" ]]; then
        bash "$SSH_SCRIPT"
    fi
fi

# Custom MOTD
if [[ -o interactive ]]; then
    if [[ -f "$CONFIG_ROOT/scripts/motd.sh" ]]; then
        bash "$CONFIG_ROOT/scripts/motd.sh"
    elif [[ -f "${PREFIX:-}/etc/motd.sh" ]]; then
        bash "$PREFIX/etc/motd.sh"
    elif [[ -f "/etc/motd.sh" ]]; then
        bash "/etc/motd.sh"
    fi
fi
