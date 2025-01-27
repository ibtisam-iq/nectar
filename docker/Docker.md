# Docker: A Structured Guide

## **What is Docker**
Docker is an open-source platform that allows developers to package, deploy, and run applications in **lightweight, portable containers**. These containers ensure consistent behavior across various environments, eliminating compatibility issues.

---

## **Key Features and Benefits**
- **Lightweight**: Containers share the host OS kernel, avoiding the overhead of a full operating system per application.
- **Portable**: Run containers consistently across any environment that supports Docker.
- **Efficient**: Containers start and stop quickly, improving development and deployment speed.
- **Isolated**: Each container operates independently, preventing conflicts between applications.
- **Secure**: Applications run in isolated, secure environments.
- **Scalable**: Containers can scale easily to meet demand.
- **Ease of Use**: Simple tools and automation simplify container management.
- **Cross-Platform**: Compatible with Linux, macOS, and Windows.
- **Community Support**: A large ecosystem provides tools and resources for developers.

---

## **Problems Docker Solves**

### **1. Dependency and Configuration Management**

#### **What are Dependencies and Configuration?**
- **Dependencies**: External libraries, frameworks, runtime environments, or packages required for an application to run. For example:
  - Python applications need specific Python versions and libraries like `Django` or `Flask`.
  - Java applications may require `JDK` or specific `.jar` files.
- **Configuration**: Environment-specific settings, such as:
  - Database connection strings.
  - API keys and credentials.
  - Server-specific configurations (e.g., ports, memory limits).

#### **How Were Dependencies and Configuration Managed Earlier?**
- **Manual Installation**: Developers manually installed dependencies on each system, often leading to version mismatches.
- **Environment Variations**: Applications behaved differently across environments due to inconsistencies in configurations and dependencies.
- **Complex Deployment**: Teams had to maintain detailed documentation or scripts to replicate the required environment, which was time-consuming and error-prone.

#### **How Docker Solves This Problem**
- Docker packages the application, its dependencies, and configurations into **Docker images**:
  - Ensures all dependencies are included, avoiding version conflicts.
  - Allows environment-specific configurations to be managed using **environment variables** or **configuration files**.
- Docker containers provide a consistent runtime environment, eliminating "it works on my machine" issues.
- Developers can focus on coding without worrying about infrastructure setup.

---

### **2. Portability**
**Before Docker**: Applications faced compatibility issues due to differences in operating systems, dependencies, and configurations.  
**With Docker**: 
- Applications and dependencies are packaged into **Docker images**, ensuring consistent behavior across environments.
- Containers eliminate the need to manage infrastructure dependencies manually.

---

### **3. Complexity**
**Before Docker**: Running applications with diverse dependencies required complex configurations.  
**With Docker**: Docker simplifies the process by bundling application code, dependencies, and configurations into a single container.

---

### **4. Inefficiency**
**Before Docker**: Traditional methods consumed excessive resources due to redundant OS instances and slow startup times.  
**With Docker**: 
- Containers share the host OS kernel, drastically reducing resource usage.
- They start almost instantly, enabling faster workflows and scaling.

---

### **5. Security**
**Before Docker**: Shared environments posed risks of application conflicts and vulnerabilities.  
**With Docker**: Containers isolate applications, minimizing risks and ensuring secure execution.

---

## **Docker vs. Virtual Machines**

### **Virtual Machines**
- Each VM includes a full OS, leading to:
  - High resource usage (CPU, memory, disk space).
  - Slow startup times due to OS booting.
  - Inefficient resource sharing and management.

### **Docker Containers**
- Containers share the host OS kernel, offering:
  - **Resource Efficiency**: No need for a full OS per container, enabling more containers on the same hardware.
  - **Fast Startup**: Containers start in seconds, ideal for scaling.
  - **Portability**: Containers run consistently across environments without dependency issues.
  - **Cost-Effectiveness**: Reduced resource usage lowers infrastructure costs.

---

## **How Docker Revolutionizes Deployment**
1. **Unified Workflow**: Containers simplify transitions between development, testing, and production environments.
2. **Rapid Scaling**: Instant container startup enables responsive scaling during peak demands.
3. **Streamlined Management**: Tools like Docker Compose and Docker Swarm simplify multi-container application management.

---

## Docker Architecture
Docker uses a layered architecture to manage containers. The key components include:
- **Docker Engine**: The core component responsible for creating, managing, and running containers. It includes the Docker daemon and the Docker client.
- **Docker Hub**: A cloud-based registry where users can store and share Docker images.
- **Docker Objects**: These are the building blocks of Docker, including images, containers, volumes, networks, and more.
- For details, please click [here](architecture.md).

