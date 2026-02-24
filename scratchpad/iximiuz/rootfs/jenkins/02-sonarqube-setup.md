# SonarQube Setup on iximiuz Labs with SSL and Custom Domain

**Author:** Muhammad Ibtisam Iqbal  
**Last Updated:** February 20, 2026  
**Environment:** iximiuz Labs MiniLAN Playground (node-02)  
**Public URL:** https://sonar.ibtisam-iq.com  
**Internal Port:** 9000

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Installation](#step-by-step-installation)
  - [Common Setup (Nginx + Cloudflare Tunnel)](#common-setup-nginx--cloudflare-tunnel)
  - [1. Install PostgreSQL Database](#1-install-postgresql-database)
  - [2. Configure System Requirements](#2-configure-system-requirements)
  - [3. Install SonarQube](#3-install-sonarqube)
  - [4. Configure SonarQube](#4-configure-sonarqube)
  - [5. Initial SonarQube Configuration](#5-initial-sonarqube-configuration)
  - [6. Integrate with Jenkins](#6-integrate-with-jenkins)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)
- [Appendix](#appendix)

---

## Overview

This guide provides complete step-by-step instructions for setting up **SonarQube Community Edition** on an iximiuz Labs playground node, secured with SSL via **Cloudflare Tunnel** and **Nginx reverse proxy**, and accessible through a custom domain.

**What is SonarQube?**

SonarQube is an open-source platform for continuous inspection of code quality. It performs automatic reviews with static analysis to detect bugs, code smells, and security vulnerabilities.

**Why SonarQube?**

- **Code Quality Analysis**: Detect bugs, vulnerabilities, and code smells
- **Security Scanning**: Identify security hotspots and vulnerabilities
- **Technical Debt Tracking**: Monitor code quality trends over time
- **Multi-Language Support**: Java, JavaScript, Python, C#, PHP, and 25+ languages
- **CI/CD Integration**: Seamless integration with Jenkins and other CI tools
- **Quality Gates**: Enforce quality standards before deployment

---

## Prerequisites

Before starting, ensure you have:

- ✅ SSH access to node-02 in iximiuz Labs
- ✅ Cloudflare account with domain configured (ibtisam-iq.com)
- ✅ Basic knowledge of Linux command line
- ✅ At least 4GB RAM available on node (SonarQube requires 2GB heap)
- ✅ Ubuntu 24.04 LTS running on node-02

**Resource Requirements (node-02):**

- CPU: 2 cores minimum (4 cores recommended)
- RAM: 4GB minimum (8GB recommended for production)
- Disk: 20GB minimum (depends on project size)
- OS: Ubuntu 24.04 LTS
- Network: Internet connectivity required

---

## Architecture

```
Internet Users
    ↓
Cloudflare DNS (sonar.ibtisam-iq.com)
    ↓
Cloudflare Edge Network (DDoS Protection, CDN)
    ↓
Cloudflare Tunnel (Encrypted Connection)
    ↓
node-02 | cloudflared daemon (localhost:80)
    ↓
Nginx Reverse Proxy (localhost:80)
    ↓
SonarQube Application (localhost:9000)
    ↓
PostgreSQL Database (localhost:5432)
```

**Traffic Flow:**

1. User accesses `https://sonar.ibtisam-iq.com`
2. Cloudflare DNS resolves to Cloudflare edge
3. Request enters Cloudflare Tunnel (SSL terminated at Cloudflare)
4. Cloudflared daemon on node-02 receives request
5. Forwards to Nginx reverse proxy on localhost:80
6. Nginx proxies to SonarQube application
7. SonarQube queries PostgreSQL for data
8. Response travels back through same encrypted path

---

## Step-by-Step Installation

### Common Setup (Nginx + Cloudflare Tunnel)

**⚠️ Important:** The following steps are identical to Jenkins setup (sections 1-4).

**Follow the Jenkins setup guide for:**

1. **Prepare the Node** (section 1)
2. **Install and Configure Nginx Reverse Proxy** (section 2)
3. **Setup Cloudflare Tunnel** (section 3)
4. **Configure Custom Domain with SSL** (section 4)

**When following Jenkins guide, make these replacements:**

| Item | Jenkins Value | SonarQube Value |
|------|---------------|-----------------|
| Node | node-01 | node-02 |
| Subdomain | jenkins.ibtisam-iq.com | sonar.ibtisam-iq.com |
| Port | 8080 | 9000 |
| Tunnel Name | jenkins-tunnel | sonarqube-tunnel |
| Service File | cloudflared-jenkins.service | cloudflared-sonarqube.service |

**Quick Reference - Nginx Configuration:**

```nginx
server {
    listen 80;
    server_name sonar.ibtisam-iq.com;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 150;
        proxy_send_timeout 100;
        proxy_read_timeout 100;
        
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

Save to: `/etc/nginx/sites-available/sonarqube`

Enable: `sudo ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/`

**Quick Reference - Cloudflare Tunnel Config:**

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: /home/ubuntu/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  - hostname: sonar.ibtisam-iq.com
    service: http://localhost:80
  - service: http_status:404
```

Save to: `~/.cloudflared/config.yml`

**Create tunnel:**
```bash
cloudflared tunnel create sonarqube-tunnel
```

**Route DNS:**
```bash
cloudflared tunnel route dns sonarqube-tunnel sonar.ibtisam-iq.com
```

**Systemd service:**
```bash
sudo nano /etc/systemd/system/cloudflared-sonarqube.service
```

Content (adjust username if needed):
```ini
[Unit]
Description=Cloudflare Tunnel for SonarQube
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/ubuntu/.cloudflared/config.yml run sonarqube-tunnel
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-sonarqube
sudo systemctl start cloudflared-sonarqube
```

---

### 1. Install PostgreSQL Database

SonarQube requires a database. We'll use PostgreSQL (recommended).

**Install PostgreSQL:**

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
```

**Start PostgreSQL service:**

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Verify PostgreSQL is running:**

```bash
sudo systemctl status postgresql
```

Expected: `active (running)`

**Create SonarQube database and user:**

```bash
sudo -i -u postgres
```

You're now in PostgreSQL user shell.

```bash
psql
```

You're now in PostgreSQL prompt.

```sql
CREATE USER sonarqube WITH PASSWORD 'sonarqube_password';
CREATE DATABASE sonarqube OWNER sonarqube;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonarqube;
\q
```

Exit PostgreSQL user:

```bash
exit
```

**Verify database creation:**

```bash
sudo -u postgres psql -c "\l" | grep sonarqube
```

Should show `sonarqube` database.

---

### 2. Configure System Requirements

SonarQube has specific system requirements.

**Increase system limits:**

```bash
sudo nano /etc/sysctl.conf
```

Add at the end:

```
vm.max_map_count=524288
fs.file-max=131072
```

Save and exit.

**Apply changes:**

```bash
sudo sysctl -p
```

**Configure ulimit:**

```bash
sudo nano /etc/security/limits.conf
```

Add at the end:

```
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
```

Save and exit.

**Install Java 17 (SonarQube requirement):**

```bash
sudo apt install -y openjdk-17-jdk
```

**Verify Java installation:**

```bash
java -version
```

Expected output:
```
openjdk version "17.0.x"
OpenJDK Runtime Environment (build 17.0.x+x-Ubuntu-x)
OpenJDK 64-Bit Server VM (build 17.0.x+x-Ubuntu-x, mixed mode, sharing)
```

---

### 3. Install SonarQube

**Create SonarQube user:**

```bash
sudo useradd -r -s /bin/bash sonarqube
```

**Download SonarQube:**

```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
```

**⚠️ Note:** Version 10.4.1 is used here. Check [SonarQube Downloads](https://www.sonarqube.org/downloads/) for latest version.

**Install unzip:**

```bash
sudo apt install -y unzip
```

**Extract SonarQube:**

```bash
sudo unzip sonarqube-10.4.1.88267.zip
```

**Rename directory:**

```bash
sudo mv sonarqube-10.4.1.88267 sonarqube
```

**Set ownership:**

```bash
sudo chown -R sonarqube:sonarqube /opt/sonarqube
```

**Remove zip file:**

```bash
sudo rm sonarqube-10.4.1.88267.zip
```

---

### 4. Configure SonarQube

**Edit SonarQube configuration:**

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

**Find and uncomment/modify these lines:**

```properties
# Database Configuration
sonar.jdbc.username=sonarqube
sonar.jdbc.password=sonarqube_password
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

# Web Server
sonar.web.host=127.0.0.1
sonar.web.port=9000

# Application Context Path (optional)
sonar.web.context=/
```

**⚠️ Important:** Replace `sonarqube_password` with the password you set during PostgreSQL setup.

Save and exit.

**Create systemd service for SonarQube:**

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

**Paste:**

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
```

Save and exit.

**Enable and start SonarQube:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube
```

**⚠️ SonarQube takes 2-3 minutes to start. Monitor startup:**

```bash
sudo journalctl -u sonarqube -f
```

Wait for: `SonarQube is operational`

Press `Ctrl+C` to exit log view.

**Check SonarQube status:**

```bash
sudo systemctl status sonarqube
```

Expected: `active (running)`

**Verify SonarQube is listening on port 9000:**

```bash
sudo ss -tlnp | grep 9000
```

Expected output:
```
tcp   LISTEN  0   50   127.0.0.1:9000   *:*   users:(("java",pid=xxxx))
```

**Test local SonarQube access:**

```bash
curl -I http://localhost:9000
```

Expected: `HTTP/1.1 200 OK`

---

### 5. Initial SonarQube Configuration

**Access SonarQube via custom domain:**

Open browser: **https://sonar.ibtisam-iq.com**

You should see SonarQube login page.

**Default credentials:**

- Username: `admin`
- Password: `admin`

**Step 1: Login**

1. Enter username: `admin`
2. Enter password: `admin`
3. Click **"Log in"**

**Step 2: Change Admin Password**

SonarQube will prompt you to change the default password.

1. Enter new password (strong password recommended)
2. Confirm new password
3. Click **"Update"**

**⚠️ Save this password securely** - you'll need it for Jenkins integration.

**Step 3: Initial Setup**

SonarQube dashboard will load. You're now ready to analyze code!

---

### 6. Integrate with Jenkins

**Generate SonarQube token:**

1. In SonarQube, click on **"A"** (admin icon) → **"My Account"**
2. Go to **"Security"** tab
3. Under **"Generate Tokens"**:
   - Name: `jenkins-integration`
   - Type: `Global Analysis Token`
   - Expires in: `90 days` (or `No expiration`)
4. Click **"Generate"**
5. **⚠️ Copy the token** - you won't see it again!

Example token: `squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8`

**Configure Jenkins (on node-01):**

1. Go to Jenkins: **https://jenkins.ibtisam-iq.com**
2. Navigate to: **Manage Jenkins** → **System**
3. Scroll to **"SonarQube servers"** section
4. Click **"Add SonarQube"**
5. Configure:
   - Name: `SonarQube`
   - Server URL: `https://sonar.ibtisam-iq.com`
   - Server authentication token: Click **"Add"** → **"Jenkins"**
     - Kind: `Secret text`
     - Secret: `<paste-sonarqube-token>`
     - ID: `sonarqube-token`
     - Description: `SonarQube Authentication Token`
     - Click **"Add"**
   - Select credential: `sonarqube-token`
6. Click **"Save"**

**Install SonarQube Scanner plugin in Jenkins:**

1. Go to: **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for: `SonarQube Scanner`
3. Check the box and click **"Install"**
4. Wait for installation to complete

**Configure SonarQube Scanner:**

1. Go to: **Manage Jenkins** → **Tools**
2. Scroll to **"SonarQube Scanner"** section
3. Click **"Add SonarQube Scanner"**
4. Configure:
   - Name: `SonarQube Scanner`
   - ✅ Check **"Install automatically"**
   - Version: Select latest version
5. Click **"Save"**

**Create test pipeline to verify integration:**

1. Go to Jenkins Dashboard
2. Click **"New Item"**
3. Enter name: `sonarqube-test`
4. Select **"Pipeline"**
5. Click **"OK"**
6. Scroll to **"Pipeline"** section
7. Paste:

```groovy
pipeline {
    agent any
    
    stages {
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQube Scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=test-project \
                            -Dsonar.projectName='Test Project' \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions=**/*.java
                        """
                    }
                }
            }
        }
    }
}
```

8. Click **"Save"**
9. Click **"Build Now"**
10. Check **"Console Output"**

If build succeeds and you see `ANALYSIS SUCCESSFUL`, integration is working!

---

## Verification

**Complete checklist to verify successful installation:**

### 1. Service Status Check

```bash
sudo systemctl status sonarqube
sudo systemctl status postgresql
sudo systemctl status nginx
sudo systemctl status cloudflared-sonarqube
```

All should show: `active (running)`

### 2. Port Verification

```bash
sudo ss -tlnp | grep :80    # Nginx
sudo ss -tlnp | grep :9000  # SonarQube
sudo ss -tlnp | grep :5432  # PostgreSQL
```

All should show processes listening.

### 3. Web Access Test

Open browser: **https://sonar.ibtisam-iq.com**

- ✅ Should load SonarQube dashboard
- ✅ SSL certificate valid (lock icon in browser)
- ✅ No security warnings
- ✅ URL shows `https://` (not `http://`)

### 4. SSL Certificate Verification

```bash
curl -I https://sonar.ibtisam-iq.com
```

Should return: `HTTP/2 200`

### 5. Database Connection Test

```bash
sudo -u postgres psql -d sonarqube -c "\dt" | head -5
```

Should show SonarQube tables.

### 6. Create Test Project

**In SonarQube dashboard:**

1. Click **"Create Project"** → **"Manually"**
2. Project key: `test-app`
3. Display name: `Test Application`
4. Click **"Set Up"**
5. Choose **"Locally"**
6. Generate token (or use existing)
7. Select build tool: **"Other"**
8. Select OS: **"Linux"**

You'll see scanner command example.

If project is created successfully, **SonarQube is working!**

---

## Troubleshooting

### Issue: SonarQube service won't start

**Check logs:**

```bash
sudo journalctl -u sonarqube -n 100 --no-pager
```

**Common error: OutOfMemoryError**

Edit JVM settings:

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

Find and modify:

```properties
sonar.web.javaOpts=-Xmx2048m -Xms1024m
sonar.ce.javaOpts=-Xmx2048m -Xms1024m
sonar.search.javaOpts=-Xms512m -Xmx512m
```

Restart:

```bash
sudo systemctl restart sonarqube
```

---

### Issue: Cannot connect to PostgreSQL

**Check PostgreSQL status:**

```bash
sudo systemctl status postgresql
```

**Test connection manually:**

```bash
psql -U sonarqube -d sonarqube -h localhost -W
```

Enter password when prompted.

If connection fails, check:

```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf
```

Ensure this line exists:

```
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
```

Restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

---

### Issue: SonarQube slow startup

**Common causes:**

1. **Insufficient RAM**: SonarQube needs at least 4GB total system RAM
2. **Database initialization**: First startup takes 5-10 minutes

**Monitor startup progress:**

```bash
tail -f /opt/sonarqube/logs/sonar.log
tail -f /opt/sonarqube/logs/web.log
tail -f /opt/sonarqube/logs/ce.log
tail -f /opt/sonarqube/logs/es.log
```

Look for: `SonarQube is operational`

**Check system resources:**

```bash
free -h
df -h
top
```

---

### Issue: Jenkins integration not working

**Verify SonarQube token:**

Test API access:

```bash
curl -u squ_yourtoken: https://sonar.ibtisam-iq.com/api/system/status
```

Should return JSON with status.

**Check Jenkins logs:**

In Jenkins build console output, look for:

```
INFO: Scanner configuration file: /path/to/sonar-scanner
INFO: Project root configuration file: NONE
INFO: SonarQube server: https://sonar.ibtisam-iq.com
```

**Common issues:**

1. **Wrong token** → Regenerate token in SonarQube
2. **Wrong URL** → Verify `https://sonar.ibtisam-iq.com` (not `http://`)
3. **Network issue** → Test: `curl https://sonar.ibtisam-iq.com` from Jenkins node

---

### Issue: "Compute Engine" not starting

**Check CE logs:**

```bash
tail -f /opt/sonarqube/logs/ce.log
```

**Common error: Elasticsearch failed**

Check ES logs:

```bash
tail -f /opt/sonarqube/logs/es.log
```

**Fix: Increase vm.max_map_count**

```bash
sudo sysctl -w vm.max_map_count=524288
```

Make permanent:

```bash
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
```

Restart SonarQube:

```bash
sudo systemctl restart sonarqube
```

---

### Issue: Forgot admin password

**Reset admin password:**

```bash
sudo -u postgres psql -d sonarqube
```

Run:

```sql
UPDATE users SET crypted_password='$2a$12$uCkkXmhW5ThVK8mpBvnXOOJRLd64LJeHTeCkSuB3lfaR2N0AYBaSi', salt=null, hash_method='BCRYPT' WHERE login='admin';
\q
```

This resets admin password to: `admin`

Login and change it immediately.

---

## Next Steps

Now that SonarQube is running, you can:

1. **Create Quality Gates** to enforce code quality standards
2. **Configure Quality Profiles** for different languages
3. **Setup Webhooks** for Jenkins build status updates
4. **Configure Email Notifications** for quality gate failures
5. **Enable LDAP/SSO** for centralized authentication
6. **Setup Backup Strategy** for SonarQube database
7. **Configure Branch Analysis** for pull requests
8. **Setup Security Hotspot Review** workflows
9. **Create Custom Rules** using rule templates
10. **Integrate with GitHub/GitLab** for automatic scanning

---

## Appendix: Useful Commands

### SonarQube Service Management

```bash
# Start SonarQube
sudo systemctl start sonarqube

# Stop SonarQube
sudo systemctl stop sonarqube

# Restart SonarQube
sudo systemctl restart sonarqube

# Check status
sudo systemctl status sonarqube

# View logs (live)
sudo journalctl -u sonarqube -f

# View specific log files
tail -f /opt/sonarqube/logs/sonar.log
tail -f /opt/sonarqube/logs/web.log
tail -f /opt/sonarqube/logs/ce.log
tail -f /opt/sonarqube/logs/es.log
```

### PostgreSQL Management

```bash
# Connect to database
sudo -u postgres psql -d sonarqube

# List databases
sudo -u postgres psql -c "\l"

# List tables in sonarqube database
sudo -u postgres psql -d sonarqube -c "\dt"

# Database size
sudo -u postgres psql -d sonarqube -c "SELECT pg_size_pretty(pg_database_size('sonarqube'));"

# Backup database
sudo -u postgres pg_dump sonarqube > sonarqube-backup-$(date +%Y%m%d).sql

# Restore database
sudo -u postgres psql sonarqube < sonarqube-backup-20260220.sql
```

### SonarQube API Examples

```bash
# Get system status
curl -u admin:password https://sonar.ibtisam-iq.com/api/system/status

# List projects
curl -u admin:password https://sonar.ibtisam-iq.com/api/projects/search

# Get project metrics
curl -u admin:password "https://sonar.ibtisam-iq.com/api/measures/component?component=test-app&metricKeys=ncloc,bugs,vulnerabilities,code_smells"

# Create project
curl -u admin:password -X POST "https://sonar.ibtisam-iq.com/api/projects/create?name=MyProject&project=my-project-key"
```

### SonarQube File Locations

```bash
# Installation directory
/opt/sonarqube/

# Configuration
/opt/sonarqube/conf/sonar.properties

# Logs
/opt/sonarqube/logs/

# Data directory
/opt/sonarqube/data/

# Extensions (plugins)
/opt/sonarqube/extensions/

# Temporary files
/opt/sonarqube/temp/
```

### System Monitoring

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check SonarQube process
ps aux | grep sonarqube

# Check all related processes
ps aux | grep -E "sonarqube|postgres|nginx|cloudflared"

# Monitor system load
top
htop  # If installed
```

### Backup SonarQube

**Complete backup:**

```bash
# Stop SonarQube
sudo systemctl stop sonarqube

# Backup database
sudo -u postgres pg_dump sonarqube > sonarqube-db-$(date +%Y%m%d).sql

# Backup data directory
sudo tar -czf sonarqube-data-$(date +%Y%m%d).tar.gz /opt/sonarqube/data/

# Backup extensions (plugins)
sudo tar -czf sonarqube-extensions-$(date +%Y%m%d).tar.gz /opt/sonarqube/extensions/

# Start SonarQube
sudo systemctl start sonarqube
```

### Restore SonarQube

```bash
# Stop SonarQube
sudo systemctl stop sonarqube

# Restore database
sudo -u postgres psql -d sonarqube < sonarqube-db-20260220.sql

# Restore data
sudo tar -xzf sonarqube-data-20260220.tar.gz -C /

# Restore extensions
sudo tar -xzf sonarqube-extensions-20260220.tar.gz -C /

# Fix permissions
sudo chown -R sonarqube:sonarqube /opt/sonarqube/

# Start SonarQube
sudo systemctl start sonarqube
```

---

## Resources

- **Official SonarQube Documentation:** https://docs.sonarqube.org/latest/
- **SonarQube Downloads:** https://www.sonarqube.org/downloads/
- **SonarQube Community Forum:** https://community.sonarsource.com/
- **Jenkins SonarQube Plugin:** https://plugins.jenkins.io/sonar/
- **SonarQube API Documentation:** https://docs.sonarqube.org/latest/extend/web-api/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/

---

**Documentation maintained as part of:** https://nectar.ibtisam-iq.com  
**Project:** Self-Hosted CI/CD Stack on iximiuz Labs  
**GitHub:** https://github.com/ibtisam-iq/silver-stack