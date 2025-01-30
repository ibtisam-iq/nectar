# Docker: A Structured Guide

## What is Docker
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

## Problems Docker Solves

### 1. Dependency and Configuration Management

#### What are Dependencies and Configuration?

- **Dependencies**: External libraries, frameworks, runtime environments, or packages required for an application to run. For example:
  - Python applications need specific Python versions and libraries like `Django` or `Flask`.
  - Java applications may require `JDK` or specific `.jar` files.

- **Configuration**: Environment-specific settings, such as:
  - Database connection strings.
  - API keys and credentials.
  - Server-specific configurations (e.g., ports, memory limits).

#### How Were Dependencies and Configuration Managed Earlier?

- **Manual Installation**: Developers manually installed dependencies on each system, often leading to version mismatches.

- **Environment Variations**: Applications behaved differently across environments due to inconsistencies in configurations and dependencies.

- **Complex Deployment**: Teams had to maintain detailed documentation or scripts to replicate the required environment, which was time-consuming and error-prone.

#### How Docker Solves This Problem

- Docker packages the application, its dependencies, and configurations into **Docker images**:
  - Ensures all dependencies are included, avoiding version conflicts.
  - Allows environment-specific configurations to be managed using **environment variables** or **configuration files**.
- Docker containers provide a consistent runtime environment, eliminating "it works on my machine" issues.
- Developers can focus on coding without worrying about infrastructure setup.

---

### 2. Portability

**Before Docker**: Applications faced compatibility issues due to differences in operating systems, dependencies, and configurations.

**With Docker**: 
- Applications and dependencies are packaged into **Docker images**, ensuring consistent behavior across environments.
- Containers eliminate the need to manage infrastructure dependencies manually.

---

### 3. Complexity

**Before Docker**: Running applications with diverse dependencies required complex configurations.

**With Docker**: Docker simplifies the process by bundling application code, dependencies, and configurations into a single container.

---

### 4. Inefficiency

**Before Docker**: Traditional methods consumed excessive resources due to redundant OS instances and slow startup times.

**With Docker**: 
- Containers share the host OS kernel, drastically reducing resource usage.
- They start almost instantly, enabling faster workflows and scaling.

---

### 5. Security

**Before Docker**: Shared environments posed risks of application conflicts and vulnerabilities.

**With Docker**: Containers isolate applications, minimizing risks and ensuring secure execution.

---

## Docker vs. Virtual Machines

### Virtual Machines

- Each VM includes a full OS, leading to:
  - High resource usage (CPU, memory, disk space).
  - Slow startup times due to OS booting.
  - Inefficient resource sharing and management.

### Docker Containers

- Containers share the host OS kernel, offering:
  - **Resource Efficiency**: No need for a full OS per container, enabling more containers on the same hardware.
  - **Fast Startup**: Containers start in seconds, ideal for scaling.
  - **Portability**: Containers run consistently across environments without dependency issues.
  - **Cost-Effectiveness**: Reduced resource usage lowers infrastructure costs.

---

## How Docker Revolutionizes Deployment

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

- Have a look on its Descritives in depth:
  - [ARG, ENV, EXPOSE](ARG-ENV-EXPOSE.md)
  - [ENTRYPOINT, CMD](ENTRYPOINT-CMD.md)

- Official [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)

---

## Install Docker Engine

