# SilverStack – Jenkins LTS Rootfs Image for iximiuz Labs Playgrounds

Modern, production-grade **Jenkins LTS** environment packaged as an **OCI-compatible root filesystem image**, designed specifically to be mounted as the **root drive (`/`)** in **iximiuz Labs playground VMs**.

**Important note**:
This image is **not** designed to be run directly with `docker run`. It is built for **iximiuz Labs** playgrounds where it becomes the root filesystem of a full VM with real kernel and systemd as PID 1. Local Docker testing will show service failures (255/EXCEPTION) — this is expected and does **not** indicate a problem with the image.

**Public OCI Image**:
`oci:/ghcr.io/ibtisam-iq/silver-stack:latest`

---

## Features

- Jenkins LTS (latest stable release)
- Java: OpenJDK 21 (fixed)
- Nginx reverse proxy pre-configured (port 80 → localhost:8080)
- Full systemd init system (PID 1 = `/lib/systemd/systemd`)
- SSH server enabled (password + pubkey support)
- Interactive user: `ubuntu` (configurable via build arg)
- Jenkins daemon user: `jenkins` (fixed, created by Debian package)
- cloudflared binary pre-installed (setup via single dashboard command)
- No hardcoded domain — supports any domain via Cloudflare Tunnel
- Build-time healthcheck validates packages, files, symlinks, ownership

---

## Quick Start – iximiuz Labs Playground

1. In iximiuz Labs dashboard → Create or edit a playground
2. Go to **Drives** tab → Add Drive
3. **Source Type**: Custom Image
4. Source: `oci:/ghcr.io/ibtisam-iq/silver-stack:latest`
5. Mount Path: `/` (root filesystem)
6. Filesystem: ext4
7. Size: 50 GiB (or more recommended)
8. Save → Run Once or Clone Playground

**After boot**:

- Open the terminal in the iximiuz dashboard (this is your access to the VM)
- You will see the welcome MOTD with Cloudflare Tunnel setup instructions
- Jenkins dashboard (internal): http://localhost:8080
- Nginx proxy (internal): http://localhost:80

**Note**: This VM has **no public IP** accessible from the internet — Cloudflare Tunnel is required for external access.

---

## Making Jenkins Publicly Accessible (Cloudflare Tunnel – February 2026)

1. Go to https://one.dash.cloudflare.com → Zero Trust → Networks → Tunnels
2. Click "Create a tunnel" → give it a name (e.g. jenkins-lab)
3. Choose "Cloudflared" connector
4. Copy the single command shown in the dashboard
   It looks like this:
   `sudo cloudflared service install eyJhIjoi...` (long token)

5. In the VM terminal (from iximiuz dashboard), paste and run that command exactly as shown.
   It will:
   - Register your tunnel token
   - Create or update the systemd service (/etc/systemd/system/cloudflared.service)
   - Start and enable the service
   - Connect your tunnel immediately

6. Back in the dashboard → "Route Traffic" → Add a public hostname:
   - Subdomain: jenkins (or any name you want)
   - Domain: your domain (e.g. ibtisam-iq.com)
   - Path: (leave blank for all paths)
   - Service Type: HTTP
   - URL: localhost:80

Your Jenkins is now live at https://jenkins.yourdomain.com (with SSL & DDoS protection)

---

## Building the Image Yourself

```bash
# Clone repo
git clone https://github.com/ibtisam-iq/silver-stack.git
cd silver-stack

# Build with defaults (amd64 platform for iximiuz compatibility)
docker buildx build --platform linux/amd64 -t ghcr.io/ibtisam-iq/silver-stack:latest --no-cache .

# Customize interactive username or Jenkins port
docker buildx build --platform linux/amd64 \
  --build-arg USERNAME=ciuser \
  --build-arg JENKINS_PORT=9090 \
  -t myregistry/silver-stack:custom .

# Push to registry
docker push ghcr.io/ibtisam-iq/silver-stack:latest
```

### Build Arguments

| ARG              | Default     | Description                              |
|------------------|-------------|------------------------------------------|
| JENKINS_VERSION  | lts         | lts or weekly                            |
| USERNAME         | ubuntu      | Interactive SSH/lab user                 |
| USER_UID         | 1000        | UID for interactive user                 |
| USER_GID         | 1000        | GID for interactive user                 |
| JENKINS_PORT     | 8080        | Jenkins HTTP port                        |

Java is fixed at OpenJDK 21 — no ARG for it.

---

## Project Structure

```
├── configs
│   ├── jenkins.service          # Custom systemd unit for Jenkins
│   ├── nginx.conf               # Nginx reverse proxy config
│   ├── profile.d/
│   │   └── jenkins-env.sh       # Login shell prompt & bashrc source
│   ├── sshd_config              # SSH daemon config
│   └── sudoers.d/
│       └── jenkins-user         # Sudo rules for jenkins daemon
├── scripts
│   ├── configure-nginx.sh       # Enables site + creates minimal override
│   ├── entrypoint.sh            # Boot-time setup + MOTD
│   ├── healthcheck.sh           # Build-time validation
│   ├── install-jenkins.sh       # Installs Jenkins LTS + sets port
│   ├── install-cloudflared.sh   # Install Cloudflared binary
│   └── setup-user.sh            # Creates interactive user + sudoers
├── Dockerfile                   # Builds OCI rootfs image
└── README.md                    # This file
```

---

## Architecture & Security

**Traffic flow (with Cloudflare Tunnel)**:

```
User → https://jenkins.yourdomain.com
       ↓
Cloudflare Edge (SSL, DDoS protection)
       ↓
Cloudflare Tunnel (outbound encrypted)
       ↓
VM (iximiuz node) → cloudflared service
       ↓
Nginx (port 80) → localhost:8080
       ↓
Jenkins
```

**Security notes**:

- No inbound ports open — only outbound Cloudflare Tunnel
- Nginx proxies internally (127.0.0.1:8080)
- Jenkins runs as non-root user `jenkins`
- Systemd hardening enabled (PrivateTmp=yes, NoNewPrivileges=yes, etc.)
- Interactive user `ubuntu` has sudo — change password after first login
- SSH: password auth enabled (convenient for labs), pubkey also supported

---

## Troubleshooting

- Jenkins not starting → `systemctl status jenkins` / `journalctl -u jenkins -n 50`
- Nginx issues → `journalctl -u nginx` or `/var/log/nginx/jenkins-error.log`
- Cloudflare Tunnel problems → After running dashboard command: `journalctl -u cloudflared`
- No internet → Check iximiuz network settings
- Build fails → Run `docker buildx build --no-cache` and check logs

---

## Contributing / Customizing

Fork this repo and:

- Change `ARG USERNAME` for different lab user
- Update Nginx config for additional locations
- Add plugins in `install-jenkins.sh`
- Extend MOTD for your own instructions

PRs welcome!

---

## License

MIT – free to use, fork, modify, and share.

**Author:** Muhammad Ibtisam Iqbal
**GitHub:** https://github.com/ibtisam-iq/silver-stack
**OCI Image:** ghcr.io/ibtisam-iq/silver-stack:latest







ssh ubuntu@localhost -p 2222
# password: ubuntu

docker run -d \
  --name jenkins-test \
  --privileged \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 8080:8080 \
  -p 80:80 \
  -p 2222:22 \
  ghcr.io/ibtisam-iq/jenkins-lts-rootfs
