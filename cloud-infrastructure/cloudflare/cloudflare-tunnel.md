# Cloudflare Tunnel - Expose Services Without Public IP

## Problem Statement

You have services running on machines without public IP addresses (ephemeral environments, home labs, corporate networks behind NAT) and need to make them accessible via HTTPS with custom domains.

**Common scenarios:**

- iximiuz Labs playgrounds (no public IP, 8-hour sessions)
- Home server behind router NAT
- Corporate network with firewall restrictions
- Development environments in containers

**Traditional solutions:**

- Port forwarding (requires router access, security risk)
- VPS with reverse proxy (costs money, extra infrastructure)
- ngrok/localtunnel (limited free tier, random URLs)

**Limitations:**

- No static public IP
- Can't configure inbound firewall rules
- Need professional custom domain (not random URLs)
- Require HTTPS with valid certificates

---

## Solution: Cloudflare Tunnel

**What it is:** Secure outbound connection from your service to Cloudflare's edge network.

**Key advantage:** Outbound-only connection (no inbound ports needed).

**How it works:**
```
Internet User
    ↓
Cloudflare Edge (HTTPS termination)
    ↓
Cloudflare Tunnel (encrypted connection)
    ↓
Your Service (localhost:8080)
```

**Benefits:**

- No public IP required
- No port forwarding needed
- Free HTTPS certificates
- Custom domain support
- DDoS protection included
- Zero Trust security

---

## Prerequisites

### Requirements

1. **Cloudflare account** (free tier works)
2. **Domain registered** (can be purchased through Cloudflare or external registrar)
3. **Domain DNS managed by Cloudflare** (nameservers pointed to Cloudflare)
4. **Service running locally** (e.g., Jenkins on port 8080)

### Verify DNS Setup

Check your domain nameservers:

```bash
dig +short NS ibtisam-iq.com
# Should show Cloudflare nameservers:
# bob.ns.cloudflare.com
# sue.ns.cloudflare.com
```

---

## Setup Steps

### Step 1: Create Tunnel

**Via Cloudflare Dashboard:**

1. Login to Cloudflare Dashboard
2. Navigate to: **Zero Trust** → **Networks** → **Tunnels**
3. Click: **Create a tunnel**
4. Choose: **Cloudflared**
5. Name your tunnel: `jenkins-tunnel` (or descriptive name)
6. Click: **Save tunnel**

**Result:** Cloudflare generates a unique tunnel token (keep this secure).

### Step 2: Install cloudflared

**On your server (Ubuntu/Debian):**

```bash
# Download and install
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared

# Verify installation
cloudflared version
```

**Alternative (package manager):**

```bash
# Add Cloudflare GPG key
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install
sudo apt update
sudo apt install cloudflared
```

### Step 3: Install Tunnel as System Service

**Using tunnel token:**

```bash
# Install tunnel (creates systemd service)
sudo cloudflared service install eyJhIjoiOTM4NDU2...YOUR_TOKEN_HERE

# Service is automatically enabled and started
# Verify status
sudo systemctl status cloudflared

# Check logs
sudo journalctl -u cloudflared -f
```

**Service management:**

```bash
# Start
sudo systemctl start cloudflared

# Stop
sudo systemctl stop cloudflared

# Restart
sudo systemctl restart cloudflared

# Enable on boot
sudo systemctl enable cloudflared

# Disable
sudo systemctl disable cloudflared
```

### Step 4: Configure Public Hostname (Route)

**In Cloudflare Dashboard:**

1. Go to your tunnel: **jenkins-tunnel**
2. Navigate to: **Public Hostname** tab
3. Click: **Add a public hostname**

**Configure route:**

```
Subdomain: jenkins
Domain: ibtisam-iq.com (select your domain)
Path: (leave empty)

Service:
  Type: HTTP
  URL: localhost:8080
```

4. Click: **Save hostname**

**Result:** Your service is now accessible at `https://jenkins.ibtisam-iq.com`

---

## How It Works

### Architecture

