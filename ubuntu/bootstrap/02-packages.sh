#!/usr/bin/env bash
set -e

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

echo "Installing essential packages via apt..."

$SUDO apt update
$SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    openssh-server \
    openssh-client \
    nodejs \
    npm \
    openssl \
    zip \
    unzip \
    tar \
    iproute2 \
    zsh \
    tmux \
    rsync \
    tree \
    jq \
    fzf \
    cron \
    net-tools \
    upower \
    lm-sensors \
    libnotify-bin \
    procps \
    bat

# Fix 'bat' command on Ubuntu where binary is installed as 'batcat'
mkdir -p "$HOME/.local/bin"
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    echo "✓ Linked batcat -> ~/.local/bin/bat"
fi

# Install zoxide if not installed
if ! command -v zoxide >/dev/null 2>&1; then
    echo "Installing zoxide..."
    if $SUDO apt install -y zoxide 2>/dev/null; then
        echo "✓ Installed zoxide via apt"
    else
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        echo "✓ Installed zoxide via official installer"
    fi
fi

# Install starship prompt if not installed
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "✓ Installed starship prompt"
fi

# Install fastfetch if not installed
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Installing fastfetch..."
    if $SUDO apt install -y fastfetch 2>/dev/null; then
        echo "✓ Installed fastfetch via apt"
    else
        # Try adding PPA or installing neofetch as fallback
        $SUDO add-apt-repository -y ppa:zhangsongcui3371/fastfetch 2>/dev/null && \
        $SUDO apt update 2>/dev/null && \
        $SUDO apt install -y fastfetch 2>/dev/null || {
            echo "Fastfetch PPA not available, installing neofetch fallback..."
            $SUDO apt install -y neofetch 2>/dev/null || true
        }
    fi
fi

echo "Core packages installed successfully."

