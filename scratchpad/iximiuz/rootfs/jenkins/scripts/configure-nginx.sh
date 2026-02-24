#!/bin/bash
set -euo pipefail

#######################################################################
# Nginx Configuration Script
#
# This script configures Nginx as reverse proxy for Jenkins.
#
# Usage:
#   ./configure-nginx.sh
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

echo "==========================="
echo "Configuring Nginx for Jenkins"
echo "==========================="

# Verify Nginx configuration exists
if [ ! -f /etc/nginx/sites-available/jenkins ]; then
    echo "ERROR: Nginx configuration file not found: /etc/nginx/sites-available/jenkins"
    exit 1
fi

# Remove default site if exists
echo "Removing default Nginx site..."
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm -f /etc/nginx/sites-enabled/default
    echo "✓ Removed default site"
fi

# Enable Jenkins site
echo "Enabling Jenkins site..."
ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/jenkins

# Create log directories
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

echo ""
echo "✓ Nginx configured successfully"
echo "  Config: /etc/nginx/sites-available/jenkins"
echo "  Enabled: /etc/nginx/sites-enabled/jenkins"
echo "  Logs: /var/log/nginx/jenkins-*.log"

# ---------------------------------------------------------------------
# Systemd Service Override
# ---------------------------------------------------------------------
# The stock nginx.service uses Type=forking + PID file daemonization,
# which fails in containerized systemd environments (exits 255).
# Override to run nginx in foreground (Type=simple + daemon off),
# which is the correct mode for systemd-managed containers.
#
# ExecStartPre=/ExecStart=/ExecReload= with empty value first clears
# the inherited list from the stock unit before setting new commands.
# ---------------------------------------------------------------------
echo "Creating nginx systemd override for container compatibility..."
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf << 'EOF'
[Service]
# Minimal changes for systemd VM compatibility
Type=simple
KillSignal=SIGQUIT
TimeoutStopSec=5
ExecStartPre=
ExecStartPre=/usr/sbin/nginx -t
ExecStart=
ExecStart=/usr/sbin/nginx -g 'daemon off;'
ExecReload=
ExecReload=/usr/sbin/nginx -s reload
EOF
echo "✓ Nginx systemd override created"

# Note: daemon-reload is done at boot in entrypoint.sh
echo "Note: systemd daemon-reload will run at boot to apply override"