---

## Docker Plugins
- Docker Plugins are **extensions** or **add-ons** that enhance Docker's functionality. 
- These tools integrate with the Docker Engine to provide additional capabilities, simplifying workflows and extending Docker's usability.
- Please click [here](plugins.md) for more information.

---

## Dockerfile
- It is a text file that contains all the commands a user could call on the command line to assemble an image.
- For details, please click [here](./Dockerfile).
- Official [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)

---

## Install Docker Engine

- [Official Documentation](https://docs.docker.com/engine/install/)

### 1. Uninstall Old Versions
To ensure a clean installation, remove any conflicting packages by running the following command:

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
  sudo apt-get remove -y $pkg
done
```

---

### 2. Installation
Docker Engine can be installed using different methods depending on your requirements.

#### **1. Docker Desktop**
- Docker Engine comes bundled with **Docker Desktop** for Linux, offering the easiest setup.
- [Installation Guide](https://docs.docker.com/desktop/setup/install/linux/)
- Key command to manage Docker Desktop:
  ```bash
  systemctl --user start|stop|enable|disable docker-desktop
  ```

#### **2. Using `apt` Repository**
Install Docker Engine directly from Docker's official `apt` repository:

1. **Add Docker's GPG Key and Repository**

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
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

### 3. Post-Installation Steps
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

### 4. Deploy Portainer
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
---

## Docker CLI Overview

- container
- image
- volume
- network
- system: df, events, info, prune
- authentication: login, logout
- plugins: plugin, context, search
- version
- stats
- manifest

---

## Docker Essenial Commands

```bash
# Lists all available images on the system.
docker images

# Alias for docker images.
docker image ls

# Filters images with the name 'node'.
docker image ls node

# Lists dangling images (unused image layers).
docker images -f "dangling=true"

# Lists running containers.
docker ps

# Lists all container IDs (running and stopped).
docker ps -a -q

# Displays details of both running containers and images.
docker ps/images/container

# Removes a specific container using its ID.
docker rm CONTAINERID

# Removes all stopped containers.
docker rm $(docker ps -a -q)

# Another way to remove all stopped containers.
docker ps -aq | xargs docker rm

# Removes a specific volume by its ID.
docker volume rm VOLID

# Removes a specific image forcibly, either by ID or name.
docker rmi IMAGEID/REPOSITORY:v --force

# Cleans up unused images, containers, networks, and volumes to free up disk space.
docker system prune
```

---

## Docker Commands: Pull, Push, and Tag

```bash
# Pull a specific image from Docker Hub (e.g., hello-world)
docker image pull hello-world

# Pull all tags of a specific image (e.g., image_name)
# Useful when you want to download all variants of an image
docker pull --all-tags image_name

# Tag an image from an old repository to a new one (e.g., OLDREPOSITORY:v to mibtisam/NEWREPOSITORY:v)
docker tag OLDREPOSITORY:v mibtisam/NEWREPOSITORY:v

# Tag an image by its Image ID (e.g., IMAGE_ID to my-app:1.0)
docker tag IMAGE_ID my-app:1.0

# Push an image to a Docker repository (e.g., mibtisam/NEWREPOSITORY:v)
docker push mibtisam/NEWREPOSITORY:v
```
- The **image name** is distinct from the **repository name**, with the repository serving as the storage location for images.
- Please follow the complete guide [here](repository.md).

---



























# docker pull, push, tag

docker image pull hello-world	docker pull --all-tags  image_name
docker tag OLDREPOSITORY:v mibtisam/NEWREPOSITORY:v		docker tag IMAGE_ID my-app:1.0
docker push NEWREPOSITORY:v

# docker build

docker build -t IMAGENAME:version /path		t=tag			
docker build -t img1:sam  /home/osboxes/ibtisam/docker/files		ERROR	    {Dockerfile1}
docker build -t img1:sam  .								            ERROR	    {Dockerfile1}
docker build -t img1:sam  /home/osboxes/ibtisam/docker/files		EXECUTED	{Dockerfile}
docker build -t img1:sam  .								            EXECUTED	{Dockerfile}
docker build -t img:sam -f ../../../Dockerfile1 /home/osboxes/ibtisam/docker/files
					{dockerfile path}		{folder path = docker context}
docker build -t img:sam -f ../../../Dockerfile2 /home/osboxes/ibtisam/docker/files

# docker commit

docker commit -a "Ibtisam" -m "Nginx container with custom CMD, ENV, and exposed port" \
    -c 'CMD ["nginx", "-g", "daemon off;"]' \
    -c 'ENTRYPOINT ["nginx", "-g", "daemon off;"]' \
    -c 'ENV APP_ENV=production PORT=8080' \
    -c 'WORKDIR /usr/src/app' -c 'EXPOSE 8080' \
    -c 'USER nginx' \
    -c 'LABEL version="1.0" description="Custom Nginx image"' \
    -c 'VOLUME ["/data"]' <container_id/name> <image>

# docker run

docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
docker container run = docker container create + docker container start + docker container attach
CMD can be overridden; but ENTRYPOINT can’t. # Lec-20
docker run --name <> --entrypoint sleep -d alpine infinity		entrypoint=sleep, arg=infinity
docker run --name <> --entrypoint <> nginx 10	# Dr_f: ENTRYPOINT [“sleep”] CMD [“5”], will override both ENTRYPOINT & CMD mentioned in Dr_f
# docker run --name abc --entrypoint echo nginx ibtisam
docker container run --rm -d --name <> REPOSITORY:v	
docker run -dit --name myfirstcon REPOSITORY:v /bin/sh	[COMMAND] (/bin/sh) 
docker run -dit --name myfirstcon REPOSITORY:v uname -a	[COMMAND] (uname) [ARG...] (-a)
docker run -dit --name myfirstcon alpine sleep 10		[COMMAND] (sleep) [ARG...] (10)
docker run --name <> alpine sh -c "echo hello" 		    [COMMAND] (sh) [ARG...] (-c "echo hello")
docker run alpine ls -l {by default prints the output of /root}	ls -l /usr {list /usr}
docker run --cap-add MAC_ADMIN ubuntu sleep 3600		docker run --cap-drop KILL ubuntu
docker run --user=<> ubuntu sleep 3600							user=1000
docker run -it -d --name <> -e PORT=$MY_PORT -p 7600:$MY_PORT --mount type=bind,src=$PWD/src,dst=/app/src node:$MY_ENV

# port mapping

docker run -it --name {} -p 8080:80 nginx /bin/sh	host/client:server/container
docker run -it --name web1 -p 80:80 nginx 		    YES
docker run -it --name web2 -p 80:80 nginx 		    NO mapped, but container generated. 
docker run -it --name web2 -p 8080:80 nginx 		NO mapped,because container ID exists.
docker run -it --name web3 -p 8080:80 nginx 		NOT mapped, port is already allocated.
docker run -it --name web4 -p 8081:80 nginx 		YES
docker run --rm -it --name nginx1 -d -p 127.0.0.1:80:8081/tcp nginx 80 on local to 8081 inside cont

# docker volume

docker volume create/inspect/ls/prune/rm <>	
docker volume, docker bind (bind mount), tmpfs
/var/lib/docker/image/overlay2/imagedb/metadata/sha256 (build)
/var/lib/docker/image/overlay2/imagedb/content/sha256 (All)
docker run -it --name cont1 -v /Vo1 alpine /bin/sh
Yes, all commands are essentially the same. They all create a new container named cont1 from the alpine image,
start a shell in the container, and mount a volume named my-vol at the path /Vol in the container.
docker create volume my-vol
docker run -it --name cont1 --mount type=volume,source=my-volume,target=/Vol alpine /bin/sh
docker run -it --name cont1 --mount source=my-vol,target=/Vol alpine /bin/sh 	"Type": "volume"
docker run -it -d --name con1 --mount src=my-vol,dst=/Vol alpine				"Type": "volume"
docker run -it --name cont1 -v my-volume:/Vol alpine /bin/sh				    "Type": "volume"
docker run -it --name cont2 -v /HOST/PATH:/CONTAINER/PATH alpine /bin/sh		"Type": "bind"
ibtisam@mint-dell:~/dockr$ mkdir bind			/home/ibtisam/dockr/bind
docker run -it --name cont2 --mount type=bind,source=/../../,destination=/opt/data alpine /bin/sh
docker run -it --name cont-v3 -v /home/ibtisam/ct/doc-ker/docker-bind:/opt/data busybox /bin/sh & docker run -it --name cont-v4 -v /home/ibtisam/ct/doc-ker/docker-bind:/opt/data busybox /bin/sh; more than one container (with same everything) can be mounted on the same destination, all containers will share the same ONE path. Unlike docker bind, in docker volumes, all the containers have a unique volume ID, so containers can’t share the data.
docker run -d -it --name cont3 --mount type=tmpfs,destination=/app alpine /bin/sh
docker run -d -it --name cont3 --tmpfs /app alpine /bin/sh
docker create -v /dbdata --name lec-18 postgres:13-alpine /bin/true cont (lec-18) created, but exited.
docker run -d -it --name db1 --volumes-from lec-18 postgres:13-alpine /bin/sh
docker run -d -it --name db2 --volumes-from lec-18 postgres:13-alpine /bin/sh
docker run -it --name container2 --privileged=true --volume-from container1 ubuntu bin/bash
-v /home/ec2-user(host):/rajput(container) --privileged=true (container to host volume mounting)

# docker network

docker connect/create/disconnect/inspect/ls/prune/rm <>

# Monitoring & Debugging

docker exec -it CONTAINERID /bin/sh
docker start/stop/kill/pause/unpause CONTAINERID
docker start --attach CONTAINERID  (it also prints the message; docker run hello)
docker start (docker ps) docker diff <container>
docker container logs/inspect/port CONTAINERID/NAME 	
docker logs -f CONTAINERID
docker inspect <> | python3 -c "import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)" > abc.yaml
docker search <image name to be searched from hub>

# docker compose

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04 
https://docs.docker.com/compose/ 		https://github.com/docker/compose

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; sudo chmod +x /usr/local/bin/docker-compose 
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose; docker-compose --version
# if ln -s isn’t created;	/usr/local/bin/docker-compose --version
https://docs.docker.com/reference/compose-file/legacy-versions/ 
up -d; ps -a; down;
```
**Key Points**

- docker run, always use -it, if you later want to enter (docker exec) into the container, otherwise docker start doesn't start it to exec. /bin/sh (better to add)
- To be in ps, -it isn’t mandatory; docker start exec
- Kill/stop the container. Remove/Delete the container. Remove/Delete the image.
- Once you exit the running container, you need to start it again before running exec.
- docker start/exec {containerID}, unlike the run command, container stops only if stopped.
- docker run `exit` exited; but docker start/exec `exit` NOT EXited, until you stop it.
- docker run/build `NO ContainerID`, exec/start/stop/kill/commit/inspect/logs `ContainerID`
- docker run doesn’t require a path, but docker build requires a path.
- docker start {containerID}, it just starts the container, but can’t print the output.
- To print the message, docker start --attach {containerID}
- To run the same container, start --attach directly instead of exec
- docker commit, whether you make changes in container or not, each commit command generates a new image ID.
- docker build, image layers are read-only. Image layers = no of lines in Dockerfile 
- While building, if any error occurs at any layer, it will not proceed next, but create the image with `none` tag and finish it.
- docker build . dangling image; NO image Name & TAG,but contains Image ID. 
- docker images alpine; docker build with RUN alpine; docker images, NO alpine 
- ImageName, always be in lower case.
- ls -l, just print the output after exiting. docker run alpine ls -l
- dagling image = `repo & tag = none`, but imageID allocated
- /var/run/docker.sock this file connects docker client with server/daemon. If the server is off, pa -a doesn’t show any result.
- -- rm, name, attach, version, help, all
- docker run -it & -dit, /bin/sh is not mandatory. -it leads to /boot by default.
- docker exec -it & -dit, /path isn’t mandatory.	docker exec {container ID} ls
- docker exec, -it is mandatory along with /path, if you enter into the container.
- build, /Dockerfile path is mandatory.
- run `<ls -l> <bin/sh> <bin/ash> <echo “this is ibtisam”>`
- To go into the container, add -it. Or add --attach while starting the container for print.
- Image ID NOT changed, `<deletion> <tagging> <pushing>`
- Image ID CHANGED, `<changes in Dockerfile> <commit, even you made no changes in container>`
- Image ID Created, `<build>, <pull>, <commit>`
- --name cont1 -v /VOL alpine		--name cont2 -v /VOL alpine; possible
- /VOL (the same destination) can be used to mount for n volumes
- containers -v (n) = volumes (n) , same destination no problem, but containers can’t share the data due to the unique volume ID assigned to each one.
- In docker volume, different container IDs, different Volume Ids, data not shared
- In docker bind, different container IDs, no Volume ID, data shared
- docker run -d --rm -p 8080:8080 --name webserver busybox sh -c "while true; do { echo -e 'HTTP/1.1 200 OK\r\n';echo 'smallest http server'; } | nc -l -p 8080; done"
- docker ps -a	 or docker port CONTAINERID	
- netstat -tuln | grep 8080	OR	ss -tuln | grep 8080
- curl http://localhost:8080 or http://192.168.100.107:8080/
- docker run -dit -p 8080:80 --name myser nginx		YES
- docker run -dit -p 8080:80 --name myser1 nginx		NO, port allocated




<div style="text-align: justify;">
ARG PORT=8000
ENV PORT=$PORT

- ARG PORT=8000: This sets PORT to 8000 during the build process (build-time). You can override this value when you build the Docker image using docker build --build-arg PORT=5000 . to change the port number just during the build.

- ENV PORT=$(PORT): After the build is done, this line ensures that the port you specified at build-time gets passed into the container as an environment variable.

  - application is listening on 8000, and docker also exposes 8000. Right? so, I'll map it to my localhost at 8000 to work properly? from what I understand, ENV & Expose must be the same in the docker file, and should you open the same port on your localhost?

**ChatGPT said:**
Yes, you're understanding it correctly. Here's the breakdown:

Application inside the container:
The application is configured to listen on port 8000 because of the ENV PORT=8000 in the Dockerfile.

Docker exposing the port:
Docker is set to expose port 8000 to allow access to the application from outside the container (using EXPOSE 8000).

Mapping to localhost:
When running the container, you'll need to map the container's port 8000 to a port on your localhost (host machine). 

The most straightforward way is to map it to the same port on your localhost by running:
docker run -p 8000:8000 your-image This command maps port 8000 inside the container to port 8000 on your localhost. Now, when you visit http://localhost:8000, it will route to the application running inside the Docker container.

Key Points:

ENV and EXPOSE values should generally be the same to keep everything aligned, meaning both are set to 8000 in this case.

When you map the container port to your localhost, you can use the same 8000 port on the host machine for simplicity, but you can also map to a different port if needed (e.g., -p 9000:8000 would map the container's port 8000 to port 9000 on the host).

So yes, for everything to work as expected:

The application listens on port 8000.

Docker exposes port 8000.

You map port 8000 to your localhost:8000.

In this way, accessing http://localhost:8000 on your machine will successfully reach your application.

   - so, is it mandatory to mention both ENV & AGR? what if i mentioned AGR, but don't mention ENV? or what if I mention ENV, and don't mention AGR?

**ChatGPT said:**

It’s not mandatory to mention both ARG and ENV together in a Dockerfile. They have distinct purposes and behave differently:

If you mention only ARG (without ENV):

ARG is only available during build-time (when the Docker image is being created), so if you use ARG PORT=8000, this value will only be used during the build process. Once the container is running, ARG values are no longer available. This means the application inside the container won't be able to access PORT unless you explicitly set it with ENV as well.

Result: The application in index.js won’t know about PORT at runtime because ARG is only for build-time, so it will fall back to the default in your code (4000 in this case).

If you mention only ENV (without ARG):

ENV sets environment variables for runtime (when the container is running). So if you only use ENV PORT=8000, your application will pick up this value from process.env.PORT at runtime. This means your application will listen on port 8000 without needing ARG.

Result: Your application will correctly use port 8000 because ENV passes the value to process.env.PORT at runtime.

If you mention both ARG and ENV:
ARG is used during the build to pass values that can later be set as environment variables via ENV. For example:

ARG PORT=8000
ENV PORT=$PORT

Here, ARG PORT=8000 sets a default value at build-time, and then ENV PORT=$PORT makes it available at runtime by passing the value from the ARG to ENV.

This setup allows flexibility where the build process can accept different ARG values but still make them available as ENV for the container.

Result: This ensures that both build-time and runtime configurations align. You could also override the ARG at build-time like this:

docker build --build-arg PORT=9000 -t myapp .

In Summary:

Only ARG: Used at build-time. The application won’t see it unless you pass it to ENV.
Only ENV: This is what you need for the application to get the value at runtime.
Both ARG and ENV: Flexible and allows you to pass different values during the build, which are then available at runtime.
For your case with the Node.js application, you can skip ARG if you don’t need to pass a different port at build-time and only use ENV for runtime configuration.
</div>

## **Conclusion**
Docker provides a lightweight, efficient, and secure alternative to traditional virtual machines. By addressing critical issues like dependency management, configuration consistency, portability, complexity, inefficiency, and security, Docker has become an essential tool for modern software development and deployment. Its ability to maximize resource utilization and scalability makes it indispensable for organizations aiming for agility and cost-efficiency.
