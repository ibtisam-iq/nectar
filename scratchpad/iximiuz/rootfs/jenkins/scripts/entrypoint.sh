#!/bin/bash
set -e

#######################################################################
# Container Entrypoint Script
#
# Initializes the Jenkins rootfs environment on boot.
#
# This image is designed for iximiuz Labs playgrounds (VM-like, full systemd):
# - systemd runs as PID 1 (CMD ["/lib/systemd/systemd"] in Dockerfile)
# - Services (sshd, nginx, jenkins) are managed by systemd units
# - No manual starts here — only one-time setup and permissions
# - Manual starts would conflict with systemd (port bind, duplicate processes)
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo " Jenkins Rootfs Initialization (iximiuz Labs VM)"
echo "=========================================="
echo ""

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# ---------------------------------------------------------------------
# Jenkins Home — Permissions
# ---------------------------------------------------------------------
if [ -d /var/lib/jenkins ]; then
    log "Setting Jenkins home directory permissions..."
    chown -R jenkins:jenkins /var/lib/jenkins
    chmod -R 755 /var/lib/jenkins
    echo -e "${GREEN}✓${NC} Jenkins home permissions set"
fi

# ---------------------------------------------------------------------
# SSH — Host Keys
# ---------------------------------------------------------------------
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    log "Generating SSH host keys..."
    ssh-keygen -A
    echo -e "${GREEN}✓${NC} SSH host keys generated"
else
    log "SSH host keys already exist"
fi

# ---------------------------------------------------------------------
# SSH — Privilege Separation Directory
# ---------------------------------------------------------------------
# Required for sshd (tmpfs wipes /run at boot)
mkdir -p /run/sshd
chmod 755 /run/sshd

# ---------------------------------------------------------------------
# Runtime Directories for Services
# ---------------------------------------------------------------------
mkdir -p /run/nginx
mkdir -p /var/log/jenkins
mkdir -p /var/log/nginx

# Jenkins workspace ownership (if exists)
if [ -d /var/lib/jenkins/workspace ]; then
    chown -R jenkins:jenkins /var/lib/jenkins/workspace
fi

# ---------------------------------------------------------------------
# Reload systemd to apply any unit overrides
# ---------------------------------------------------------------------
log "Reloading systemd daemon to apply unit overrides..."
systemctl daemon-reload || true  # Safe if no systemd yet
echo -e "${GREEN}✓${NC} Systemd daemon reloaded"

# ---------------------------------------------------------------------
# System Information (useful for first boot logs)
# ---------------------------------------------------------------------
log "System Information:"
echo " - Hostname : $(hostname)"
echo " - OS : $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo " - Java : $(java -version 2>&1 | head -n 1)"
echo " - Jenkins Home : /var/lib/jenkins"
echo " - Jenkins Port : ${JENKINS_PORT:-8080}"
echo " - Interactive User : ${USERNAME:-ubuntu}"
echo " - Services : Managed by systemd (sshd, nginx, jenkins)"
echo ""
echo "=========================================="
echo " Initialization complete. Handing off to systemd."
echo "=========================================="
echo ""

# Create/update MOTD with clean Cloudflare Tunnel instructions (Feb 2026 dashboard flow)
cat << 'EOF' > /etc/motd

Welcome to SilverStack Jenkins Lab (iximiuz Labs VM)

Jenkins is running internally at http://localhost:8080
Nginx reverse proxy listening on port 80 (internal)

To make Jenkins publicly accessible with your own custom domain:

1. Go to https://one.dash.cloudflare.com → Zero Trust → Networks → Connectors
2. Click "Create a tunnel" → give it a name (e.g. jenkins-lab)
3. Choose "Cloudflared" connector
4. Copy the single command shown in the dashboard
   It looks like this:
   sudo cloudflared service install eyJhIjoi... (long token)

5. In this VM, paste and run that command exactly as shown.
   It will:
   - Register your tunnel token
   - Create/update the systemd service (/etc/systemd/system/cloudflared.service)
   - Start and enable the service
   - Connect your tunnel immediately

6. Back in the dashboard → "Route Traffic" → Add a public hostname:
   - Subdomain: jenkins (or any name you want)
   - Domain: your domain (e.g. ibtisam-iq.com)
   - Path: (leave blank for all paths)
   - Service Type: HTTP
   - URL: localhost:8080

Your Jenkins is now live at https://jenkins.yourdomain.com (with SSL & DDoS protection)

Happy CI/CD building!
EOF

echo -e "${GREEN}✓${NC} MOTD updated with clean Cloudflare Tunnel instructions"

# Hand off to systemd (PID 1)
exec "$@"
