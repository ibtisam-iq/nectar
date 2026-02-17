# Setting Up Custom Domain with HTTPS

## Table of Contents
1. [Problem Statement](#problem-statement)
2. [EC2 Setup (Traditional Method)](#ec2-setup-traditional-method)
3. [Ephemeral Environments (iximiuz Labs)](#ephemeral-environments-iximiuz-labs)
4. [Understanding Tunnels](#understanding-tunnels)
5. [All Possible Solutions](#all-possible-solutions)
6. [Cloudflare Tunnel Setup](#cloudflare-tunnel-setup)

---

## Problem Statement

**Goal:** Run Jenkins (or any service) on a custom domain with HTTPS enabled.

**Example:**

- Service: Jenkins running on port 8080
- Desired URL: `https://jenkins.ibtisam-iq.com`
- Requirement: Automatic HTTPS with valid SSL certificate

---

## EC2 Setup (Traditional Method)

### Architecture
```
Internet → EC2 Public IP (54.123.45.67) → Port 443 → Nginx → Port 8080 → Jenkins
```

### Prerequisites
- ✅ EC2 instance with **public IP address**
- ✅ Security group allowing ports 22, 80, 443
- ✅ Domain name (e.g., ibtisam-iq.com)
- ✅ DNS access (Cloudflare, GoDaddy, etc.)

### Method 1: Nginx + Let's Encrypt (Recommended)

**Step 1: Configure DNS**
```bash
# In Cloudflare DNS
Type: A
Name: jenkins
Content: 54.123.45.67  # Your EC2 public IP
Proxy: DNS only (gray cloud)
TTL: Auto
```

**Step 2: Install Nginx**
```bash
sudo apt update
sudo apt install nginx -y
```

**Step 3: Create Nginx Configuration**
```bash
sudo nano /etc/nginx/sites-available/jenkins.ibtisam-iq.com
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name jenkins.ibtisam-iq.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90s;
        proxy_http_version 1.1;
        proxy_request_buffering off;
    }
}
```

**Step 4: Enable Site**
```bash
sudo ln -s /etc/nginx/sites-available/jenkins.ibtisam-iq.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Step 5: Install Certbot and Get SSL Certificate**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d jenkins.ibtisam-iq.com
```

**What Certbot Does Internally:**

1. **Finds Nginx Config:** Searches for `server_name jenkins.ibtisam-iq.com`
2. **HTTP-01 Challenge:** Temporarily adds a location block to verify domain ownership
   ```nginx
   location = /.well-known/acme-challenge/TOKEN {
       return 200 "VERIFICATION_STRING";
   }
   ```
3. **Downloads Certificates:** Saves to `/etc/letsencrypt/live/jenkins.ibtisam-iq.com/`
   - `fullchain.pem` - Your certificate + intermediate certificates
   - `privkey.pem` - Private key (keep secret!)
   - `cert.pem` - Your certificate only
   - `chain.pem` - Intermediate certificates
4. **Modifies Nginx Config:** Adds SSL directives and redirect
5. **Reloads Nginx:** Applies configuration
6. **Sets Up Auto-Renewal:** Creates systemd timer (runs twice daily)

**Verify Installation:**
```bash
# Check certificates
sudo certbot certificates

# Check files
sudo ls -la /etc/letsencrypt/live/jenkins.ibtisam-iq.com/

# Check Nginx config
sudo nginx -T | grep -A 10 "server_name jenkins.ibtisam-iq.com"

# Test renewal
sudo certbot renew --dry-run

# Check auto-renewal timer
sudo systemctl status certbot.timer
```

**Step 6: Configure Jenkins for Reverse Proxy**
```bash
# Edit Jenkins config
sudo nano /etc/default/jenkins

# Add this to JENKINS_ARGS
--httpListenAddress=127.0.0.1

# Restart Jenkins
sudo systemctl restart jenkins
```

### Method 2: AWS Application Load Balancer + ACM

**Architecture:**
```
Internet → ALB (HTTPS:443) → EC2 Target Group (HTTP:8080) → Jenkins
```

**Pros:**
- No certificate management on EC2
- Automatic certificate renewal
- AWS-managed infrastructure
- Can distribute load across multiple instances

**Cons:**
- Additional cost (~$16-20/month)
- More complex setup

**Steps:**
1. Request certificate in AWS Certificate Manager for `jenkins.ibtisam-iq.com`
2. Create Application Load Balancer in same VPC
3. Create target group pointing to EC2:8080
4. Add HTTPS listener (443) with ACM certificate
5. Add HTTP listener (80) with redirect to HTTPS
6. Update DNS: `jenkins.ibtisam-iq.com` → ALB DNS name (CNAME)

### Method 3: Caddy (Automatic HTTPS)

**Steps:**
```bash
# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

# Create Caddyfile
sudo nano /etc/caddy/Caddyfile
```

```caddyfile
jenkins.ibtisam-iq.com {
    reverse_proxy localhost:8080
}
```

```bash
sudo systemctl start caddy
sudo systemctl enable caddy
```

### Certificate Backup and Restore

#### Step 1: Create the backup on EC2
```bash
# On EC2 instance
sudo tar -czf letsencrypt-backup.tar.gz /etc/letsencrypt/
sudo chown $USER:$USER letsencrypt-backup.tar.gz
mv letsencrypt-backup.tar.gz ~/
```

#### Step 2: Download to your Mac using SCP

**Option 1: Using SCP (Secure Copy)**
```bash
# On your Mac terminal
scp -i /path/to/your-key.pem ubuntu@YOUR_EC2_IP:~/letsencrypt-backup.tar.gz ~/Downloads/

# Example:
scp -i ~/.ssh/aws-jenkins.pem ubuntu@54.123.45.67:~/letsencrypt-backup.tar.gz ~/Downloads/
```

**Option 2: Using SFTP**
```bash
# On your Mac
sftp -i /path/to/your-key.pem ubuntu@YOUR_EC2_IP
# Then in SFTP prompt:
get letsencrypt-backup.tar.gz
exit
```

**Option 3: Using rsync (more features)**
```bash
# On your Mac
rsync -avz -e "ssh -i /path/to/your-key.pem" \
  ubuntu@YOUR_EC2_IP:~/letsencrypt-backup.tar.gz \
  ~/Downloads/
```

**Download to Local Mac (if no SSH key):**

Option 1: EC2 Instance Connect + transfer.sh
```bash
# Upload to transfer service
curl --upload-file ~/letsencrypt-backup.tar.gz https://transfer.sh/letsencrypt-backup.tar.gz
# Download URL will be provided
```

Option 2: AWS Systems Manager
```bash
# On Mac, install Session Manager plugin
brew install --cask session-manager-plugin

# Connect to EC2
aws ssm start-session --target i-YOUR_INSTANCE_ID

# Copy to S3
aws s3 cp ~/letsencrypt-backup.tar.gz s3://your-bucket/

# Download on Mac
aws s3 cp s3://your-bucket/letsencrypt-backup.tar.gz ~/Downloads/
```

#### Step 3: Restore on New EC2
```bash
# Upload backup to new EC2
# Extract
sudo tar -xzf letsencrypt-backup.tar.gz -C /

# Fix permissions
sudo chown -R root:root /etc/letsencrypt/
sudo chmod 755 /etc/letsencrypt/
sudo chmod -R 755 /etc/letsencrypt/live/
sudo chmod -R 755 /etc/letsencrypt/archive/
sudo chmod 600 /etc/letsencrypt/archive/*/privkey*.pem

# Verify
sudo certbot certificates

# Reload Nginx
sudo systemctl reload nginx
```

### Cleanup/Revoke Certificate

**Complete cleanup:**
```bash
# Revoke certificate
sudo certbot revoke --cert-name jenkins.ibtisam-iq.com

# Delete certificate
sudo certbot delete --cert-name jenkins.ibtisam-iq.com

# Remove all files
sudo rm -rf /etc/letsencrypt/live/jenkins.ibtisam-iq.com/
sudo rm -rf /etc/letsencrypt/archive/jenkins.ibtisam-iq.com/
sudo rm -rf /etc/letsencrypt/renewal/jenkins.ibtisam-iq.com.conf

# Restore Nginx to HTTP only
sudo nano /etc/nginx/sites-available/jenkins.ibtisam-iq.com
# Remove SSL configuration

sudo nginx -t
sudo systemctl reload nginx
```

---

## Ephemeral Environments (iximiuz Labs)

### The Problem

**What's Different from EC2:**

| Feature | EC2 | iximiuz Labs |
|---------|-----|--------------|
| Public IP | ✅ Dedicated (54.123.45.67) | ❌ Shared/None |
| Open Ports | ✅ Security groups | ❌ Cannot control |
| DNS Pointing | ✅ A record works | ❌ A record won't work |
| Let's Encrypt | ✅ Can verify domain | ❌ Cannot reach |

**Why Simple DNS Won't Work:**

```bash
# Check IP
curl ifconfig.me
# Returns: 185.123.45.67
```

This IP is **NOT yours** - it's iximiuz's gateway!

```
Internet → 185.123.45.67 (iximiuz gateway - shared)
    ↓
    ├── Playground 1 (you)
    ├── Playground 2 (someone else)
    ├── Playground 3 (another user)
    └── ...
```

When traffic arrives at 185.123.45.67, the gateway doesn't know which playground to forward to!

**If you add CNAME to iximiuz's exposed URL:**
```
Problems:
❌ URL changes with each new playground
❌ Contains port number (looks unprofessional)
❌ Temporary and expires
❌ Cannot customize SSL certificate
```

---

## Understanding Tunnels

### Core Networking Concepts

**INBOUND Connection (Traditional):**
```
Someone OUTSIDE → tries to connect → YOUR server
```
- Server **listens passively** (waiting for connections)
- Client initiates the connection
- Requires public IP
- Like: گھر میں بیٹھ کے doorbell کا انتظار

**OUTBOUND Connection (Tunnel):**
```
YOUR server → makes connection → External service
```
- Server **actively connects** first
- Server initiates the connection
- No public IP needed
- Like: آپ نے پہلے phone کر دیا

### How Tunnel Solves the Problem

**Traditional Method (Doesn't work without public IP):**
```
User's Browser
    ↓
jenkins.ibtisam-iq.com → DNS lookup → ???
    ↓
185.123.45.67 (shared gateway)
    ↓
??? Which playground? ???
    ↓
❌ Connection fails
```

**Tunnel Method (Works without public IP):**
```
Phase 1: Setup (Before anyone visits)
========================================
iximiuz playground
    ↓ [OUTBOUND connection]
cloudflared → tunnel.cloudflare.com
    ↓
Connection ESTABLISHED and kept open

Phase 2: User visits site
========================================
User's Browser
    ↓
jenkins.ibtisam-iq.com → DNS → Cloudflare
    ↓
Cloudflare: "jenkins-tunnel is already connected!"
    ↓
Pushes traffic through existing tunnel
    ↓
Reaches iximiuz playground
    ↓
Jenkins responds
```

### Key Insight

**TCP connections are bidirectional:**
- Once connected: Client ←→ Server (both can send data)
- Tunnel uses this: Server connects OUT first, then data flows BOTH ways
- No INBOUND connection needed!

---

## All Possible Solutions

### Comparison Table

| Method | Public IP Needed | Setup Once | Cost | Best For |
|--------|-----------------|------------|------|----------|
| Nginx + Let's Encrypt | ✅ Yes | ✅ Yes | Free | EC2 with public IP |
| AWS ALB + ACM | ✅ Yes | ✅ Yes | ~$16/mo | Production AWS |
| Cloudflare Tunnel | ❌ No | ✅ Yes | Free | Lab environments |
| ngrok | ❌ No | ✅ Yes | $8/mo | Quick demos |
| iximiuz URL + CNAME | ❌ No | ❌ No | Free | Testing only |
| SSH Reverse Tunnel | ⚠️ Need VPS | ❌ No | VPS cost | Manual setup |

---

## Cloudflare Tunnel Setup

### Prerequisites
- Cloudflare account
- Domain managed by Cloudflare
- Access to iximiuz playground terminal

### Step 1: Initialize Cloudflare Zero Trust

**First time only:**
1. Go to: https://one.dash.cloudflare.com/
2. You'll see "Choose your team name"
3. Enter team name: `ibtisam-iq` (or any name)
4. Select **Free** plan
5. Complete onboarding

### Step 2: Access Tunnel Dashboard

Navigate to:
```
Zero Trust Dashboard → Networks → Connectors → Cloudflare Tunnels
```

### Step 3: Create Tunnel (Dashboard Method)

1. Click **"Create a tunnel"**
2. Select **"Cloudflared"** connector
3. Name: `jenkins-tunnel`
4. Click **"Save tunnel"**
5. Copy the installation command shown (contains token)

### Step 4: Install in iximiuz Playground

```bash
# The command from dashboard will look like:
sudo cloudflared service install eyJhIjoiXXXXXXXXXX...

# Run it
sudo cloudflared service install <YOUR_TOKEN_HERE>

# Start service
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

### Step 5: Configure Public Hostname

Back in Cloudflare dashboard:
1. Click **"Next"** after installation
2. Add public hostname:
   - **Subdomain:** `jenkins`
   - **Domain:** Select `ibtisam-iq.com`
   - **Path:** Leave empty
   - **Service Type:** `HTTP`
   - **URL:** `localhost:8080`
3. Click **"Save"**

### Step 6: Verify

```bash
# Check tunnel status
sudo systemctl status cloudflared

# Test locally
curl http://localhost:8080

# Test from outside
curl https://jenkins.ibtisam-iq.com
```

### Alternative: CLI-Only Method

**No dashboard needed:**

```bash
# 1. Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# 2. Authenticate
cloudflared tunnel login
# Opens browser to authenticate

# 3. Create tunnel
cloudflared tunnel create jenkins-tunnel
# Note the Tunnel ID from output

# 4. Create config file
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

**Config file content:**
```yaml
tunnel: <TUNNEL_ID_FROM_STEP_3>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: jenkins.ibtisam-iq.com
    service: http://localhost:8080
  - service: http_status:404
```

```bash
# 5. Route DNS
cloudflared tunnel route dns jenkins-tunnel jenkins.ibtisam-iq.com

# 6. Run tunnel
cloudflared tunnel run jenkins-tunnel
```

**Run as service:**
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### Managing Tunnels

**List tunnels:**
```bash
cloudflared tunnel list
```

**Check tunnel info:**
```bash
cloudflared tunnel info jenkins-tunnel
```

**Delete tunnel:**
```bash
# Stop service
sudo systemctl stop cloudflared

# Delete tunnel
cloudflared tunnel delete jenkins-tunnel
```

---
