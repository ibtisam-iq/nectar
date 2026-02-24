#!/bin/bash
set -euo pipefail

#######################################################################
# install-cloudflared.sh
#
# Installs the official Cloudflare cloudflared package from their apt repository.
# This is the recommended way as of 2026 (uses cloudflare-public-v2.gpg repo).
#
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

echo "========================================"
echo "Installing cloudflared (official repo)"
echo "========================================"

# 1. Create keyrings directory with correct permissions
echo "Creating /usr/share/keyrings directory..."
sudo mkdir -p --mode=0755 /usr/share/keyrings

# 2. Download and install Cloudflare's public GPG key
echo "Adding Cloudflare GPG key..."
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | \
    sudo tee /usr/share/keyrings/cloudflare-public-v2.gpg > /dev/null

# 3. Add the official Cloudflare apt repository
echo "Adding Cloudflare apt repository..."
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | \
    sudo tee /etc/apt/sources.list.d/cloudflared.list

# 4. Update package index and install cloudflared
echo "Updating apt index and installing cloudflared..."
sudo apt-get update -y && \
    sudo apt-get install -y cloudflared

# 5. Verify installation
echo "Verifying cloudflared installation..."
cloudflared --version

echo ""
echo "✓ cloudflared installed successfully"
echo "  - Binary: $(which cloudflared)"
echo "  - Version: $(cloudflared --version)"
