#!/bin/bash
# custom-shell.sh – custom login shell for ubuntu user
# Shows welcome only for interactive sessions; passes through SSH commands

# If arguments passed = non-interactive SSH command (key injection, scp, etc.)
# Skip the welcome entirely and execute directly
if [ $# -gt 0 ]; then
    exec /bin/bash "$@"
fi

# Interactive login only — show welcome
clear

cat << 'EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║           SilverStack Jenkins Lab – Quick Setup Guide        ║
  ╚══════════════════════════════════════════════════════════════╝

  Jenkins is running internally at http://localhost:8080
  Nginx reverse proxy listening on port 80 (internal)

  ── Make Jenkins Public with Cloudflare Tunnel ──────────────────

  1. https://one.dash.cloudflare.com
       → Zero Trust → Networks → Connectors

  2. Create a tunnel → name it (e.g. jenkins-lab)
     Choose "Cloudflared" connector

  3. Copy and run the install command shown:
       sudo cloudflared service install <long-token>

     This will:
       - Register the token
       - Create/update the systemd service
       - Start & enable the service
       - Connect the tunnel

  4. Back in dashboard → Route Traffic → Add public hostname:
       Subdomain : jenkins (or any name)
       Domain    : your-domain.com
       Path      : (leave blank)
       Service   : HTTP → localhost:8080

  Jenkins is now live at https://jenkins.your-domain.com
  (SSL + DDoS protection included)

  ── Useful Commands ─────────────────────────────────────────────

  sudo systemctl status jenkins        # Jenkins status
  sudo systemctl status nginx          # Nginx status
  sudo journalctl -u jenkins -f        # Jenkins logs (live)
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword

  ────────────────────────────────────────────────────────────────
  Happy CI/CD building!

EOF

# Resolve current user's home directory dynamically
# $HOME is set by PAM/sshd before this shell is invoked
RCFILE="${HOME}/.bashrc"

if [ -f "${RCFILE}" ]; then
    exec /bin/bash --rcfile "${RCFILE}"
else
    exec /bin/bash
fi
