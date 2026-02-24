# Jenkins Setup on iximiuz Labs with SSL and Custom Domain

**Author:** Muhammad Ibtisam Iqbal  
**Last Updated:** February 20, 2026  
**Environment:** iximiuz Labs MiniLAN Playground (node-01)  
**Public URL:** https://jenkins.ibtisam-iq.com  
**Internal Port:** 8080

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Installation](#step-by-step-installation)
  - [1. Prepare the Node](#1-prepare-the-node)
  - [2. Install and Configure Nginx Reverse Proxy](#2-install-and-configure-nginx-reverse-proxy)
  - [3. Setup Cloudflare Tunnel](#3-setup-cloudflare-tunnel)
  - [4. Configure Custom Domain with SSL](#4-configure-custom-domain-with-ssl)
  - [5. Install Java 21](#5-install-java-21)
  - [6. Install Jenkins LTS](#6-install-jenkins-lts)
  - [7. Initial Jenkins Configuration](#7-initial-jenkins-configuration)
  - [8. Install Essential Plugins](#8-install-essential-plugins)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)
- [Appendix](#appendix)

---

## Overview

This guide provides complete step-by-step instructions for setting up **Jenkins LTS** on an iximiuz Labs playground node with **Java 21**, secured with SSL via **Cloudflare Tunnel** and **Nginx reverse proxy**, and accessible through a custom domain.

**What is Jenkins?**

Jenkins is an open-source automation server that enables continuous integration and continuous delivery (CI/CD) pipelines. It helps automate building, testing, and deploying applications.

**Why This Setup?**

- **Nginx Reverse Proxy**: Local SSL termination and request routing
- **Cloudflare Tunnel**: Secure access without opening firewall ports
- **Custom Domain**: Professional branded URL (jenkins.ibtisam-iq.com)
- **Automatic SSL**: Free SSL certificates via Cloudflare
- **DDoS Protection**: Built-in protection from Cloudflare
- **Zero Port Forwarding**: No need to expose public IPs

**Key Benefits:**

- Industry-standard CI/CD platform
- 1500+ plugins ecosystem
- Pipeline as Code support (Jenkinsfile)
- Distributed builds capability
- Active community and extensive documentation

---

## Prerequisites

Before starting, ensure you have:

- ✅ SSH access to node-01 in iximiuz Labs
- ✅ Cloudflare account with domain configured (ibtisam-iq.com)
- ✅ Basic knowledge of Linux command line
- ✅ At least 2GB RAM available on node
- ✅ Ubuntu 24.04 LTS running on node-01

**Resource Requirements (node-01):**

- CPU: 2 cores minimum
- RAM: 2GB minimum (4GB recommended)
- Disk: 10GB minimum (20GB recommended)
- OS: Ubuntu 24.04 LTS
- Network: Internet connectivity required

---

## Architecture

```
Internet Users
    ↓
Cloudflare DNS (jenkins.ibtisam-iq.com)
    ↓
Cloudflare Edge Network (DDoS Protection, CDN)
    ↓
Cloudflare Tunnel (Encrypted Connection)
    ↓
node-01 | cloudflared daemon (localhost:80)
    ↓
Nginx Reverse Proxy (localhost:80)
    ↓
Jenkins Application (localhost:8080)
```

**Traffic Flow:**

1. User accesses `https://jenkins.ibtisam-iq.com`
2. Cloudflare DNS resolves to Cloudflare edge
3. Request enters Cloudflare Tunnel (SSL terminated at Cloudflare)
4. Cloudflared daemon on node-01 receives request
5. Forwards to Nginx reverse proxy on localhost:80
6. Nginx proxies to Jenkins application
7. Response travels back through same encrypted path

**Why Nginx + Cloudflare Tunnel?**

- **Nginx**: Local request routing, caching, and future multi-service support
- **Tunnel**: Secure outbound-only connection, no firewall configuration needed
- **Combined**: Maximum flexibility and security

---

## Step-by-Step Installation

### 1. Prepare the Node

**SSH into node-01:**

From iximiuz Labs web interface, open terminal for node-01.

**Update system packages:**

```bash
sudo apt update && sudo apt upgrade -y
```

**Install essential tools:**

```bash
sudo apt install -y curl wget git vim software-properties-common
```

**Verify system information:**

```bash
lsb_release -a
```

Expected output: `Ubuntu 24.04 LTS`

---

### 2. Install and Configure Nginx Reverse Proxy

**Why Nginx First?**

We install Nginx before Jenkins because:
- It will handle incoming requests from Cloudflare Tunnel
- Provides a centralized reverse proxy for multiple services (Jenkins, SonarQube, Nexus)
- Enables future scalability and service routing

**Install Nginx:**

```bash
sudo apt install -y nginx
```

**Verify Nginx installation:**

```bash
nginx -v
```

Expected output: `nginx version: nginx/1.24.x`

**Check Nginx status:**

```bash
sudo systemctl status nginx
```

Expected: `active (running)`

**Stop Nginx temporarily (we'll configure it first):**

```bash
sudo systemctl stop nginx
```

**Create Nginx configuration for Jenkins:**

```bash
sudo nano /etc/nginx/sites-available/jenkins
```

**Paste the following configuration:**

```nginx
server {
    listen 80;
    server_name jenkins.ibtisam-iq.com;

    # Increase body size limit for artifact uploads
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (for Jenkins live updates)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 150;
        proxy_send_timeout 100;
        proxy_read_timeout 100;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

**Save and exit** (Ctrl+X, Y, Enter)

**Enable the configuration:**

```bash
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
```

**Remove default Nginx site:**

```bash
sudo rm /etc/nginx/sites-enabled/default
```

**Test Nginx configuration:**

```bash
sudo nginx -t
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Start Nginx:**

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Verify Nginx is running:**

```bash
sudo systemctl status nginx
sudo ss -tlnp | grep :80
```

Expected: Nginx listening on port 80

---

### 3. Setup Cloudflare Tunnel

**What is Cloudflare Tunnel?**

Cloudflare Tunnel (formerly Argo Tunnel) creates a secure, outbound-only connection from your server to Cloudflare's edge network without opening inbound firewall ports.

**Benefits:**

- Automatic SSL/TLS encryption
- DDoS protection
- No public IP exposure required
- No firewall port forwarding needed
- Works behind NAT/restrictive networks

**Install cloudflared daemon:**

```bash
# Download cloudflared for Linux AMD64
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared

# Make executable
chmod +x cloudflared

# Move to system path
sudo mv cloudflared /usr/local/bin/

# Verify installation
cloudflared --version
```

Expected output: `cloudflared version 2024.x.x`

**Authenticate with Cloudflare:**

```bash
cloudflared tunnel login
```

**What happens:**

1. Command generates a URL
2. Opens browser automatically (or copy URL manually)
3. Log into your Cloudflare account
4. Select your domain: `ibtisam-iq.com`
5. Authorize cloudflared
6. Certificate downloaded to `~/.cloudflared/cert.pem`

**If browser doesn't open automatically:**

```bash
# Look for output like:
# Please open the following URL and log in with your Cloudflare account:
# https://dash.cloudflare.com/argotunnel?...
```

Copy the URL and open it manually in a browser.

**Verify authentication:**

```bash
ls -la ~/.cloudflared/
```

You should see: `cert.pem` file

**Create a tunnel:**

```bash
cloudflared tunnel create jenkins-tunnel
```

**Output:**

```
Tunnel credentials written to /home/ubuntu/.cloudflared/<TUNNEL-ID>.json
Created tunnel jenkins-tunnel with id <TUNNEL-ID>
```

**⚠️ Important: Copy your Tunnel ID** - you'll need it for configuration.

Example: `a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8`

**List your tunnels (verify creation):**

```bash
cloudflared tunnel list
```

Expected output:
```
ID                                   NAME            CREATED
a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8 jenkins-tunnel  2026-02-20T08:00:00Z
```

**Create tunnel configuration directory:**

```bash
mkdir -p ~/.cloudflared
```

**Create tunnel configuration file:**

```bash
nano ~/.cloudflared/config.yml
```

**Paste the following configuration:**

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: /home/ubuntu/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  - hostname: jenkins.ibtisam-iq.com
    service: http://localhost:80
  - service: http_status:404
```

**⚠️ Important Replacements:**

Replace `<YOUR-TUNNEL-ID>` with your actual tunnel ID (from previous step)

**Configuration Explanation:**

- `tunnel`: Your unique tunnel identifier
- `credentials-file`: Path to tunnel credentials (contains auth token)
- `ingress`: Routing rules
  - `hostname`: External domain name
  - `service`: Local service URL (Nginx on port 80)
  - Final catch-all rule: Returns 404 for undefined routes

**Why service points to localhost:80 (Nginx) instead of localhost:8080 (Jenkins)?**

Because we're using Nginx as reverse proxy. Cloudflare Tunnel → Nginx → Jenkins provides better architecture.

**Save and exit** (Ctrl+X, Y, Enter)

**Verify configuration syntax:**

```bash
cloudflared tunnel ingress validate
```

Expected output: `Configuration is valid`

---

### 4. Configure Custom Domain with SSL

**Create DNS record for tunnel:**

```bash
cloudflared tunnel route dns jenkins-tunnel jenkins.ibtisam-iq.com
```

**Output:**

```
2026-02-20T08:05:00Z INF Added CNAME jenkins.ibtisam-iq.com which will route to tunnel jenkins-tunnel
```

**What this command does:**

1. Creates CNAME record in Cloudflare DNS
2. Points `jenkins.ibtisam-iq.com` to `<TUNNEL-ID>.cfargotunnel.com`
3. Automatically enables SSL/TLS (Cloudflare managed certificate)
4. Routes traffic through Cloudflare edge network

**Verify DNS record creation:**

Log into Cloudflare Dashboard:

1. Go to https://dash.cloudflare.com
2. Select domain: `ibtisam-iq.com`
3. Navigate to: **DNS** → **Records**
4. You should see:
   - Type: `CNAME`
   - Name: `jenkins`
   - Target: `<TUNNEL-ID>.cfargotunnel.com`
   - Proxy status: Enabled (orange cloud)

**Verify DNS propagation:**

```bash
nslookup jenkins.ibtisam-iq.com
```

Or use online tool: https://dnschecker.org/

**Configure Cloudflare SSL/TLS settings:**

1. In Cloudflare Dashboard, go to: **SSL/TLS** → **Overview**
2. Set encryption mode: **Flexible**
   - Why Flexible? Because Cloudflare terminates SSL and connects to Nginx via HTTP (localhost)
   - This is secure because tunnel connection is encrypted end-to-end

**Create systemd service for tunnel:**

This ensures cloudflared starts automatically on boot and restarts on failure.

```bash
sudo nano /etc/systemd/system/cloudflared-jenkins.service
```

**Paste:**

```ini
[Unit]
Description=Cloudflare Tunnel for Jenkins
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/ubuntu/.cloudflared/config.yml run jenkins-tunnel
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

**⚠️ Note:** If your username is not `ubuntu`, replace it with your actual username.

**Find your username:**

```bash
whoami
```

**Save and exit** (Ctrl+X, Y, Enter)

**Reload systemd and enable tunnel service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-jenkins
sudo systemctl start cloudflared-jenkins
```

**Check tunnel status:**

```bash
sudo systemctl status cloudflared-jenkins
```

Expected output: `active (running)`

**Verify tunnel connectivity:**

```bash
cloudflared tunnel info jenkins-tunnel
```

Expected output shows tunnel status as `ACTIVE`

**View tunnel logs (verify connection):**

```bash
sudo journalctl -u cloudflared-jenkins -f
```

Look for: `Connection established` and `Registered tunnel connection`

Press `Ctrl+C` to exit log view.

**Test external access (before Jenkins installation):**

```bash
curl -I http://localhost:80
```

Should return: `HTTP/1.1 502 Bad Gateway` (normal - Jenkins not installed yet)

**Test via custom domain:**

Open browser: **https://jenkins.ibtisam-iq.com**

You should see:
- Valid SSL certificate (lock icon)
- 502 Bad Gateway error (normal - Jenkins not running yet)

If you see this, congratulations! Your Nginx + Cloudflare Tunnel setup is working perfectly.

---

### 5. Install Java 21

Jenkins LTS now requires **Java 21** (OpenJDK 21).

**Add OpenJDK repository:**

```bash
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt update
```

**Install OpenJDK 21:**

```bash
sudo apt install -y openjdk-21-jdk
```

**Verify Java installation:**

```bash
java -version
```

Expected output:

```
openjdk version "21.0.2" 2024-01-16
OpenJDK Runtime Environment (build 21.0.2+13-Ubuntu-1)
OpenJDK 64-Bit Server VM (build 21.0.2+13-Ubuntu-1, mixed mode, sharing)
```

**Set JAVA_HOME environment variable:**

```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**Verify JAVA_HOME:**

```bash
echo $JAVA_HOME
```

Expected: `/usr/lib/jvm/java-21-openjdk-amd64`

---

### 6. Install Jenkins LTS

**Add Jenkins repository GPG key:**

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
```

**Add Jenkins APT repository:**

```bash
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
```

**Update package index:**

```bash
sudo apt update
```

**Install Jenkins:**

```bash
sudo apt install -y jenkins
```

**Enable Jenkins service:**

```bash
sudo systemctl enable jenkins
```

**Start Jenkins service:**

```bash
sudo systemctl start jenkins
```

**Jenkins takes 30-60 seconds to start. Monitor startup:**

```bash
sudo journalctl -u jenkins -f
```

Wait for: `Jenkins is fully up and running`

Press `Ctrl+C` to exit log view.

**Check Jenkins status:**

```bash
sudo systemctl status jenkins
```

Expected output: `active (running)`

**Verify Jenkins is listening on port 8080:**

```bash
sudo ss -tlnp | grep 8080
```

Expected output:
```
tcp   LISTEN  0   50   *:8080   *:*   users:(("java",pid=xxxx))
```

**Test local Jenkins access:**

```bash
curl -I http://localhost:8080
```

Expected: `HTTP/1.1 403 Forbidden` (normal - Jenkins requires initial setup)

---

### 7. Initial Jenkins Configuration

**Retrieve initial admin password:**

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Example output:**

```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**⚠️ Copy this password** - you'll need it for the next step.

**Access Jenkins via custom domain:**

Open browser: **https://jenkins.ibtisam-iq.com**

You should now see Jenkins "Unlock Jenkins" page.

**Step 1: Unlock Jenkins**

1. You'll see "Unlock Jenkins" page
2. Paste the initial admin password you retrieved
3. Click **"Continue"**

**Step 2: Customize Jenkins**

Two options:

- **Install suggested plugins** (Recommended)
- **Select plugins to install** (Advanced)

Select **"Install suggested plugins"**

This installs essential plugins:

- Git plugin
- Pipeline plugin
- Credentials plugin
- SSH Build Agents plugin
- Matrix Authorization Strategy
- Email Extension plugin
- Folders plugin
- Workspace Cleanup plugin
- And ~20 more essential plugins

Wait for plugin installation (2-5 minutes).

**Step 3: Create First Admin User**

Fill in the form:

- **Username:** `admin` (or your preferred username)
- **Password:** (strong password - save it securely)
- **Confirm password:** (repeat)
- **Full name:** `Muhammad Ibtisam Iqbal`
- **Email address:** `your-email@example.com`

Click **"Save and Continue"**

**Step 4: Instance Configuration**

Jenkins URL should show: `https://jenkins.ibtisam-iq.com/`

- ✅ Verify the URL is correct
- ✅ Ensure it uses `https://` (not `http://`)
- Click **"Save and Finish"**

**Step 5: Jenkins is Ready!**

Click **"Start using Jenkins"**

You'll be redirected to Jenkins dashboard.

---

### 8. Install Essential Plugins

**Navigate to Plugin Manager:**

Dashboard → **Manage Jenkins** → **Plugins** → **Available plugins**

**Search and install recommended plugins:**

**Build & Deploy:**

- Docker Pipeline
- Kubernetes
- Config File Provider
- Nexus Artifact Uploader
- Copy Artifact

**Code Quality & Analysis:**

- SonarQube Scanner
- Warnings Next Generation
- Code Coverage API
- JaCoCo

**Source Control:**

- GitHub Integration
- GitLab
- Bitbucket

**Notifications:**

- Slack Notification
- Email Extension Template
- Mailer

**Security:**

- OWASP Markup Formatter
- Role-based Authorization Strategy

**Utilities:**

- Blue Ocean (Modern pipeline UI)
- Pipeline Utility Steps
- Timestamper
- Build Timeout
- Workspace Cleanup

**Install plugins:**

1. Check boxes next to desired plugins
2. Scroll to bottom
3. Click **"Install"** (or **"Download now and install after restart"**)
4. Wait for download and installation
5. Check **"Restart Jenkins when installation is complete and no jobs are running"**

Jenkins will restart automatically (wait 30-60 seconds).

**Refresh browser page** - you may need to log in again.

---

## Verification

**Complete checklist to verify successful installation:**

### 1. Service Status Check

```bash
sudo systemctl status jenkins
sudo systemctl status nginx
sudo systemctl status cloudflared-jenkins
```

All should show: `active (running)`

### 2. Port Verification

```bash
sudo ss -tlnp | grep :80    # Nginx
sudo ss -tlnp | grep :8080  # Jenkins
```

Both should show processes listening.

### 3. Web Access Test

Open browser: **https://jenkins.ibtisam-iq.com**

- ✅ Should load Jenkins dashboard
- ✅ SSL certificate valid (lock icon in browser)
- ✅ No security warnings
- ✅ URL shows `https://` (not `http://`)

### 4. SSL Certificate Verification

```bash
curl -I https://jenkins.ibtisam-iq.com
```

Should return: `HTTP/2 200` (note HTTP/2, indicating HTTPS)

### 5. Cloudflare Tunnel Status

```bash
cloudflared tunnel info jenkins-tunnel
```

Should show: Status `HEALTHY` or `ACTIVE`

### 6. Create Test Job

**Verify Jenkins functionality:**

1. Go to Dashboard
2. Click **"New Item"**
3. Enter name: `test-job`
4. Select **"Freestyle project"**
5. Click **"OK"**
6. Scroll to **"Build Steps"**
7. Click **"Add build step"** → **"Execute shell"**
8. Enter command:
   ```bash
   echo "Hello from Jenkins!"
   java -version
   echo "Jenkins is working perfectly!"
   ```
9. Click **"Save"**
10. Click **"Build Now"**
11. Wait for build to complete
12. Click on build number (e.g., `#1`)
13. Click **"Console Output"**

Expected output:
```
Hello from Jenkins!
openjdk version "21.0.2"
Jenkins is working perfectly!
Finished: SUCCESS
```

If you see this, **Jenkins is successfully installed and configured!**

---

## Troubleshooting

### Issue: Jenkins service won't start

**Check logs:**

```bash
sudo journalctl -u jenkins -n 100 --no-pager
```

**Common error: Port 8080 already in use**

Find process using port 8080:

```bash
sudo lsof -i :8080
```

Kill the process or change Jenkins port:

```bash
sudo nano /etc/default/jenkins
```

Change: `HTTP_PORT=8080` to `HTTP_PORT=8081`

Update Nginx config accordingly:

```bash
sudo nano /etc/nginx/sites-available/jenkins
```

Change: `proxy_pass http://localhost:8080;` to `proxy_pass http://localhost:8081;`

Restart services:

```bash
sudo systemctl restart jenkins
sudo systemctl restart nginx
```

---

### Issue: Cannot access Jenkins through custom domain

**Step-by-step diagnosis:**

**1. Test local Jenkins access:**

```bash
curl http://localhost:8080
```

If this fails → Jenkins issue (check Jenkins service)

**2. Test Nginx:**

```bash
curl http://localhost:80
```

If this fails → Nginx issue (check Nginx config)

**3. Check Cloudflare Tunnel:**

```bash
sudo systemctl status cloudflared-jenkins
cloudflared tunnel info jenkins-tunnel
```

**4. View tunnel logs:**

```bash
sudo journalctl -u cloudflared-jenkins -n 50
```

Look for connection errors.

**5. Verify DNS record:**

```bash
nslookup jenkins.ibtisam-iq.com
```

Should return CNAME pointing to `*.cfargotunnel.com`

**6. Test external access:**

```bash
curl -I https://jenkins.ibtisam-iq.com
```

**If still not working, restart all services:**

```bash
sudo systemctl restart jenkins
sudo systemctl restart nginx
sudo systemctl restart cloudflared-jenkins
```

Wait 60 seconds and test again.

---

### Issue: SSL certificate warnings

**Verify Cloudflare SSL settings:**

1. Go to Cloudflare Dashboard
2. Select domain: `ibtisam-iq.com`
3. Navigate to: **SSL/TLS** → **Overview**
4. Ensure encryption mode is: **Flexible** or **Full**

**Recommended setting for this setup:** **Flexible**

(Cloudflare → Nginx connection is over secure tunnel, no SSL needed on origin)

**Check DNS CNAME record:**

Ensure CNAME is proxied (orange cloud enabled in Cloudflare DNS)

---

### Issue: Forgot Jenkins admin password

**Method 1: Reset via config.xml**

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Edit config file
sudo nano /var/lib/jenkins/config.xml
```

Find: `<useSecurity>true</useSecurity>`

Change to: `<useSecurity>false</useSecurity>`

Save and exit.

```bash
# Start Jenkins
sudo systemctl start jenkins
```

Access Jenkins (no password required now) → Create new admin user → Re-enable security

**Method 2: Reset via Groovy script**

Access Jenkins Script Console:

Dashboard → **Manage Jenkins** → **Script Console**

Run:

```groovy
import hudson.security.*
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "newpassword123")
instance.setSecurityRealm(hudsonRealm)
instance.save()
```

Replace `newpassword123` with your new password.

---

### Issue: Java version mismatch

**Verify Java version:**

```bash
java -version
```

If not Java 21:

```bash
# Install Java 21
sudo apt install -y openjdk-21-jdk

# Set as default
sudo update-alternatives --config java
```

Select Java 21 from the list (usually option 0 or 1).

**Restart Jenkins:**

```bash
sudo systemctl restart jenkins
```

---

### Issue: Nginx reverse proxy not working

**Test Nginx configuration:**

```bash
sudo nginx -t
```

Should show: `syntax is ok` and `test is successful`

**If errors, check config file:**

```bash
sudo nano /etc/nginx/sites-available/jenkins
```

Verify:
- `proxy_pass http://localhost:8080;` (correct port)
- No syntax errors (missing semicolons, brackets)

**Reload Nginx:**

```bash
sudo systemctl reload nginx
```

---

### Issue: Cloudflare Tunnel disconnected

**Check tunnel service:**

```bash
sudo systemctl status cloudflared-jenkins
```

**View recent logs:**

```bash
sudo journalctl -u cloudflared-jenkins -n 50
```

**Common errors:**

**Error: "failed to register tunnel"**

→ Check credentials file path in config.yml

**Error: "dial tcp: lookup failed"**

→ DNS resolution issue, check internet connectivity

**Restart tunnel:**

```bash
sudo systemctl restart cloudflared-jenkins
```

**Test tunnel manually:**

```bash
cloudflared tunnel --config ~/.cloudflared/config.yml run jenkins-tunnel
```

Press `Ctrl+C` when done testing.

---

## Next Steps

Now that Jenkins is running with SSL and custom domain, you can:

1. **Configure Build Agents** (node-02, node-03) for distributed builds
2. **Integrate with SonarQube** (node-02) for code quality analysis
3. **Connect to Nexus** (node-03) for artifact management
4. **Create CI/CD Pipelines** using Jenkinsfile (Pipeline as Code)
5. **Setup GitHub Webhooks** for automatic builds on git push
6. **Configure Backup Strategy** for Jenkins home directory
7. **Enable LDAP/SSO Authentication** for centralized user management
8. **Setup Monitoring** with Prometheus and Grafana
9. **Configure Email Notifications** for build status
10. **Create Shared Libraries** for reusable pipeline code

---

## Appendix: Useful Commands

### Jenkins Service Management

```bash
# Start Jenkins
sudo systemctl start jenkins

# Stop Jenkins
sudo systemctl stop jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Check status
sudo systemctl status jenkins

# View logs (live)
sudo journalctl -u jenkins -f

# View last 50 log lines
sudo journalctl -u jenkins -n 50

# Reload configuration
sudo systemctl reload jenkins
```

### Nginx Service Management

```bash
# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Restart Nginx
sudo systemctl restart nginx

# Reload configuration (no downtime)
sudo systemctl reload nginx

# Test configuration syntax
sudo nginx -t

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Cloudflare Tunnel Management

```bash
# List all tunnels
cloudflared tunnel list

# Get tunnel info
cloudflared tunnel info jenkins-tunnel

# Start tunnel manually (testing)
cloudflared tunnel --config ~/.cloudflared/config.yml run jenkins-tunnel

# View tunnel logs (live)
sudo journalctl -u cloudflared-jenkins -f

# View last 50 tunnel log lines
sudo journalctl -u cloudflared-jenkins -n 50

# Restart tunnel service
sudo systemctl restart cloudflared-jenkins

# Check tunnel status
sudo systemctl status cloudflared-jenkins

# Validate tunnel configuration
cloudflared tunnel ingress validate
```

### Jenkins File Locations

```bash
# Installation directory
/usr/share/jenkins/

# Home directory (jobs, config, plugins)
/var/lib/jenkins/

# Main configuration
/var/lib/jenkins/config.xml

# Jobs directory
/var/lib/jenkins/jobs/

# Plugins directory
/var/lib/jenkins/plugins/

# System logs
/var/log/jenkins/jenkins.log

# Initial admin password
/var/lib/jenkins/secrets/initialAdminPassword

# Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
```

### Jenkins CLI Operations

**Download Jenkins CLI:**

```bash
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
```

**List all jobs:**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:password list-jobs
```

**Build a job:**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:password build test-job
```

**Get job configuration:**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:password get-job test-job
```

**Safe restart (waits for running jobs):**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:password safe-restart
```

### Backup Jenkins

**Complete backup:**

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Create backup
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins/

# Start Jenkins
sudo systemctl start jenkins

# Copy backup to safe location
# Example: External storage or another server
scp jenkins-backup-*.tar.gz user@backup-server:/backups/
```

**Backup only important data (faster):**

```bash
sudo systemctl stop jenkins

sudo tar -czf jenkins-config-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/jobs/ \
  /var/lib/jenkins/config.xml \
  /var/lib/jenkins/credentials.xml \
  /var/lib/jenkins/secrets/

sudo systemctl start jenkins
```

### Restore Jenkins

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Remove existing data (careful!)
sudo rm -rf /var/lib/jenkins/*

# Extract backup
sudo tar -xzf jenkins-backup-20260220.tar.gz -C /

# Fix permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/

# Start Jenkins
sudo systemctl start jenkins
```

### System Monitoring

**Check disk space:**

```bash
df -h
```

**Check memory usage:**

```bash
free -h
```

**Check CPU usage:**

```bash
top
# Press 'q' to quit
```

**Check Jenkins process:**

```bash
ps aux | grep jenkins
```

**Check all related processes:**

```bash
ps aux | grep -E "jenkins|nginx|cloudflared"
```

---

## Resources

- **Official Jenkins Documentation:** https://www.jenkins.io/doc/
- **Jenkins LTS Changelog:** https://www.jenkins.io/changelog-stable/
- **Jenkins Plugin Index:** https://plugins.jenkins.io/
- **Jenkins Pipeline Documentation:** https://www.jenkins.io/doc/book/pipeline/
- **Cloudflare Tunnel Documentation:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Nginx Documentation:** https://nginx.org/en/docs/
- **Ubuntu Server Guide:** https://ubuntu.com/server/docs

---

## Notes for SonarQube and Nexus Setup

**If you're setting up SonarQube (node-02) or Nexus (node-03):**

The following steps are **identical** for all services:

- **Section 1:** Prepare the Node
- **Section 2:** Install and Configure Nginx Reverse Proxy
- **Section 3:** Setup Cloudflare Tunnel
- **Section 4:** Configure Custom Domain with SSL

**Only differences:**

1. **Node name:** node-02 (SonarQube) or node-03 (Nexus)
2. **Subdomain:** `sonar.ibtisam-iq.com` or `nexus.ibtisam-iq.com`
3. **Port:** 9000 (SonarQube) or 8081 (Nexus)
4. **Tunnel name:** `sonarqube-tunnel` or `nexus-tunnel`
5. **Application installation:** SonarQube or Nexus specific steps

**To avoid repetition:**

When creating SonarQube/Nexus documentation, you can reference:

> "Follow sections 1-4 from Jenkins Setup documentation, replacing:
> - `jenkins.ibtisam-iq.com` with `sonar.ibtisam-iq.com`
> - Port 8080 with 9000
> - `jenkins-tunnel` with `sonarqube-tunnel`"

Then start from application-specific installation steps.

---

**Documentation maintained as part of:** https://nectar.ibtisam-iq.com  
**Project:** Self-Hosted CI/CD Stack on iximiuz Labs  
**GitHub:** https://github.com/ibtisam-iq/silver-stack