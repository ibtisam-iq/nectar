https://nginx.org/en/linux_packages.html

Ubuntu
```bash
# Install the prerequisites:
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# Import an official nginx signing key so apt could verify the packages authenticity. Fetch the key:

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Verify that the downloaded file contains the proper key:

gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

# To set up the apt repository for stable nginx packages, run the following command:

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

# To install nginx, run the following commands:

sudo apt update
sudo apt install nginx -y
```

1. Install Nginx:
2. Create Nginx configuration

```bash
sudo vi /etc/nginx/sites-available/ibtisam-iq.com
sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf

# Enable the new configuration:
sudo ln -s /etc/nginx/sites-available/ibtisam-iq.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Configure HTTPS
sudo apt install -y certbot python3-certbot-nginx
# sudo certbot --nginx -d ibtisam-iq.com -d www.ibtisam-iq.com
sudo certbot certonly --standalone -d ibtisam-iq.com -d www.ibtisam-iq.com
sudo ls /etc/letsencrypt/live/ibtisam-iq.com
sudo certbot renew --dry-run
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🗺️ Master Cheat Sheet

| Topic | Ubuntu / Debian | CentOS / RHEL |
|---|---|---|
| Install command | `apt install nginx` | `yum install nginx` |
| Web root | `/var/www/html/` | `/usr/share/nginx/html/` |
| Main config | `/etc/nginx/nginx.conf` | `/etc/nginx/nginx.conf` |
| Site config | `/etc/nginx/sites-enabled/default` | `/etc/nginx/conf.d/default.conf` |
| Error logs | `/var/log/nginx/error.log` | `/var/log/nginx/error.log` |
| Access logs | `/var/log/nginx/access.log` | `/var/log/nginx/access.log` |
| Check config | `sudo nginx -t` | `sudo nginx -t` |
| Restart | `sudo systemctl restart nginx` | `sudo systemctl restart nginx` |


---

## 📄 `scripts/ec2-user-data.sh`

```bash
#!/bin/bash
# =============================================================================
# EC2 User Data Script — Nginx Auto Setup
# =============================================================================
# PURPOSE:
#   This script runs automatically when an EC2 instance first boots.
#   It installs Nginx and sets a custom webpage so you can identify
#   which server is receiving traffic in an Auto Scaling Group.
#
# HOW TO USE:
#   Paste this script into the "User Data" field when launching an EC2 instance
#   or creating a Launch Template for your Auto Scaling Group.
#
# WHAT IT DOES:
#   1. Updates the package list (so we get the latest version of Nginx)
#   2. Installs Nginx
#   3. Writes a custom HTML page to the correct web root for Ubuntu
#   4. Restarts Nginx so the new page is served immediately
# =============================================================================

# Step 1 — Update package list
# Why: Without this, apt might try to install an outdated version of Nginx
#      or fail because the package index is empty on a fresh instance.
sudo apt update -y

# Step 2 — Install Nginx
# Why: A fresh EC2 Ubuntu instance has no web server installed.
#      The -y flag automatically answers "yes" to all prompts.
sudo apt install nginx -y

# Step 3 — Write a custom HTML page
# Why: We use "tee" with sudo because the shell's ">" redirect does NOT
#      inherit sudo privileges. tee is the program writing the file,
#      so it runs as root and has permission to write to /var/www/html/.
#
# IMPORTANT: On Ubuntu, the web root is /var/www/html/ (NOT /usr/share/nginx/html/)
#
# Change "London" to "Mumbai" on your second server so you can tell them apart
# when testing your Load Balancer and Auto Scaling Group.

echo "<h1>Love you Ibtisam from London</h1>" | sudo tee /var/www/html/index.html

# Step 4 — Restart Nginx
# Why: Nginx needs to be restarted to pick up and serve the new index.html.
#      Without this, the old default page may still be cached in memory.
sudo systemctl restart nginx

# Step 5 — Enable Nginx on boot
# Why: If the EC2 instance is stopped and started again, Nginx will not
#      start automatically unless we enable it as a systemd service.
sudo systemctl enable nginx

# =============================================================================
# VERIFICATION (run these manually after SSH-ing in):
#   curl http://localhost                          → should show your message
#   cat /var/www/html/index.html                  → confirm file content
#   sudo systemctl status nginx                   → confirm nginx is running
#   grep "root" /etc/nginx/sites-enabled/default  → confirm web root path
# =============================================================================
```

***

## 📄 `scripts/install-ubuntu.sh`

```bash
#!/bin/bash
# =============================================================================
# Nginx Installation Script — Ubuntu / Debian
# =============================================================================

set -e  # Stop the script immediately if any command fails

echo "==> Step 1: Updating package index..."
sudo apt update -y

echo "==> Step 2: Installing Nginx..."
sudo apt install nginx -y

echo "==> Step 3: Starting Nginx service..."
sudo systemctl start nginx

echo "==> Step 4: Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo "==> Step 5: Checking Nginx status..."
sudo systemctl status nginx --no-pager

echo ""
echo "✅ Nginx installed successfully!"
echo "   Web root: /var/www/html/"
echo "   Config:   /etc/nginx/sites-enabled/default"
echo "   Logs:     /var/log/nginx/"
echo ""
echo "   To set a custom page, run:"
echo "   echo 'Hello World' | sudo tee /var/www/html/index.html"
```

***

## 📄 `scripts/install-centos.sh`

```bash
#!/bin/bash
# =============================================================================
# Nginx Installation Script — CentOS / RHEL / Amazon Linux 2
# =============================================================================

set -e

echo "==> Step 1: Installing Nginx..."
sudo yum install nginx -y   # Use "dnf" instead of "yum" on Amazon Linux 2023

echo "==> Step 2: Starting Nginx service..."
sudo systemctl start nginx

echo "==> Step 3: Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo "==> Step 4: Opening port 80 in firewall (if firewalld is active)..."
sudo firewall-cmd --permanent --add-service=http 2>/dev/null || echo "firewalld not active, skipping"
sudo firewall-cmd --reload 2>/dev/null || true

echo ""
echo "✅ Nginx installed successfully!"
echo "   Web root: /usr/share/nginx/html/"
echo "   Config:   /etc/nginx/conf.d/default.conf"
echo "   Logs:     /var/log/nginx/"
echo ""
echo "   To set a custom page, run:"
echo "   echo 'Hello World' | sudo tee /usr/share/nginx/html/index.html"
```