```
┌─────────────┐
│   Internet  │
│    User     │
└──────┬──────┘
       │ HTTPS Request
       │ https://jenkins.ibtisam-iq.com
       ▼
┌─────────────────────────────────┐
│    Cloudflare Edge Network      │
│  - DNS resolution               │
│  - HTTPS termination            │
│  - DDoS protection              │
└──────┬──────────────────────────┘
       │ Encrypted Tunnel
       │ (Outbound connection only)
       ▼
┌─────────────────────────────────┐
│    Your Server (No public IP)   │
│  ┌──────────────────────┐      │
│  │  cloudflared daemon  │      │
│  └──────────┬───────────┘      │
│             │                   │
│             │ HTTP              │
│             ▼                   │
│  ┌──────────────────────┐      │
│  │  Jenkins :8080       │      │
│  └──────────────────────┘      │
└─────────────────────────────────┘
```

### Traffic Flow

**Inbound request:**

1. User requests: `https://jenkins.ibtisam-iq.com`
2. DNS resolves to Cloudflare IP
3. Request hits Cloudflare edge
4. Cloudflare forwards via tunnel to cloudflared
5. cloudflared proxies to localhost:8080
6. Jenkins responds
7. Response flows back through tunnel
8. User receives response

**Key point:** All connections are outbound from your server (firewall-friendly).

---

## Adding Multiple Services

### One Tunnel, Multiple Routes

You can expose multiple services using the same tunnel:

**In Cloudflare Dashboard:**

**Route 1: Jenkins**
```
Subdomain: jenkins
Domain: ibtisam-iq.com
Path: (empty)
URL: localhost:8080
```

**Route 2: SonarQube**
```
Subdomain: sonar
Domain: ibtisam-iq.com
Path: (empty)
URL: localhost:9000
```

**Route 3: Nexus**
```
Subdomain: nexus
Domain: ibtisam-iq.com
Path: (empty)
URL: localhost:8081
```

**Result:**

- `https://jenkins.ibtisam-iq.com` → Jenkins
- `https://sonar.ibtisam-iq.com` → SonarQube
- `https://nexus.ibtisam-iq.com` → Nexus

**Note:** All routes use the same cloudflared service and tunnel token.

---

## Security Considerations

### Tunnel Token Management

**The token is sensitive:** Anyone with the token can create routes to your services.

**Best practices:**

1. **Store securely:** Use secrets manager (Doppler, Vault, AWS Secrets Manager)
2. **Never commit to Git:** Add to .gitignore
3. **Rotate if compromised:** Generate new tunnel token
4. **Limit access:** Only install on trusted machines

**Example using Doppler:**

```bash
# Store token
doppler secrets set CLOUDFLARE_TUNNEL_TOKEN="eyJhIjoiOTM4..."

# Retrieve and install
TOKEN=$(doppler secrets get CLOUDFLARE_TUNNEL_TOKEN --plain)
sudo cloudflared service install $TOKEN
```

### Access Control

**Cloudflare Zero Trust options:**

- Add authentication (Google SSO, GitHub, email OTP)
- IP allowlist/blocklist
- Geographic restrictions
- Rate limiting

**Configure in:** Cloudflare Dashboard → Zero Trust → Access → Applications

---

## Troubleshooting

### Check Service Status

```bash
# Service status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Test connectivity
curl https://jenkins.ibtisam-iq.com
```

### Common Issues

**Issue: Tunnel shows "Disconnected"**

Solution:
```bash
# Restart service
sudo systemctl restart cloudflared

# Check logs for errors
sudo journalctl -u cloudflared -n 50
```

**Issue: 404 or 502 error**

Possible causes:

- Service not running on specified port
- Incorrect URL in route configuration
- Firewall blocking localhost connections

Verify:
```bash
# Check if service is running
curl http://localhost:8080

# Check listening ports
sudo ss -tulpn | grep 8080
```

**Issue: DNS not resolving**

Solution:
```bash
# Check DNS propagation
dig +short jenkins.ibtisam-iq.com

# Clear local DNS cache
sudo systemd-resolve --flush-caches

# Try different DNS server
dig @8.8.8.8 jenkins.ibtisam-iq.com
```

---

## Comparison with Alternatives

### Cloudflare Tunnel vs Traditional Methods

