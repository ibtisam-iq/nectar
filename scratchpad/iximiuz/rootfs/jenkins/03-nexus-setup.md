# Nexus Repository Manager Setup on iximiuz Labs with SSL and Custom Domain

**Author:** Muhammad Ibtisam Iqbal  
**Last Updated:** February 20, 2026  
**Environment:** iximiuz Labs MiniLAN Playground (node-03)  
**Public URL:** https://nexus.ibtisam-iq.com  
**Internal Port:** 8081

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Installation](#step-by-step-installation)
  - [Common Setup (Nginx + Cloudflare Tunnel)](#common-setup-nginx--cloudflare-tunnel)
  - [1. Install Java Runtime](#1-install-java-runtime)
  - [2. Install Nexus Repository Manager](#2-install-nexus-repository-manager)
  - [3. Configure Nexus](#3-configure-nexus)
  - [4. Initial Nexus Configuration](#4-initial-nexus-configuration)
  - [5. Create Repositories](#5-create-repositories)
  - [6. Integrate with Jenkins](#6-integrate-with-jenkins)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)
- [Appendix](#appendix)

---

## Overview

This guide provides complete step-by-step instructions for setting up **Nexus Repository Manager OSS** on an iximiuz Labs playground node, secured with SSL via **Cloudflare Tunnel** and **Nginx reverse proxy**, and accessible through a custom domain.

**What is Nexus Repository Manager?**

Nexus Repository Manager is a universal artifact repository that supports Maven, npm, Docker, PyPI, NuGet, and many other formats. It acts as a central hub for storing and managing build artifacts and dependencies.

**Why Nexus Repository?**

- **Universal Repository**: Support for 30+ formats (Maven, npm, Docker, PyPI, etc.)
- **Proxy & Cache**: Cache remote repositories for faster builds
- **Private Hosting**: Host your own artifacts securely
- **Role-Based Access**: Granular permissions and security
- **Lifecycle Management**: Automated cleanup policies
- **High Availability**: Clustering and replication support

---

## Prerequisites

Before starting, ensure you have:

- ✅ SSH access to node-03 in iximiuz Labs
- ✅ Cloudflare account with domain configured (ibtisam-iq.com)
- ✅ Basic knowledge of Linux command line
- ✅ At least 4GB RAM available on node (Nexus requires 2.5-3GB heap)
- ✅ Ubuntu 24.04 LTS running on node-03

**Resource Requirements (node-03):**

- CPU: 2 cores minimum (4 cores recommended)
- RAM: 4GB minimum (8GB recommended for production)
- Disk: 50GB minimum (depends on artifact storage needs)
- OS: Ubuntu 24.04 LTS
- Network: Internet connectivity required

---

## Architecture

```
Internet Users
    ↓
Cloudflare DNS (nexus.ibtisam-iq.com)
    ↓
Cloudflare Edge Network (DDoS Protection, CDN)
    ↓
Cloudflare Tunnel (Encrypted Connection)
    ↓
node-03 | cloudflared daemon (localhost:80)
    ↓
Nginx Reverse Proxy (localhost:80)
    ↓
Nexus Repository Manager (localhost:8081)
    ↓
Blob Storage (File System)
```

**Traffic Flow:**

1. User accesses `https://nexus.ibtisam-iq.com`
2. Cloudflare DNS resolves to Cloudflare edge
3. Request enters Cloudflare Tunnel (SSL terminated at Cloudflare)
4. Cloudflared daemon on node-03 receives request
5. Forwards to Nginx reverse proxy on localhost:80
6. Nginx proxies to Nexus application
7. Nexus serves artifacts from blob storage
8. Response travels back through same encrypted path

**Component Interaction:**

- **Jenkins (node-01)** → Uploads/downloads artifacts → **Nexus (node-03)**
- **Developers** → Pull dependencies → **Nexus (node-03)**
- **Docker Registry** → Push/pull images → **Nexus (node-03)**

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

| Item | Jenkins Value | Nexus Value |
|------|---------------|-------------|
| Node | node-01 | node-03 |
| Subdomain | jenkins.ibtisam-iq.com | nexus.ibtisam-iq.com |
| Port | 8080 | 8081 |
| Tunnel Name | jenkins-tunnel | nexus-tunnel |
| Service File | cloudflared-jenkins.service | cloudflared-nexus.service |

**Quick Reference - Nginx Configuration:**

```nginx
server {
    listen 80;
    server_name nexus.ibtisam-iq.com;

    # Increase body size for large artifact uploads
    client_max_body_size 500M;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Increase timeouts for large uploads
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

Save to: `/etc/nginx/sites-available/nexus`

Enable: `sudo ln -s /etc/nginx/sites-available/nexus /etc/nginx/sites-enabled/`

**Quick Reference - Cloudflare Tunnel Config:**

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: /home/ubuntu/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  - hostname: nexus.ibtisam-iq.com
    service: http://localhost:80
  - service: http_status:404
```

Save to: `~/.cloudflared/config.yml`

**Create tunnel:**
```bash
cloudflared tunnel create nexus-tunnel
```

**Route DNS:**
```bash
cloudflared tunnel route dns nexus-tunnel nexus.ibtisam-iq.com
```

**Systemd service:**
```bash
sudo nano /etc/systemd/system/cloudflared-nexus.service
```

Content (adjust username if needed):
```ini
[Unit]
Description=Cloudflare Tunnel for Nexus Repository
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/ubuntu/.cloudflared/config.yml run nexus-tunnel
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-nexus
sudo systemctl start cloudflared-nexus
```

---

### 1. Install Java Runtime

Nexus Repository Manager requires **Java 8 or 11**. We'll use OpenJDK 8.

**Install OpenJDK 8:**

```bash
sudo apt update
sudo apt install -y openjdk-8-jre-headless
```

**Verify Java installation:**

```bash
java -version
```

Expected output:

```
openjdk version "1.8.0_xxx"
OpenJDK Runtime Environment (build 1.8.0_xxx-8uXXX)
OpenJDK 64-Bit Server VM (build 25.xxx-bXX, mixed mode)
```

---

### 2. Install Nexus Repository Manager

**Create directories:**

```bash
sudo mkdir -p /opt/nexus
sudo mkdir -p /opt/sonatype-work
```

**Download Nexus Repository Manager:**

```bash
cd /opt
sudo wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
```

**Extract:**

```bash
sudo tar -xvzf latest-unix.tar.gz
```

**Rename directories:**

```bash
sudo mv nexus-3* nexus
```

**Verify extraction:**

```bash
ls -la /opt/
```

You should see: `nexus/` and `sonatype-work/`

**Create nexus user:**

```bash
sudo useradd -r -s /bin/bash nexus
```

**Set ownership:**

```bash
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work
```

**Configure Nexus to run as nexus user:**

```bash
sudo nano /opt/nexus/bin/nexus.rc
```

**Uncomment and set:**

```bash
run_as_user="nexus"
```

Save and exit.

**Remove downloaded archive:**

```bash
sudo rm /opt/latest-unix.tar.gz
```

---

### 3. Configure Nexus

**Adjust JVM memory settings:**

```bash
sudo nano /opt/nexus/bin/nexus.vmoptions
```

**Modify these values (adjust based on available RAM):**

```
-Xms1024m
-Xmx2048m
-XX:MaxDirectMemorySize=2048m
-XX:LogFile=./sonatype-work/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=./sonatype-work/nexus3
-Dkaraf.log=./sonatype-work/nexus3/log
-Djava.io.tmpdir=./sonatype-work/nexus3/tmp
```

**Key settings:**
- `-Xms1024m`: Initial heap size (1GB)
- `-Xmx2048m`: Maximum heap size (2GB)
- `-XX:MaxDirectMemorySize=2048m`: Off-heap memory (2GB)

Save and exit.

**Create systemd service:**

```bash
sudo nano /etc/systemd/system/nexus.service
```

**Paste:**

```ini
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
```

Save and exit.

**Enable and start Nexus service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus
```

**⚠️ Nexus takes 2-3 minutes to start. Monitor startup:**

```bash
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log
```

Wait for: `Started Sonatype Nexus OSS`

Press `Ctrl+C` to exit log view.

**Check Nexus status:**

```bash
sudo systemctl status nexus
```

Expected: `active (running)`

**Verify Nexus is listening on port 8081:**

```bash
sudo ss -tlnp | grep 8081
```

Expected output:
```
tcp   LISTEN   0   50   *:8081   *:*   users:(("java",pid=xxxx))
```

**Test local Nexus access:**

```bash
curl -I http://localhost:8081
```

Expected: `HTTP/1.1 200 OK`

---

### 4. Initial Nexus Configuration

**Retrieve initial admin password:**

```bash
sudo cat /opt/sonatype-work/nexus3/admin.password
```

**Example output:**

```
a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6
```

**⚠️ Copy this password** - you'll need it for the next step.

**Access Nexus via custom domain:**

Open browser: **https://nexus.ibtisam-iq.com**

You should see Nexus welcome page.

**Step 1: Sign In**

1. Click **"Sign in"** (top-right corner)
2. Username: `admin`
3. Password: `<paste-initial-password>`
4. Click **"Sign in"**

**Step 2: Setup Wizard**

Nexus will launch a setup wizard.

**Change Admin Password:**

1. Enter new password (strong password recommended)
2. Confirm new password
3. Click **"Next"**

**Configure Anonymous Access:**

1. Select: **"Enable anonymous access"** (recommended for read-only)
   - This allows unauthenticated users to download artifacts
   - They cannot upload or modify
2. Click **"Next"**

**Finish Setup:**

1. Review configuration
2. Click **"Finish"**

You'll be redirected to Nexus dashboard.

**Delete initial password file:**

```bash
sudo rm /opt/sonatype-work/nexus3/admin.password
```

---

### 5. Create Repositories

**Repository Types:**

- **Hosted**: Store your own artifacts
- **Proxy**: Cache remote repositories (Maven Central, npm registry)
- **Group**: Combine multiple repositories into one URL

#### Create Docker Registry (Hosted)

1. Go to: **Server administration** (⚙️ icon) → **Repositories**
2. Click **"Create repository"**
3. Select **"docker (hosted)"**
4. Configure:
   - **Name:** `docker-hosted`
   - **HTTP port:** `5000`
   - ✅ **Enable Docker V1 API**
   - **Blob store:** `default`
   - **Deployment policy:** `Allow redeploy`
5. Click **"Create repository"**

#### Create Maven Repository (Hosted)

1. Click **"Create repository"**
2. Select **"maven2 (hosted)"**
3. Configure:
   - **Name:** `maven-releases`
   - **Version policy:** `Release`
   - **Layout policy:** `Strict`
   - **Blob store:** `default`
   - **Deployment policy:** `Allow redeploy`
4. Click **"Create repository"**

**Create Maven Snapshots:**

1. Click **"Create repository"**
2. Select **"maven2 (hosted)"**
3. Configure:
   - **Name:** `maven-snapshots`
   - **Version policy:** `Snapshot`
   - **Layout policy:** `Strict`
   - **Blob store:** `default`
   - **Deployment policy:** `Allow redeploy`
4. Click **"Create repository"**

#### Create Maven Proxy (Maven Central)

1. Click **"Create repository"**
2. Select **"maven2 (proxy)"**
3. Configure:
   - **Name:** `maven-central`
   - **Remote storage:** `https://repo1.maven.org/maven2/`
   - **Blob store:** `default`
4. Click **"Create repository"**

#### Create Maven Group (Unified Access)

1. Click **"Create repository"**
2. Select **"maven2 (group)"**
3. Configure:
   - **Name:** `maven-public`
   - **Blob store:** `default`
   - **Member repositories:** (order matters!)
     1. `maven-releases`
     2. `maven-snapshots`
     3. `maven-central`
4. Click **"Create repository"**

**Why group repository?**

Instead of configuring multiple repository URLs, developers use one URL: `https://nexus.ibtisam-iq.com/repository/maven-public/`

#### Create npm Proxy

1. Click **"Create repository"**
2. Select **"npm (proxy)"**
3. Configure:
   - **Name:** `npm-proxy`
   - **Remote storage:** `https://registry.npmjs.org`
   - **Blob store:** `default`
4. Click **"Create repository"**

#### Create PyPI Proxy

1. Click **"Create repository"**
2. Select **"pypi (proxy)"**
3. Configure:
   - **Name:** `pypi-proxy`
   - **Remote storage:** `https://pypi.org`
   - **Blob store:** `default`
4. Click **"Create repository"**

#### Create Raw Repository (Generic Files)

1. Click **"Create repository"**
2. Select **"raw (hosted)"**
3. Configure:
   - **Name:** `raw-hosted`
   - **Blob store:** `default`
   - **Deployment policy:** `Allow redeploy`
4. Click **"Create repository"**

**Verify repositories:**

Go to: **Browse** → You should see all created repositories.

---

### 6. Integrate with Jenkins

#### Configure Nexus Credentials in Jenkins

**On Jenkins (node-01):**

1. Go to: **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** → **Add Credentials**
3. Configure:
   - **Kind:** `Username with password`
   - **Username:** `admin`
   - **Password:** `<your-nexus-password>`
   - **ID:** `nexus-credentials`
   - **Description:** `Nexus Repository Credentials`
4. Click **"Create"**

#### Configure Maven Settings

1. Go to: **Manage Jenkins** → **Managed files**
2. Click **"Add a new Config"** → **"Global Maven settings.xml"**
3. Configure:
   - **ID:** `nexus-maven-settings`
   - **Name:** `Nexus Maven Settings`
   - **Content:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>${NEXUS_PASSWORD}</password>
    </server>
    <server>
      <id>nexus-snapshots</id>
      <username>admin</username>
      <password>${NEXUS_PASSWORD}</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.ibtisam-iq.com/repository/maven-public/</url>
    </mirror>
  </mirrors>
</settings>
```

4. Click **"Submit"**

#### Configure Docker Registry

**On Jenkins node (node-01):**

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "insecure-registries": ["nexus.ibtisam-iq.com:5000"]
}
```

**Restart Docker:**

```bash
sudo systemctl restart docker
```

**Test Docker push:**

```bash
# Login to registry
docker login nexus.ibtisam-iq.com:5000
# Username: admin
# Password: <your-nexus-password>

# Tag an image
docker pull alpine:latest
docker tag alpine:latest nexus.ibtisam-iq.com:5000/alpine:latest

# Push to Nexus
docker push nexus.ibtisam-iq.com:5000/alpine:latest
```

**Verify in Nexus:**

- Go to: **Browse** → **docker-hosted**
- You should see `alpine` image

#### Create Test Pipeline

**Create Jenkins pipeline to test Maven integration:**

1. Go to Jenkins Dashboard
2. Click **"New Item"**
3. Enter name: `nexus-maven-test`
4. Select **"Pipeline"**
5. Click **"OK"**
6. Scroll to **"Pipeline"** section
7. Paste:

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven'
    }
    
    stages {
        stage('Build') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn -s $MAVEN_SETTINGS clean package'
                }
            }
        }
        
        stage('Deploy to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh '''
                        mvn deploy:deploy-file \
                        -DgroupId=com.example \
                        -DartifactId=test-app \
                        -Dversion=1.0.0 \
                        -Dpackaging=jar \
                        -Dfile=target/app.jar \
                        -DrepositoryId=nexus-releases \
                        -Durl=https://nexus.ibtisam-iq.com/repository/maven-releases/ \
                        -Dusername=$NEXUS_USER \
                        -Dpassword=$NEXUS_PASSWORD
                    '''
                }
            }
        }
    }
}
```

8. Click **"Save"**

---

## Verification

**Complete checklist to verify successful installation:**

### 1. Service Status Check

```bash
sudo systemctl status nexus
sudo systemctl status nginx
sudo systemctl status cloudflared-nexus
```

All should show: `active (running)`

### 2. Port Verification

```bash
sudo ss -tlnp | grep :80    # Nginx
sudo ss -tlnp | grep :8081  # Nexus
```

Both should show processes listening.

### 3. Web Access Test

Open browser: **https://nexus.ibtisam-iq.com**

- ✅ Should load Nexus dashboard
- ✅ SSL certificate valid (lock icon in browser)
- ✅ No security warnings
- ✅ URL shows `https://` (not `http://`)

### 4. Repository Check

Navigate to: **Browse** → verify all repositories:

- ✅ docker-hosted
- ✅ maven-releases
- ✅ maven-snapshots
- ✅ maven-central
- ✅ maven-public
- ✅ npm-proxy
- ✅ pypi-proxy
- ✅ raw-hosted

### 5. Docker Registry Test

```bash
# From any node with Docker
curl https://nexus.ibtisam-iq.com:5000/v2/_catalog
```

Should return JSON with repositories list.

### 6. Maven Repository Test

```bash
curl -u admin:password https://nexus.ibtisam-iq.com/service/rest/v1/repositories
```

Should return JSON with all repositories.

---

## Troubleshooting

### Issue: Nexus service won't start

**Check logs:**

```bash
sudo tail -n 100 /opt/sonatype-work/nexus3/log/nexus.log
```

**Common error: OutOfMemoryError**

Increase heap:

```bash
sudo nano /opt/nexus/bin/nexus.vmoptions
```

Change:
```
-Xmx3072m
```

Restart:

```bash
sudo systemctl restart nexus
```

---

### Issue: Docker push fails

**Error: `x509: certificate signed by unknown authority`**

Add Nexus as insecure registry:

```bash
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "insecure-registries": ["nexus.ibtisam-iq.com:5000", "nexus.ibtisam-iq.com"]
}
```

Restart:

```bash
sudo systemctl restart docker
```

---

### Issue: Cannot access Docker registry on port 5000

**Check if Nexus connector is listening:**

```bash
sudo ss -tlnp | grep 5000
```

**Verify in Nexus:**

- Go to: **Repositories** → **docker-hosted**
- Ensure **HTTP** connector is enabled on port `5000`

**Check firewall (if applicable):**

```bash
sudo ufw status
sudo ufw allow 5000/tcp
```

---

### Issue: Maven artifacts not uploading

**Check authentication:**

Test with curl:

```bash
curl -u admin:password -X POST "https://nexus.ibtisam-iq.com/service/rest/v1/components?repository=maven-releases" \
-H "accept: application/json" \
-F "maven2.groupId=com.example" \
-F "maven2.artifactId=test" \
-F "maven2.version=1.0" \
-F "maven2.asset1=@file.jar" \
-F "maven2.asset1.extension=jar"
```

**Common issues:**

1. **Wrong credentials** → Verify in Nexus
2. **Repository doesn't exist** → Check repository name
3. **Deployment policy** → Set to "Allow redeploy"

---

### Issue: Blob store full

**Check disk space:**

```bash
df -h /opt/sonatype-work/nexus3/blobs/
```

**Check blob store size in Nexus:**

Go to: **Server administration** → **Blob Stores**

**Create cleanup policy:**

1. Go to: **Server administration** → **Cleanup Policies**
2. Click **"Create Cleanup Policy"**
3. Configure:
   - **Name:** `delete-old-snapshots`
   - **Format:** `maven2`
   - **Component Age:** `30` days
   - **Release Type:** `Snapshot`
4. Click **"Create"**

**Apply to repository:**

1. Go to: **Repositories** → **maven-snapshots**
2. Click **"Edit"**
3. Under **"Cleanup Policies"**, select `delete-old-snapshots`
4. Click **"Save"**

**Run cleanup task:**

Go to: **Server administration** → **Tasks** → **"Admin - Compact blob store"**

---

## Next Steps

Now that Nexus is running, you can:

1. **Configure Cleanup Policies** to remove old artifacts
2. **Setup Backup Strategy** for blob stores and database
3. **Create Custom Roles** for team-based access control
4. **Configure LDAP/SSO** for centralized authentication
5. **Setup PyPI Repository** for Python packages
6. **Create Helm Chart Repository** for Kubernetes
7. **Enable Content Selectors** for fine-grained permissions
8. **Configure Scheduled Tasks** for maintenance
9. **Setup High Availability** with clustering
10. **Monitor with Nexus IQ** for component intelligence

---

## Appendix: Useful Commands

### Nexus Service Management

```bash
# Start Nexus
sudo systemctl start nexus

# Stop Nexus
sudo systemctl stop nexus

# Restart Nexus
sudo systemctl restart nexus

# Check status
sudo systemctl status nexus

# View logs
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log
sudo tail -f /opt/sonatype-work/nexus3/log/request.log
```

### Nexus API Examples

```bash
# Get system status
curl -u admin:password https://nexus.ibtisam-iq.com/service/rest/v1/status

# List repositories
curl -u admin:password https://nexus.ibtisam-iq.com/service/rest/v1/repositories

# List components in repository
curl -u admin:password https://nexus.ibtisam-iq.com/service/rest/v1/components?repository=maven-releases

# Search for artifact
curl -u admin:password "https://nexus.ibtisam-iq.com/service/rest/v1/search?name=myapp"

# Delete component
curl -u admin:password -X DELETE https://nexus.ibtisam-iq.com/service/rest/v1/components/{componentId}
```

### Docker Commands

```bash
# List images in registry
curl -u admin:password https://nexus.ibtisam-iq.com/service/rest/v1/components?repository=docker-hosted

# Login to registry
docker login nexus.ibtisam-iq.com:5000

# Pull image from Nexus
docker pull nexus.ibtisam-iq.com:5000/alpine:latest

# Push image to Nexus
docker push nexus.ibtisam-iq.com:5000/myapp:1.0.0
```

### Maven Configuration

**Add to project `pom.xml`:**

```xml
<distributionManagement>
  <repository>
    <id>nexus-releases</id>
    <url>https://nexus.ibtisam-iq.com/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>nexus-snapshots</id>
    <url>https://nexus.ibtisam-iq.com/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>

<repositories>
  <repository>
    <id>nexus</id>
    <url>https://nexus.ibtisam-iq.com/repository/maven-public/</url>
  </repository>
</repositories>
```

**Add to `~/.m2/settings.xml`:**

```xml
<servers>
  <server>
    <id>nexus-releases</id>
    <username>admin</username>
    <password>your-password</password>
  </server>
  <server>
    <id>nexus-snapshots</id>
    <username>admin</username>
    <password>your-password</password>
  </server>
</servers>
<mirrors>
  <mirror>
    <id>nexus</id>
    <mirrorOf>*</mirrorOf>
    <url>https://nexus.ibtisam-iq.com/repository/maven-public/</url>
  </mirror>
</mirrors>
```

### npm Configuration

```bash
# Set registry
npm config set registry https://nexus.ibtisam-iq.com/repository/npm-proxy/

# Login
npm login --registry=https://nexus.ibtisam-iq.com/repository/npm-proxy/

# Publish package
npm publish --registry=https://nexus.ibtisam-iq.com/repository/npm-hosted/
```

### Nexus File Locations

```bash
# Installation directory
/opt/nexus/

# Configuration
/opt/nexus/etc/nexus-default.properties

# Data directory
/opt/sonatype-work/nexus3/

# Blob stores
/opt/sonatype-work/nexus3/blobs/

# Logs
/opt/sonatype-work/nexus3/log/

# Database
/opt/sonatype-work/nexus3/db/

# Temporary files
/opt/sonatype-work/nexus3/tmp/
```

### Backup Nexus

**Complete backup:**

```bash
# Stop Nexus
sudo systemctl stop nexus

# Backup blob stores
sudo tar -czf nexus-blobs-$(date +%Y%m%d).tar.gz /opt/sonatype-work/nexus3/blobs/

# Backup database
sudo tar -czf nexus-db-$(date +%Y%m%d).tar.gz /opt/sonatype-work/nexus3/db/

# Start Nexus
sudo systemctl start nexus

# Copy backups to safe location
scp nexus-*.tar.gz user@backup-server:/backups/
```

### Restore Nexus

```bash
# Stop Nexus
sudo systemctl stop nexus

# Restore blob stores
sudo tar -xzf nexus-blobs-20260220.tar.gz -C /

# Restore database
sudo tar -xzf nexus-db-20260220.tar.gz -C /

# Fix permissions
sudo chown -R nexus:nexus /opt/sonatype-work/

# Start Nexus
sudo systemctl start nexus
```

---

## Resources

- **Official Nexus Documentation:** https://help.sonatype.com/repomanager3
- **Nexus Downloads:** https://www.sonatype.com/products/repository-oss-download
- **Docker Registry Configuration:** https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/docker-registry
- **Maven Repository Guide:** https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/maven-repositories
- **REST API Documentation:** https://help.sonatype.com/repomanager3/integrations/rest-and-integration-api
- **npm Configuration:** https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/npm-registry

---

**Documentation maintained as part of:** https://nectar.ibtisam-iq.com  
**Project:** Self-Hosted CI/CD Stack on iximiuz Labs  
**GitHub:** https://github.com/ibtisam-iq/silver-stack