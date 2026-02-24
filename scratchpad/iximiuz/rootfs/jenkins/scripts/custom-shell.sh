#!/bin/bash
# custom-shell.sh – overrides default shell to show only our message

# Clear screen (optional – removes any previous output)
clear

cat << 'EOF'

SilverStack Jenkins Lab – Quick Setup Guide

Jenkins is running internally at http://localhost:8080
Nginx reverse proxy listening on port 80 (internal)

To make Jenkins public with your custom domain:

1. https://one.dash.cloudflare.com → Zero Trust → Networks → Connectors
2. Create a tunnel → name it (e.g. jenkins-lab)
3. Choose "Cloudflared" connector
4. Copy the command shown:
   sudo cloudflared service install <long-token>

5. Paste & run it here in this terminal. It will:
   - Register the token
   - Create/update systemd service
   - Start & enable the service
   - Connect the tunnel

6. Back in dashboard → Route Traffic → Add public hostname:
   - Subdomain: jenkins (or any name)
   - Domain: your domain
   - Path: (leave blank)
   - Service Type: HTTP
   - URL: localhost:8080

Jenkins is now live at https://jenkins.yourdomain.com (SSL + DDoS protection)

Happy CI/CD building!
EOF

# Exec real bash (preserves all environment)
exec /bin/bash "$@"
