# ~/.bashrc - Ubuntu Homelab Environment

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# PATH additions
export PATH="$HOME/.local/bin:$HOME/system_scripts/control-layer:$PATH"

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd cd)"
fi

alias python='python3'
alias pip='pip3'
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi

CONFIG_ROOT="$HOME/.config/ubuntu-bootstrap"

if [[ -f "$HOME/.aliases" ]]; then
    . "$HOME/.aliases"
fi

# SSH Login hook
if [[ -n "${SSH_CLIENT:-}" ]]; then
    SSH_SCRIPT="$CONFIG_ROOT/scripts/ssh_login.sh"
    if [[ -f "$SSH_SCRIPT" ]]; then
        bash "$SSH_SCRIPT"
    fi
fi

# Safe Trash functions
trash() {
    local TRASH_DIR="$HOME/.local/trash"
    mkdir -p "$TRASH_DIR"
    if [ $# -eq 0 ]; then
        echo "Usage: trash <file_or_directory>"
        return 1
    fi
    mv -f "$@" "$TRASH_DIR/"
    echo "Moved to trash: $@"
}

empty-trash() {
    local TRASH_DIR="$HOME/.local/trash"
    if [ -d "$TRASH_DIR" ]; then
        rm -rf "$TRASH_DIR"/*
        echo "Trash emptied."
    else
        echo "Trash is already empty."
    fi
}

alias rm='trash'

# Custom MOTD
if [[ -f "$CONFIG_ROOT/scripts/motd.sh" ]]; then
    bash "$CONFIG_ROOT/scripts/motd.sh"
elif [[ -f "/etc/motd.sh" ]]; then
    bash "/etc/motd.sh"
fi