| Feature | Cloudflare Tunnel | Port Forwarding | VPS + Reverse Proxy | ngrok |
|---------|------------------|-----------------|---------------------|-------|
| **Public IP needed** | No | No | Yes | No |
| **Router access** | No | Yes | N/A | No |
| **Cost** | Free | Free | $5-10/month | Free (limited) |
| **Custom domain** | Yes | Yes | Yes | Paid only |
| **HTTPS certificate** | Automatic | Manual | Manual | Automatic |
| **DDoS protection** | Included | No | Manual setup | Limited |
| **Setup complexity** | Low | Medium | High | Very Low |
| **Security** | Zero Trust | Firewall rules | Manual hardening | Basic |

---

## Use Cases

### Development Environments

**Scenario:** Share work-in-progress with team or clients.

```bash
# Development server
npm run dev  # localhost:3000

# Expose via tunnel
# Route: dev.ibtisam-iq.com → localhost:3000

# Share: https://dev.ibtisam-iq.com
```

### CI/CD Services (Jenkins, GitLab)

**Scenario:** Access Jenkins from anywhere, receive GitHub webhooks.

```bash
# Jenkins running on iximiuz Labs
# No public IP, 8-hour sessions

# Expose via tunnel
# Route: jenkins.ibtisam-iq.com → localhost:8080

# GitHub webhook: https://jenkins.ibtisam-iq.com/github-webhook/
```

### Home Lab Services

**Scenario:** Access home services while traveling.

```bash
# Home Assistant, Plex, NAS
# Behind residential NAT

# Expose via tunnel
# Routes:
# - home.ibtisam-iq.com → localhost:8123
# - plex.ibtisam-iq.com → localhost:32400
```

---

## Best Practices

### Naming Conventions

**Tunnel names:** Descriptive and environment-specific
```
jenkins-tunnel
production-tunnel
home-lab-tunnel
```

**Subdomain names:** Service-specific
```
jenkins.ibtisam-iq.com
sonar.ibtisam-iq.com
nexus.ibtisam-iq.com
```

### Monitoring

**Check tunnel health:**

```bash
# View tunnel status in dashboard
# Cloudflare → Zero Trust → Networks → Tunnels

# Check service uptime
sudo systemctl status cloudflared

# Monitor logs
sudo journalctl -u cloudflared -f
```

---

## Cost Analysis

### Free Tier Includes:

- Unlimited tunnels
- Unlimited routes per tunnel
- Automatic HTTPS certificates
- DDoS protection (unmetered)
- 50 users for Zero Trust
- Basic analytics

### When to Upgrade:

**Cloudflare Teams (paid):**

- More Zero Trust users (beyond 50)
- Advanced security policies
- Device posture checks
- Audit logs retention

**Cost:** Starting at $7/user/month

**For personal projects and small teams:** Free tier is sufficient.

---

## Quick Reference

### Essential Commands

```bash
# Install tunnel
sudo cloudflared service install <TOKEN>

# Service management
sudo systemctl {start|stop|restart|status} cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Version
cloudflared version

# Update cloudflared
sudo cloudflared update

# Uninstall
sudo cloudflared service uninstall
```

### Configuration Locations

```bash
# Service file
/etc/systemd/system/cloudflared.service

# Credentials
/etc/cloudflared/
~/.cloudflared/

# Logs
sudo journalctl -u cloudflared
```

---

## Summary

**Cloudflare Tunnel solves the problem of exposing services without public IP addresses by creating secure outbound connections to Cloudflare's edge network.**

**Key advantages:**

- No public IP or port forwarding required
- Automatic HTTPS with valid certificates
- Custom domain support
- Free for unlimited tunnels and routes
- Built-in DDoS protection
- Works in restrictive networks (outbound-only)

**Typical workflow:**

1. Create tunnel in Cloudflare Dashboard
2. Install cloudflared on your server
3. Add public hostname routes
4. Access via custom domain with HTTPS

**Perfect for:**

- Ephemeral environments (iximiuz Labs, containers)
- Home labs behind NAT
- Development sharing
- CI/CD services
- Learning and experimentation
