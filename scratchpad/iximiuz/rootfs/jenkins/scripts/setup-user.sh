#!/bin/bash
set -euo pipefail

#######################################################################
# User Setup Script
#
# This script creates a non-root user with sudo privileges.
#
# Usage:
#   ./setup-user.sh USERNAME [UID] [GID]
#
# Arguments:
#   USERNAME - Username to create (required)
#   UID      - User ID (default: 1000)
#   GID      - Group ID (default: 1000)
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

USERNAME=${1:-ubuntu}
USER_UID=${2:-1000}
USER_GID=${3:-1000}

echo "==============================="
echo "Setting up user: ${USERNAME}"
echo "==============================="

# Validate username
if [ -z "${USERNAME}" ]; then
    echo "ERROR: Username cannot be empty"
    exit 1
fi

# Check if user already exists
if id "${USERNAME}" &>/dev/null; then
    echo "⚠ User '${USERNAME}' already exists, skipping creation"
else
    # Create group
    echo "Creating group '${USERNAME}' with GID ${USER_GID}..."
    groupadd --gid ${USER_GID} ${USERNAME}

    # Create user
    echo "Creating user '${USERNAME}' with UID ${USER_UID}..."
    useradd --uid ${USER_UID} \
            --gid ${USER_GID} \
            --shell /bin/bash \
            --create-home \
            --comment "CI/CD User" \
            ${USERNAME}

    echo "✓ User created successfully"
fi

# Setup sudo permissions
echo "Configuring sudo permissions..."
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}
chmod 0440 /etc/sudoers.d/${USERNAME}

# Create user directories
echo "Creating user directories..."
mkdir -p /home/${USERNAME}/.ssh
mkdir -p /home/${USERNAME}/.config
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
chmod 700 /home/${USERNAME}/.ssh

# ~/.bashrc — Non-login interactive shells (docker exec, tmux, etc.)
cat > /home/${USERNAME}/.bashrc << 'EOF'
# ~/.bashrc: executed by bash for non-login interactive shells
# PATH, JAVA_HOME, PS1 are set via /etc/profile.d/jenkins-env.sh for login shells.
# This file handles aliases, history, and interactive-only settings.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Color support for ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Navigation
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Jenkins
alias jenkins-status='sudo systemctl status jenkins'
alias jenkins-logs='sudo tail -f /var/log/jenkins/jenkins.log'
alias jenkins-restart='sudo systemctl restart jenkins'

# Nginx
alias nginx-status='sudo systemctl status nginx'
alias nginx-logs='sudo tail -f /var/log/nginx/jenkins-access.log'
alias nginx-reload='sudo systemctl reload nginx'

# Editor
export EDITOR=vim
export VISUAL=vim
EOF

chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc
echo "✓ .bashrc created for ${USERNAME}"

# Add user to common groups
echo "Adding user to common groups..."
usermod -aG sudo ${USERNAME}
usermod -aG docker ${USERNAME} 2>/dev/null || echo "  (docker group not available)"

# Set default password (allows SSH password authentication)
# Change in production or inject via SSH keys instead
echo "${USERNAME}:${USERNAME}" | chpasswd
echo "✓ Default password set for ${USERNAME}"

# Display user info
echo ""
echo "✓ User setup completed successfully"
echo "  Username : ${USERNAME}"
echo "  UID      : ${USER_UID}"
echo "  GID      : ${USER_GID}"
echo "  Home     : /home/${USERNAME}"
echo "  Shell    : /bin/bash"
echo "  Sudo     : Enabled (NOPASSWD)"
id ${USERNAME}
