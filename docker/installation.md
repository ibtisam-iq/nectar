## Install Docker Engine

- [Official Documentation](https://docs.docker.com/engine/install/)

## 1. Uninstall Old Versions
To ensure a clean installation, remove any conflicting packages by running the following command:

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
  sudo apt-get remove -y $pkg
done
```

---

## 2. Installation
Docker Engine can be installed using different methods depending on your requirements.

### **1. Docker Desktop**
- Docker Engine comes bundled with **Docker Desktop** for Linux, offering the easiest setup.
- [Installation Guide](https://docs.docker.com/desktop/setup/install/linux/)
- Key command to manage Docker Desktop:
  ```bash
  systemctl --user start|stop|enable|disable docker-desktop
  ```

### **2. Using `apt` Repository**
Install Docker Engine directly from Docker's official `apt` repository:

1. **Add Docker's GPG Key and Repository**

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

> **Note**: For Ubuntu derivative distributions (e.g., Linux Mint), replace `VERSION_CODENAME` with `UBUNTU_CODENAME`.

2. **Install Docker Engine**

```bash
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

---

## 3. Post-Installation Steps
To enable non-root users to run Docker and perform other configurations, follow these steps:

- [Post-Installation Guide](https://docs.docker.com/engine/install/linux-postinstall/)

1. **Add Your User to the Docker Group**

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

2. **Apply Changes**
Log out and back in, or activate the changes immediately:

```bash
newgrp docker
```

3. **Verify Group Membership**

```bash
groups $USER
```

4. **Manage Docker Service**

```bash
# Start, stop, or check the status of Docker
sudo systemctl start|stop|status docker

# Alternatively, use the following:
sudo service docker start|stop|status

# Start the Docker socket
sudo systemctl start docker.socket

# List Docker-related services
sudo systemctl list-units --type=service | grep docker
```

---

## 4. Deploy Portainer
Portainer is a lightweight management UI for Docker:

```bash
# Pull the Portainer image
docker pull portainer/portainer-ce

# Create a volume for Portainer
docker volume create portainer_data

# Run Portainer

docker run -d -p 8000:8000 -p 9443:9443 --name=portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce

# Access Portainer at: https://localhost:9443
```
