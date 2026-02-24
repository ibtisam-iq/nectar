# Jenkins LTS Custom Rootfs for iximiuz Labs

Production-ready Jenkins LTS environment with Java 21, Nginx reverse proxy, and systemd, pre-baked into a custom rootfs image for iximiuz Labs playgrounds.

## 🎯 What's Included

- **Base**: Ubuntu 24.04 LTS (iximiuz Labs official rootfs)
- **Java**: OpenJDK 21
- **Jenkins**: LTS (latest stable version)
- **Nginx**: Reverse proxy pre-configured for Jenkins
- **User**: Non-root `user` account with sudo privileges
- **SSH**: OpenSSH server enabled and configured
- **Systemd**: Full systemd init for service management

## 📦 Quick Start

### Option 1: Use Pre-built Image (Recommended)

1. **In iximiuz Labs Playground Settings:**
   - Navigate to **Machine Settings** → **Drives** tab
   - Set **Source Type**: `Custom Image`
   - Set **Source**: `oci://ghcr.io/ibtisam-iq/silver-stack/jenkins-rootfs:latest`
   - **Mount Path**: `/`
   - **Size**: `40GiB`

2. **Start playground** and wait for initialization (~30-60 seconds)

3. **SSH into the machine:**
   ```bash
   ssh user@<node-ip>
   ```

4. **Verify Jenkins is running:**
   ```bash
   sudo systemctl status jenkins
   sudo systemctl status nginx
   ```

5. **Get initial admin password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

6. **Setup Cloudflare Tunnel** (follow main documentation)

### Option 2: Build Your Own Image

```bash
# Clone repository
git clone https://github.com/ibtisam-iq/silver-stack.git
cd silver-stack/rootfs/jenkins

# Build image
docker build -t jenkins-rootfs:custom .

# Test locally
docker run -d --name jenkins-test \
  --privileged \
  -p 8080:8080 \
  jenkins-rootfs:custom

# Test services
docker exec jenkins-test /opt/setup-scripts/test-services.sh

# Push to GHCR
docker tag jenkins-rootfs:custom ghcr.io/ibtisam-iq/silver-stack/jenkins-rootfs:custom
docker push ghcr.io/ibtisam-iq/silver-stack/jenkins-rootfs:custom
```

## 🏗️ Directory Structure

```
rootfs/jenkins/
├── Dockerfile                 # Main image definition
├── .dockerignore              # Files to exclude from build
├── scripts/                   # Installation and setup scripts
│   ├── install-java.sh        # Java 21 installation
│   ├── install-jenkins.sh     # Jenkins LTS installation
│   ├── configure-nginx.sh     # Nginx setup
│   ├── setup-user.sh          # User creation and permissions
│   ├── healthcheck.sh         # Post-install verification
│   └── entrypoint.sh          # Container initialization
├── configs/                   # Service configuration files
│   ├── nginx.conf             # Nginx reverse proxy config
│   ├── jenkins.service        # Systemd service unit
│   ├── sshd_config            # SSH daemon config
│   └── sudoers.d/
│       └── jenkins-user       # Sudo permissions
├── tests/                     # Validation tests
│   ├── test-image.sh          # Image validation tests
│   └── test-services.sh       # Service startup tests
└── README.md                  # This file
```

## 🔧 Build Arguments

Customize the image during build:

| Argument | Default | Description |
|----------|---------|-------------|
| `JENKINS_VERSION` | `lts` | Jenkins version (`lts` or `weekly`) |
| `JAVA_VERSION` | `21` | OpenJDK version (11, 17, 21) |
| `USERNAME` | `user` | Non-root user account name |
| `USER_UID` | `1000` | User ID |
| `USER_GID` | `1000` | Group ID |
| `JENKINS_HOME` | `/var/lib/jenkins` | Jenkins home directory |
| `JENKINS_PORT` | `8080` | Jenkins HTTP port |

### Build Examples

**With custom username:**
```bash
docker build \
  --build-arg USERNAME=ibtisam \
  -t jenkins-rootfs:custom \
  .
```

**With different Java version:**
```bash
docker build \
  --build-arg JAVA_VERSION=17 \
  -t jenkins-rootfs:java17 \
  .
```

**Complete customization:**
```bash
docker build \
  --build-arg JENKINS_VERSION=weekly \
  --build-arg JAVA_VERSION=21 \
  --build-arg USERNAME=cicd \
  --build-arg USER_UID=2000 \
  --build-arg USER_GID=2000 \
  -t jenkins-rootfs:custom \
  .
```