- Docker Engine can be installed using different methods depending on your requirements. Please follow [these steps](installation.md) to install it.
- [Official Documentation](https://docs.docker.com/engine/install/)

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

Please click [here](docker%20--help.md) to learn these commands and their flags in depth.

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
- Please follow the complete guide [Docker Repositories, Registries, and Image Names: The Big Picture](repository.md).

---

## docker build

The `docker build` command is used to create Docker images from a `Dockerfile` and its associated context. The **context** refers to the directory sent to the Docker daemon containing the `Dockerfile` and any files required during the build process. The behavior of the `docker build` command depends on the correct setup of the context and the path to the `Dockerfile`.

- For details, please click [docker build](build.md) and [docker tag](tag.md)

```bash
docker build -t IMAGENAME:version /path/to/docker/context

docker build -t img1:sam  /files	  # ERROR	   Dockerfile1

docker build -t img1:sam  .		      # ERROR	   Dockerfile1

docker build -t img1:sam  /files	  # EXECUTED  Dockerfile

docker build -t img1:sam  .		      # EXECUTED  Dockerfile

docker build -t img:sam -f ../../../Dockerfile1 /files    # EXECUTED

docker build -t img:sam -f ../../../Dockerfile2 /files    # EXECUTED
```
---

# docker commit

```bash
# Commit the container to a new image

docker commit \
    -a "Ibtisam" \
    -m "Nginx container with custom CMD, ENV, and exposed port" \
    -c 'ENTRYPOINT ["nginx", "-g", "daemon off;"]' \ 
    -c 'CMD ["nginx", "-g", "daemon off;"]' \
    -c 'ENV APP_ENV=production PORT=8080' \
    -c 'WORKDIR /usr/src/app' \
    -c 'EXPOSE 8080' \
    -c 'USER nginx' \
    -c 'LABEL version="1.0" description="Custom Nginx image"' \
    -c 'VOLUME ["/data"]' \
    <container_id/name> <image>
```
---

## docker run

The `docker run` command is used to create and start a container from a specified image. It is often the first step to interact with a containerized application.

#### Basic Syntax:
`docker run [OPTIONS] IMAGE [COMMAND] [ARG...]`

- OPTIONS: Various flags to modify container behavior (e.g., `-d`, `--name`, `--entrypoint`).
- IMAGE: The image to use for creating the container.
- COMMAND: (Optional) The command to run inside the container.
- ARG: (Optional) Arguments for the specified command.

> `docker container run` is equivalent to: `docker container create + docker container start + docker container attach`

#### ENTRYPOINT and CMD

- Here's how it works:
  - **ENTRYPOINT** defines the `executable` to run.
  - **CMD** provides the default `arguments` to the ENTRYPOINT.

- `CMD` can be overridden when running the container.
- `ENTRYPOINT` cannot be overridden without using the `--entrypoint` flag.
- If you use the `ENTRYPOINT` flag, **it doesn't automatically replace the** `CMD` unless you specify a new command after the image name. If no command is specified after overriding `ENTRYPOINT`, Docker will use the default `CMD` from the Dockerfile.

- For example:
  - If you override `ENTRYPOINT` to `sleep`, but you don't provide any argument, Docker will use the `CMD` argument from the Dockerfile (if defined).
  - If you want to override both, you would need to specify both `ENTRYPOINT` and `CMD` explicitly.

1. **Override ENTRYPOINT and CMD**
   
   `docker run --name <container_name> --entrypoint sleep -d alpine infinity`
   - This command sets the entrypoint to `sleep` and the argument to `infinity`. This effectively overrides both the `ENTRYPOINT` and `CMD` behavior. The `infinity` argument overrides whatever `CMD` was originally defined in the Dockerfile (if any).
   
   `docker run --name <container_name> --entrypoint <entrypoint_command> nginx 10`
   - This overrides both the `ENTRYPOINT` and `CMD` defined in the Dockerfile. For example, if the Dockerfile defined:
     - `ENTRYPOINT` ["sleep"]
     - `CMD` ["5"]
     - Both `ENTRYPOINT` and `CMD` are overridden here.

- Both points clarify that when an argument is provided for `ENTRYPOINT` (like `infinity` or `10`), it overrides the `CMD` as well.

2. **Run and remove the container automatically on exit**
   
   `docker container run --rm -d --name <container_name> REPOSITORY:v`
   - Runs the container in detached mode and removes it automatically after it stops.

3. **Run with a shell command**
   
   `docker run -dit --name myfirstcon REPOSITORY:v /bin/sh`
   - Runs the container with the command `/bin/sh`, allowing interaction with the shell.

4. **Run with a shell command to echo a message**
   
   `docker run --name <container_name> alpine sh -c "echo hello"`
   - Runs the container with the `sh` command and the argument `-c "echo hello"`, which prints "hello" to the console.

5. **Run with default command**
   
   `docker run alpine ls -l`
   - Runs the container with the `ls -l` command. By default, it lists the contents of the `/root` directory.

6. **Run with a custom command and arguments**
   
   `docker run -dit --name myfirstcon REPOSITORY:v uname -a`
   - Runs the container with the command `uname` and the argument `-a` to display system information.

7. **Run with the sleep command**
   
   `docker run -dit --name myfirstcon alpine sleep 10`
   - Runs the container with the `sleep` command and the argument `10`, making the container sleep for 10 seconds before stopping.

8. **Run with custom capabilities**
   
   `docker run --cap-add MAC_ADMIN ubuntu sleep 3600`
   - Adds the `MAC_ADMIN` capability to the container and runs it for 3600 seconds (1 hour).
   
   `docker run --cap-drop KILL ubuntu`
   - Drops the `KILL` capability from the container, restricting its ability to kill other processes.

9. **Run with specific user**
   
   `docker run --user=1000 ubuntu sleep 3600`
   - Runs the container as the `user` with UID 1000.

10. **Run with environment variable and bind mount**
   
   `docker run -it -d --name <container_name> -e PORT=$MY_PORT -p 7600:$MY_PORT --mount type=bind,src=$PWD/src,dst=/app/src node:$MY_ENV`
   - Runs the container interactively with environment variables, a port binding, and a bind mount.

---


## Port Mapping

1. **Run with port mapping (host:container)**
   
   `docker run -it --name {} -p 8080:80 nginx /bin/sh`  
   - This command maps port `8080` on the host to port `80` inside the container. It allows you to access the container's `nginx` service on `http://<host-ip>:8080`.  
   - The placeholder `{}` should be replaced with a container name (e.g., `web1`).

2. **Run with port 80 mapped successfully**
   
   `docker run -it --name web1 -p 80:80 nginx`  
   - Here, port `80` on the host is mapped to port `80` inside the container, meaning the `nginx` service is accessible from `http://<host-ip>:80`.

3. **Run with port 80 already mapped (same as host and container)**  
   
   `docker run -it --name web2 -p 80:80 nginx`  
   - This won't work because port `80` is already in use on the host by another container (`web1`). Docker will generate a container, but the port mapping is not successful.

4. **Run with port 8080 on host and port 80 inside container (container ID exists)**

   `docker run -it --name web2 -p 8080:80 nginx`  
   - This command fails if a container with the same name (`web2`) already exists, as container names must be unique. Even if the container runs, the port is not mapped because the container ID already exists.

5. **Run with port 8080 already allocated on host**

   `docker run -it --name web3 -p 8080:80 nginx`  
   - If port `8080` is already in use on the host (by another container or application), Docker cannot map the port and the container won’t run as expected. The port is already allocated.

6. **Run with port 8081 mapped successfully**

   `docker run -it --name web4 -p 8081:80 nginx`  
   - In this case, port `8081` on the host is mapped to port `80` inside the container. This command works as expected and maps the port successfully.

7. **Run with specific IP for port mapping**

   `docker run --rm -it --name nginx1 -d -p 127.0.0.1:80:8081/tcp nginx`  
   - This command maps port `8081` inside the container to port `80` on the local machine's loopback interface (`127.0.0.1`). The container is accessible only from the host itself (not from other devices on the network).  
   - The `--rm` flag ensures the container is removed after it stops.

#### Port Binding Protocols:

- Docker uses the **TCP protocol** by default for port mappings. However, you can also specify other protocols like UDP if needed (e.g., `-p 80:80/udp` for UDP).

- A service using **port 5353 for UDP** does **not** block Docker from binding **port 5353 for TCP**, as the protocols are distinct and separate. Docker can bind to the same port for both protocols without conflicts.

---

## docker volume

Docker supports **Named & Anonymous Volumes**, **Bind Mounts**, and **tmpfs** for managing container data. Please follow [this](volumes.md) link for more details.

```bash

# Creates a Docker-managed named volume `my-volume`, stored under `/var/lib/docker/volumes`
docker volume create my-volume

# Displays metadata about the specified volume, such as mount paths and usage.
docker volume inspect my-volume  

# Lists all Docker-managed volumes on the host system.
docker volume ls  

# Cleans up all unused volumes to free disk space.
docker volume prune  

# Deletes the specified volume permanently.
docker volume rm my-volume  

## Just create the volume, no mounting

# Create the container and start shell with ananymous volume mounting.
docker run -it --name cont1 -v /Vo1 alpine /bin/sh  

# Volume type: volume (docker-managed volume; docker-named volume)
docker run -it --name cont1 --mount type=volume,source=my-volume,target=/Vol alpine /bin/sh
docker run -it --name cont1 --mount source=my-vol,target=/Vol alpine /bin/sh
docker run -it --name cont1 --mount src=my-vol,dst=/Vol alpine
docker run -it --name cont1 -v my-volume:/Vol alpine /bin/sh

# Volume type: bind (mounts host directory)

mkdir /home/ibtisam/dockr/bind  # Create a directory on the host system for mounting.
docker run -it --name cont2 -v /HOST/PATH:/CONTAINER/PATH alpine /bin/sh
docker run -it --name cont2 --mount type=bind,source=/../../,destination=/opt/data alpine /bin/sh

# Volume type: tmpfs (in-memory mount)
docker run -d -it --name cont3 --mount type=tmpfs,destination=/app alpine /bin/sh
docker run -d -it --name cont3 --tmpfs /app alpine /bin/sh

## Sharing the volume between containers

# Create a container `lec-18` with volume `/dbdata`, but container will exit immediately.
docker create -v /dbdata --name lec-18 postgres:13-alpine /bin/true
docker run -d -it --name db1 --volumes-from lec-18 postgres:13-alpine /bin/sh
docker run -d -it --name db2 --volumes-from lec-18 postgres:13-alpine /bin/sh

# Sharing a host directory between containers
docker run -it --name cont-v3 -v /home/ibtisam/docker-bind:/opt/data busybox /bin/sh
docker run -it --name cont-v4 -v /home/ibtisam/docker-bind:/opt/data busybox /bin/sh

## Privileged container to container volume mounting

# Create `container2` and share volumes from `container1`.
docker run -it --name container2 --privileged=true --volume-from container1 ubuntu bin/bash

# Mount host directory `/home/ec2-user` to `/rajput` in `container2`.  
docker run -it --name container2 -v /home/ec2-user:/ibtisam --privileged=true ubuntu bin/bash  
```

---

## docker network

```bash
# Creates a custom Docker network named `my-network`
docker network create my-network

# Displays detailed information about the custom network `my-network`, including connected containers
docker network inspect my-network

# Lists all available Docker networks on the host system
docker network ls  

# Removes the specified network `my-network` from Docker
docker network rm my-network  

# Removes all unused Docker networks to free disk space
docker network prune  

# Connects `container1` to the existing `my-network`
docker network connect my-network container1  

# Disconnects `container1` from the `my-network`
docker network disconnect my-network container1  
```
Please click [here](network.md) for more understanding.

---

## Monitoring & Debugging

```bash

# Executes an interactive bash shell inside `container1`
docker exec -it container1 /bin/sh  

# Gracefully starts/stops the running container `container1`
docker start|stop container1

# Forcefully stops the running container `container1`
docker kill container1  

# Pauses the execution of `container1`, suspending its processes
docker pause container1  

# Resumes the execution of `container1` after it has been paused
docker unpause container1  

# Starts `container1` and attaches to its output stream. This is useful for monitoring logs directly.
docker start --attach container1

# Viewing container logs
docker container logs container1

# Streams real-time logs from `container1`, useful for continuous monitoring of its output.
docker logs -f container1  

# Inspecting container details and viewing changes made to the container
# Displays detailed information about `container1` such as its configuration, environment variables, and status.
docker inspect container1

# Shows the changes made to `container1`’s filesystem since it was created, such as added or deleted files.
docker diff container1  

# Displays the port mappings for `container1`, showing which host ports are forwarded to container ports
docker container port container1  

# Search for images from Docker Hub
docker search nginx

# Converts the inspection output of `container1` into a human-readable YAML format and saves it as `container1.yaml`
docker inspect container1 | python3 -c "import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)" > container1.yaml  
```

---

## docker compose

Please click [here](compose.md).

---

## Multi-Stage Docker Build

Multi-stage builds are an efficient way to create optimized Docker images by separating build and runtime environments. This approach helps in:  

- **Reducing image size** – Only necessary files are included in the final image.  
- **Enhancing security** – Removes unnecessary build tools and dependencies.  
- **Optimizing performance** – Lighter images lead to faster deployments.  

### **How It Works?**

A multi-stage build consists of multiple `FROM` instructions, where:  
- Each stage produces artifacts that the next stage can use.  
- The final image contains only the essential runtime components.  

### **Common Approaches**  

#### 1. Using Different Images for Build and Runtime

- **First stage:** Uses a larger image with all build dependencies.  
- **Second stage:** Uses a minimal runtime image, copying only what’s required.  
- **Best for:** Compiled languages like **Go, Java, and C++**, where the build process needs extra dependencies that aren’t required in production.  

**🔹 Example Use Case:**  
- A **Go application** builds inside a full-featured image (e.g., `golang`), and the compiled binary is copied to a lightweight **Alpine-based** image for runtime.  

#### 2️. Using the First Stage as a Base for the Final Image

- The second stage extends the first while installing additional dependencies.  
- Keeps **shared base layers** but allows different configurations.  
- **Best for:** JavaScript-based applications (**Node.js**) where development tools (e.g., **nodemon**) are used in one stage, while only production dependencies remain in the final stage.  

**🔹 Example Use Case:**  
- A **Node.js app** starts with a `node:alpine` image to install dependencies and build assets. The final stage extends it, keeping only production dependencies while removing unnecessary files.  


### Benefits of Multi-Stage Builds

- **Lighter images** → Faster pull & deploy times.  
- **Better security** → Removes unused dependencies.  
- **Environment separation** → Dev & prod dependencies managed efficiently.  

By leveraging multi-stage builds, Docker images stay **optimized, secure, and production-ready**, ensuring **faster deployments and improved performance**.

For more details, please click [here](multi-stage1.md).

---

## Key Points

- **Use `-it` with `docker run`**  
  Always use the `-it` flags when running a container if you plan to enter the container later using `docker exec`. Without the `-it` flags, the container will not start in interactive mode, and you won't be able to enter it using `docker exec`. For better access, it's recommended to also add `/bin/sh` as the default shell.

- **Running Containers with `-it` and `-dit`**  
  When running a container with `docker run -it` or `docker run -dit`, `/bin/sh` is not mandatory. The container defaults to the `/root` directory if not specified.

- **Using `docker exec`**  
  The `-it` flags are mandatory when using `docker exec` if you intend to enter the container. You also need to specify the path to the shell, such as `/bin/sh` or `/bin/bash`.

  However, the path to shell isn't mandatory all the times, like : `docker exec {container ID} ls`  

- **To be in `docker ps`**  
  The `-it` flags are not required to list containers using `docker ps`. You can use `docker start` and `docker exec` to start and interact with a container.

- **Stopping and Removing Containers**  
  Use the commands `docker kill` or `docker stop` to stop a container. To remove a container or image, use `docker rm` or `docker rmi`, respectively.

- **Starting a Container After Exiting**  
  Once you exit a running container, you need to start it again before using `docker exec` to execute commands inside the container.

- **Difference between `docker start` and `docker exec`**  
  `docker start` and `docker exec` differ from `docker run`. When using `docker start/exec`, the container will not stop unless explicitly instructed to do so. This is different from `docker run`, where the container exits after the command finishes.

- **Behavior of `docker run` vs. `docker start/exec` with `exit`**  
  When using `docker run`, the container exits immediately after running the command (e.g., `exit`). However, when using `docker start` or `docker exec`, the container does not exit until it is explicitly stopped.

- **Entering a Container**  
  To enter a container, add the `-it` flags to `docker run`. Alternatively, you can add the `--attach` flag when starting the container to print its output.  

- **Container ID in Commands**  
  `docker run` does not require a container ID, but commands like `docker exec`, `docker start`, `docker stop`, `docker kill`, `docker commit`, `docker inspect`, and `docker logs` all require a container ID.

- **Docker Run vs Docker Build**  
  `docker run` does not require a path to an image, but `docker build` requires a path to the Dockerfile or the directory where it resides.

- **Starting Containers and Output**  
  `docker start {containerID}` will start the container but will not display any output. To display the container’s output, you need to use the `--attach` flag with `docker start`, like this: `docker start --attach {containerID}`.

- **Re-running Containers**  
  To run the same container, use `docker start --attach {containerID}` directly instead of using `docker exec`.

- **Using `docker commit`**  
  Every time you use `docker commit`, a new image ID is generated, regardless of whether changes were made to the container.

- **Image Layers in Docker Build**  
  Docker image layers are read-only, and the number of layers corresponds to the number of instructions (lines) in the Dockerfile.

- **Error Handling During Build**  
  If an error occurs at any layer during the build process, Docker will stop building further layers and will create an image with the tag `none`.

- **Dangling Images**  
  A dangling image is an image that does not have an image name or tag but still has an allocated image ID.

- **Dangling Image with No Tag**  
  A dangling image has no repository or tag assigned to it but still has an image ID allocated to it.  

- **Alpine Image Example**  
  When running `docker images alpine`, it will show the Alpine image. However, after running `docker build` with the `RUN alpine` command, running `docker images` will not show the Alpine image because it was built without tagging.

- **Image Name Case Sensitivity**  
  The image name should always be in lowercase. Docker will enforce this naming convention.

- **Listing Files with `ls -l`**  
  You can run `docker run alpine ls -l` to list files in the container. The `ls -l` command will print the output after exiting the container.

- **Docker Socket File (`/var/run/docker.sock`)**  
  The `/var/run/docker.sock` file connects the Docker client with the Docker daemon. If the Docker daemon is stopped, running `docker ps -a` will not show any containers.

- **Docker Build Requires a Dockerfile Path**  
  The path to the `Dockerfile` is mandatory when using `docker build`.

- **Running Commands in Containers**  
  To run commands in a container, you can use the syntax `docker run <ls -l> <bin/sh> <bin/ash> <echo “this is ibtisam”>`.

- **Image ID Changes or Remains the Same**  
  The Image ID remains the same when you delete, tag, or push an image. However, the Image ID will change if there are changes in the `Dockerfile` or if you commit a container, even if no changes were made inside it.

- **Creating Images**  
  Image IDs are created when you use commands like `docker build`, `docker pull`, or `docker commit`.

- **Using Volumes with Containers**  
  You can use the same volume for multiple containers by specifying `--name cont1 -v /VOL alpine` and `--name cont2 -v /VOL alpine`. However, each container will have a unique volume ID, so data cannot be shared between them unless you use a bind mount.

- **Sharing Data Between Containers**  
  In Docker volumes, each container has a unique volume ID, so the data is not shared between containers. However, in Docker bind mounts, data is shared because there is no volume ID assigned to bind mounts.

- **Running a Simple HTTP Server**  
  To run a simple HTTP server using `docker run`, you can use the following command:  
  `docker run -d --rm -p 8080:8080 --name webserver busybox sh -c "while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; echo 'smallest http server'; } | nc -l -p 8080; done"`.

- **Checking Running Containers**  
  You can list all containers (including stopped ones) using `docker ps -a`, or check the port of a specific container with `docker port {CONTAINERID}`.

- **Checking Open Ports on Host**  
  You can check which ports are open on the host using `netstat -tuln | grep 8080` or `ss -tuln | grep 8080`.

- **Accessing a Running Service**  
  You can access the service running on port 8080 by visiting `http://localhost:8080` or `http://192.168.100.107:8080/`.

- **Running Nginx Container**  
  You can run an Nginx container with the command:  
  `docker run -dit -p 8080:80 --name myser nginx`. However, this may not work as expected if the port is already allocated.

---

## Conclusion
Docker provides a lightweight, efficient, and secure alternative to traditional virtual machines. By addressing critical issues like dependency management, configuration consistency, portability, complexity, inefficiency, and security, Docker has become an essential tool for modern software development and deployment. Its ability to maximize resource utilization and scalability makes it indispensable for organizations aiming for agility and cost-efficiency.
