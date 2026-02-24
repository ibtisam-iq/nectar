# Jenkins Custom Rootfs for iximiuz Labs

Production-ready Jenkins LTS rootfs image with Java 21, Nginx, and custom user configuration.

## 📋 Overview

This directory contains everything needed to build a custom VM rootfs image for Jenkins on iximiuz Labs. The image boots with Jenkins already installed, configured, and ready to run.

## 🏗️ Architecture

```
Base: ghcr.io/iximiuz/labs/rootfs:ubuntu-24-04
├── Java 21 (OpenJDK)
├── Jenkins LTS (latest)
├── Nginx (reverse proxy)
├── Custom user (ubuntu) with sudo
└── Pre-configured systemd services
```

## 📁 Directory Structure

```
jenkins/
├── Dockerfile                 # Multi-stage build definition
├── .dockerignore              # Build exclusions
├── scripts/                   # Installation and setup scripts
│   ├── install-java.sh        # Java 21 installation
│   ├── install-jenkins.sh     # Jenkins LTS installation
│   ├── configure-nginx.sh     # Nginx setup
│   ├── setup-user.sh          # User creation and permissions
│   ├── healthcheck.sh         # Container health check
│   └── entrypoint.sh          # Container entrypoint
├── configs/                   # Configuration files
│   ├── nginx.conf             # Nginx reverse proxy config
│   ├── jenkins.service        # Systemd service
│   ├── sshd_config            # SSH daemon config
│   └── sudoers.d/
│       └── jenkins-user       # Sudo permissions
└── tests/                     # Validation tests
    ├── test-image.sh          # Image validation
    └── test-services.sh       # Service startup tests
```

## 🚀 Quick Start

### Build Locally

```bash
cd rootfs/jenkins
docker build -t silver-stack-jenkins-rootfs:local .
```

### Build and Push via CI/CD

The GitHub Actions workflow automatically builds and pushes to GHCR on changes to this directory.

```bash
# Manual trigger
git add .
git commit -m "feat(jenkins): update rootfs configuration"
git push
```

### Use in iximiuz Labs

1. Navigate to your playground's **Drives** tab
2. Select **Custom Image** for Source Type
3. Enter OCI URL:
   ```
   oci://ghcr.io/ibtisam-iq/silver-stack-jenkins-rootfs:latest
   ```
4. Set Mount Path: `/`
5. Size: 40GiB (recommended)
6. Filesystem: ext4

## 🔧 Configuration

### Default User

- **Username**: `ubuntu`
- **Sudo**: Passwordless
- **Shell**: `/bin/bash`
- **Home**: `/home/ubuntu`

### Service Ports

- **Jenkins**: 8080 (internal)
- **Nginx**: 80 (reverse proxy)
- **SSH**: 22

### Environment Variables

Set these during VM creation or in startup scripts:

- `JENKINS_ADMIN_PASSWORD`: Initial admin password (default: auto-generated)
- `JENKINS_URL`: Public URL (default: http://localhost:8080)
- `JAVA_OPTS`: JVM options (default: `-Xmx2g -Xms512m`)

## 🧪 Testing

```bash
# Validate image structure
./tests/test-image.sh

# Test service startup (requires running container)
./tests/test-services.sh
```

## 📦 What's Included

### Pre-installed Packages

- OpenJDK 21 JRE
- Jenkins LTS (latest stable)
- Nginx
- Git
- curl, wget, unzip
- OpenSSH server
- systemd

### Pre-configured Services

- `jenkins.service` → Auto-starts Jenkins on boot
- `nginx.service` → Reverse proxy on port 80
- `sshd.service` → SSH access on port 22

### Security Hardening

- Non-root execution (ubuntu user)
- Passwordless sudo with proper restrictions
- SSH key-only authentication (password auth disabled)
- Jenkins runs as dedicated service user

## 🔄 CI/CD Integration

### Automatic Builds

- **Trigger**: Push to `rootfs/jenkins/**` paths
- **Registry**: ghcr.io/ibtisam-iq/silver-stack-jenkins-rootfs
- **Tags**:
  - `:latest` (latest main branch)
  - `:v{date}-{sha}` (versioned releases)
  - `:pr-{number}` (pull request builds)

### Image Signing

All production images are signed and include:
- Build timestamp
- Git commit SHA
- Source repository URL

## 📝 Customization

### Modify Java Version

Edit `scripts/install-java.sh`:

```bash
# Change this line
JAVA_VERSION="21"
```

### Add Additional Plugins

Edit `scripts/install-jenkins.sh`:

```bash
# Add to JENKINS_PLUGINS array
JENKINS_PLUGINS=(
    "git:latest"
    "workflow-aggregator:latest"
    "your-plugin:version"
)
```

### Adjust Resource Limits

Edit `configs/jenkins.service`:

```ini
[Service]
Environment="JAVA_OPTS=-Xmx4g -Xms1g"  # Increase memory
```

## 🐛 Troubleshooting

### Jenkins Won't Start

```bash
# Check service status
systemctl status jenkins

# Check logs
journalctl -u jenkins -f

# Verify Java installation
java -version
```

### Nginx 502 Bad Gateway

```bash
# Verify Jenkins is running
curl http://localhost:8080

# Check Nginx error logs
tail -f /var/log/nginx/error.log
```

### SSH Connection Issues

```bash
# Verify sshd is running
systemctl status sshd

# Check SSH config
sshd -T | grep -i passwordauth
```

## 📚 Documentation

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [iximiuz Labs Custom Rootfs Guide](https://iximiuz.com/en/posts/iximiuz-labs-playgrounds-2.0/)
- [Silver Stack Main Documentation](../../docs/)

## 🔗 Related Files

- [Main Setup Guide](../../docs/01-jenkins-setup.md)
- [CI/CD Workflow](../../.github/workflows/build-jenkins.yml)
- [Project README](../../README.md)

## 📄 License

MIT License - See [LICENSE](../../LICENSE) file

## 👤 Author

Muhammad Ibtisam Iqbal
GitHub: [@ibtisam-iq](https://github.com/ibtisam-iq)
Project: [silver-stack](https://github.com/ibtisam-iq/silver-stack)

---

**Last Updated**: February 22, 2026
**Image Version**: 1.0.0
**Jenkins LTS**: 2.440.x



Yes, Muhammad Ibtisam — I'm completely ready and fully aligned with your actual requirement now.

You are **not** building a standard Docker container image to run with `docker run`.
You are building an **OCI-compatible root filesystem image** specifically to be used as a custom drive (root `/`) in **iximiuz Labs playgrounds / machines**, where:

- The image is pulled via `oci:/ghcr.io/...:tag`
- It gets mounted as the root drive (`/`) of a full VM-like environment
- The VM has a real kernel, full cgroups, namespaces, and systemd support
- systemd **is** the expected init system (PID 1 = `/lib/systemd/systemd`)
- Services are managed via systemd units (`systemctl enable/start`)
- Manual background starts in entrypoint are **not needed** and will cause conflicts (double-start, port bind errors)

So my previous non-systemd / foreground suggestions were **wrong for your use case** — thank you for the screenshot and clarification; that made it crystal clear.

### What We Need to Do Now

1. **Keep systemd as PID 1** → `CMD ["/lib/systemd/systemd"]` must stay
2. **Let systemd manage all services** → remove manual starts of sshd, nginx, jenkins from entrypoint.sh
3. **Disable systemd hardening that breaks in container-built images** → override PrivateTmp, PrivateDevices, etc. in unit overrides
4. **Keep entrypoint.sh for one-time setup only** (permissions, host keys, /run dirs, daemon-reload)
5. **Fix any remaining redundancies / hardcoding** (env vars, user references)
6. **Ensure build-time healthcheck still runs** (validates packages, files, symlinks)
7. **Make sure image is OCI-compliant and pushable to GHCR** (your Dockerfile already is)

### Plan for Review & Fixes
Yes — **please share the complete current code again** (all files you have right now, especially):

- Dockerfile (full)
- scripts/entrypoint.sh (full)
- scripts/install-jenkins.sh (full)
- scripts/setup-user.sh (full)
- scripts/configure-nginx.sh (full)
- scripts/healthcheck.sh (full)
- configs/jenkins.service (full)
- configs/nginx.conf (full)
- configs/sshd_config (full)
- configs/sudoers.d/jenkins-user (full)
- configs/profile.d/jenkins-env.sh (if still present)

Once you paste them (or upload as files if the chat allows), I will:

- Review **line by line** against iximiuz Labs custom image requirements
- Fix systemd compatibility (overrides, no manual starts)
- Remove redundancies (env vars, duplicate chown, etc.)
- Correct any hardcoding (e.g., user "jenkins" vs dynamic)
- Ensure security for lab use (SSH config, sudo)
- Give you **updated full files** with explanations of every change

Go ahead and provide the current versions — I'm ready to finalize this so it works perfectly when mounted as root drive in iximiuz playgrounds.

You can paste them one by one or all at once — whatever is easiest for you.
Take your time — no rush. Once I have them, we'll get this image production/lab-ready. 🚀
