# Docker Errors & Solutions

## 1. Permission Denied when Running Docker Commands
### **Error:**
```bash
Got permission denied while trying to connect to the Docker daemon socket
```
### **Why It Happens?**
- Your user doesn’t have the necessary permissions to interact with Docker.

### **Solution:**
- Add your user to the `docker` group and restart your session.
```bash
sudo usermod -aG docker $USER
newgrp docker  # Apply changes immediately
```
- If still facing issues, restart Docker:
```bash
sudo systemctl restart docker
```

---
## 2. "Pull Access Denied" when Pulling an Image
### **Error:**
```bash
docker pull myrepo/myimage
Error response from daemon: pull access denied for myrepo/myimage
```
### **Why It Happens?**
- The image is private, or the name is incorrect.

### **Solution:**
- Ensure the image name is correct.
- Authenticate to the private registry:
```bash
docker login
```
- Check the correct repository name with:
```bash
docker search myimage
```

---
## 3. "Port is Already Allocated"
### **Error:**
```bash
Error response from daemon: driver failed programming external connectivity on endpoint
```
### **Why It Happens?**
- Another process (or another container) is using the same port.

### **Solution:**
- Find running containers using the port:
```bash
docker ps | grep <port-number>
```
- Stop the conflicting container:
```bash
docker stop <container_id>
```
- Change the host port when running the container:
```bash
docker run -p 8081:80 myimage
```

---
## 4. Deleting All Running Containers
### **Issue:**
- Multiple containers are running, and you want to delete them all at once.

### **Solution:**
```bash
docker rm -f $(docker ps -aq)
```

---
## 5. Alpine Container Exits Immediately
### **Issue:**
- Running an Alpine container without a process keeps it running.

### **Solution:**
- Run it with an interactive shell:
```bash
docker run -it alpine sh
```
- Or, keep it running in the background:
```bash
docker run -d alpine tail -f /dev/null
```

---
## 6. "File Not Found" Inside the Container
### **Error:**
```bash
/xyz.txt not found
```
### **Why It Happens?**
- The file is not in the Docker build context.

### **Solution:**
- Make sure the file is inside the build directory.
- Check the file’s existence using:
```bash
docker run -it <image> sh
ls -l /xyz.txt
```

---
## 7. Cleaning Up Unused Docker Resources
### **Solution:**
```bash
docker system prune -a
```
- Removes all unused images, containers, volumes, and networks.

---
## 8. Cannot Connect to the Docker Daemon
### **Error:**
```bash
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```
### **Why It Happens?**
- Docker service is not running.

### **Solution:**
```bash
sudo systemctl start docker
```
- Check Docker status:
```bash
sudo systemctl status docker
```

---
## 9. Systemctl Stop Docker Doesn't Work
### **Issue:**
- Running `systemctl stop docker` does not stop the service.

### **Solution:**
- Stop the socket manually:
```bash
sudo systemctl stop docker.socket
```
- Then stop Docker:
```bash
sudo systemctl stop docker
```

---
## 10. "Exceeded Rate Limits" When Pulling Images
### **Error:**
```bash
Error response from daemon: toomanyrequests: You have reached your pull rate limit
```
### **Why It Happens?**
- Too many images pulled in a short time from **Docker Hub** (for anonymous users).

### **Solution:**
- Log in to Docker Hub for higher pull limits:
```bash
docker login
```
- Use a mirror or private registry.

---
## 11. "Image is Using More Space than Expected"
### **Why It Happens?**
- Unoptimized layers increase image size.

### **Solution:**
- Use **multi-stage builds**.
- Use **alpine-based images**.
- Remove unnecessary dependencies after installation.
```bash
RUN apt-get update && apt-get install -y somepackage && rm -rf /var/lib/apt/lists/*
```

---
## 12. "Mount Bind Fails with Invalid Argument"
### **Error:**
```bash
Error response from daemon: invalid mount config for type "bind"
```
### **Why It Happens?**
- Invalid mount path on Windows.

### **Solution:**
- Convert paths to **absolute paths** (on Windows):
```bash
docker run -v //c/Users:/data myimage
```

---
## 13. "Container Exits Immediately After Running"
### **Why It Happens?**
- The container runs a command and then stops because it has no long-running process.

### **Solution:**
- Run it in interactive mode:
```bash
docker run -it ubuntu bash
```
- Or, keep it running in the background:
```bash
docker run -d ubuntu tail -f /dev/null
```

---
## 14. "Docker Compose Service Fails to Start"
### **Why It Happens?**
- **Port conflicts** or **incorrect environment variables**.

### **Solution:**
- Check logs:
```bash
docker-compose logs
```
- Rebuild services:
```bash
docker-compose up --build -d
```
- Stop all containers and restart:
```bash
docker-compose down && docker-compose up -d
```

---
## 15. "Container Running But Service Not Accessible"
### **Why It Happens?**
- **Port mapping issue** or **wrong network mode**.

### **Solution:**
- Ensure the application listens on `0.0.0.0`, not `localhost`.
- Verify exposed ports in the container:
```bash
docker inspect <container_id> | grep -i "port"
```
- Restart with correct mapping:
```bash
docker run -p 8080:80 myimage
```

##
```Dockerfile
=> ERROR [2/4] RUN mvn package                                                                                                                                    11.9s
------                                                                                                                                                                   
 > [2/4] RUN mvn package:
8.462 /bin/sh: 1: mvn: not found
------

 1 warning found (use docker --debug to expand):
 - LegacyKeyValueFormat: "ENV key=value" should be used instead of legacy "ENV key value" format (line 5)
Dockerfile:7
--------------------
   5 |     ENV APP_HOME /usr/src/app
   6 |     
   7 | >>> RUN mvn package
   8 |     
   9 |     COPY target/*.jar $APP_HOME/app.jar
--------------------
ERROR: failed to solve: process "/bin/sh -c mvn package" did not complete successfully: exit code: 127
```
### **Why It Happens?**
- **Missing Maven installation** in the Dockerfile.
Docker build is failing because Maven (mvn) is not installed inside the container.

> **Note**: However, Maven is installed on your local machine, which is why it works outside the container.

### **Solution:**
- Install Maven in the Dockerfile:
```bash
RUN apt-get update && apt-get install -y maven
```
---
## Conclusion
This guide covers the most common Docker errors and their solutions, helping you troubleshoot efficiently. If you encounter additional errors, check logs using:
```bash
docker logs <container_id>
```
Happy Dockerizing! 🐳🚀

