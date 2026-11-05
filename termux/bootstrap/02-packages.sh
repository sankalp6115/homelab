#!/usr/bin/env bash
set -euo pipefail

echo "Installing essential packages via pkg..."

pkg install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    openssh \
    nodejs-lts \
    openssl \
    zip \
    unzip \
    tar \
    tur-repo \
    iproute2 \
    zsh \
    tmux \
    rsync \
    termux-tools \
    termux-services \
    tree \
    fastfetch \
    starship \
    cronie \
    bat \
    jq \
    fzf \
    zoxide

echo "Core packages installed successfully."