## 🧪 Testing

### Test Built Image

```bash
# Run comprehensive image tests
./tests/test-image.sh jenkins-rootfs:custom

# Test inside container
docker exec jenkins-test /opt/setup-scripts/test-services.sh
```

### Manual Testing

```bash
# Start container
docker run -d --name jenkins-test \
  --privileged \
  -p 2222:22 \
  -p 8080:8080 \
  jenkins-rootfs:custom

# SSH into container
ssh -p 2222 user@localhost

# Check services
sudo systemctl status jenkins
sudo systemctl status nginx

# View Jenkins logs
sudo journalctl -u jenkins -f

# Get admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins
open http://localhost:8080
```

## 🚀 GitHub Actions CI/CD

Automated builds on push to `main`:

```yaml
# .github/workflows/build-jenkins-rootfs.yml
name: Build Jenkins Rootfs

on:
  push:
    branches: [main]
    paths: ['rootfs/jenkins/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: ./rootfs/jenkins
          push: true
          tags: ghcr.io/${{ github.repository }}/jenkins-rootfs:latest
```

## 📝 Pre-installed Components

### System Packages
- curl, wget, git, vim, nano
- gnupg, ca-certificates
- sudo, systemd
- nginx, openssh-server
- net-tools, htop, tree

### Java Environment
- OpenJDK 21 JDK + JRE
- JAVA_HOME configured
- Java alternatives set

### Jenkins
- Jenkins LTS
- systemd service configured
- Jenkins home: `/var/lib/jenkins`
- Initial plugins ready to install

### Nginx
- Reverse proxy configured
- WebSocket support enabled
- Large file upload support (100MB)
- SSL-ready configuration

### SSH Server
- OpenSSH server enabled
- Root and password auth enabled
- Port 22 exposed

### User Account
- Username: `user` (customizable)
- Home: `/home/user`
- Sudo: NOPASSWD enabled
- Bashrc with Jenkins aliases

## 🔍 Troubleshooting

### Image build fails

**Java installation error:**
```bash
# Check Java version is valid (11, 17, 21)
docker build --build-arg JAVA_VERSION=21 .
```

**Jenkins installation error:**
```bash
# Check version is valid (lts or weekly)
docker build --build-arg JENKINS_VERSION=lts .
```

### Container won't start

**Systemd requires privileged mode:**
```bash
docker run -d --privileged <image>
```

### Services not starting

**Check service logs:**
```bash
docker exec <container> journalctl -u jenkins -n 50
docker exec <container> journalctl -u nginx -n 50
```

**Restart services:**
```bash
docker exec <container> systemctl restart jenkins
docker exec <container> systemctl restart nginx
```

### Jenkins not accessible

**Check port binding:**
```bash
docker ps  # Verify port 8080 is mapped
```

**Check Jenkins is running:**
```bash
docker exec <container> systemctl status jenkins
docker exec <container> ss -tlnp | grep 8080
```

### Permission issues

**Fix Jenkins home ownership:**
```bash
docker exec <container> chown -R jenkins:jenkins /var/lib/jenkins
```

**Fix user home ownership:**
```bash
docker exec <container> chown -R user:user /home/user
```

## 📚 Related Documentation

- **Main Setup Guide**: [01-jenkins-setup.md](../../docs/01-jenkins-setup.md)
- **Custom Rootfs Guide**: [04-custom-rootfs-guide.md](../../docs/04-custom-rootfs-guide.md)
- **iximiuz Labs Docs**: https://iximiuz.com/en/posts/iximiuz-labs-playgrounds-2.0/
- **Jenkins Documentation**: https://www.jenkins.io/doc/

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and test thoroughly
4. Run tests: `./tests/test-image.sh`
5. Commit changes: `git commit -m 'Add feature'`
6. Push to branch: `git push origin feature/my-feature`
7. Open Pull Request

## 📄 License

MIT License - See repository root for details.

## ✍️ Author

**Muhammad Ibtisam Iqbal**
- GitHub: [@ibtisam-iq](https://github.com/ibtisam-iq)
- Project: [Silver Stack](https://github.com/ibtisam-iq/silver-stack)
- Documentation: https://nectar.ibtisam-iq.com

## 🙏 Acknowledgments

- iximiuz Labs for custom rootfs support
- Jenkins community for excellent documentation
- Cloudflare for Tunnel technology
