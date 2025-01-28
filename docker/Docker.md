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

## docker build

The `docker build` command is used to create Docker images from a `Dockerfile` and its associated context. The **context** refers to the directory sent to the Docker daemon containing the `Dockerfile` and any files required during the build process. The behavior of the `docker build` command depends on the correct setup of the context and the path to the `Dockerfile`.

##### Docker Context:
The *context* is the directory specified at the end of the `docker build` command.
Docker copies the entire context directory to the Docker daemon during the build process.
All files referenced in the `Dockerfile` (e.g., `ADD`, `COPY` commands) must be located within the context directory.

##### Dockerfile Path:
By default, Docker looks for a file named `Dockerfile` in the root of the context.
Use the `-f` option to specify a `Dockerfile` with a different name or located outside the default context.

```bash
docker build -t IMAGENAME:version /path/to/docker/context		
docker build -t img1:sam  /home/ibtisam/docker/files		    # ERROR	    {Dockerfile1}
docker build -t img1:sam  .								                  # ERROR	    {Dockerfile1}
docker build -t img1:sam  /home/ibtisam/docker/files		    # EXECUTED	{Dockerfile}
docker build -t img1:sam  .								                  # EXECUTED	{Dockerfile}
docker build -t img:sam -f ../../../Dockerfile1 /home/ibtisam/docker/files    # EXECUTED
docker build -t img:sam -f ../../../Dockerfile2 /home/ibtisam/docker/files    # EXECUTED
```

1. **Execution Based on Context and Dockerfile Location**:

- If you run `docker build -t img1:sam /home/ibtisam/docker/files`, the build will succeed if the directory `/home/ibtisam/docker/files` contains a valid `Dockerfile`. If the `Dockerfile` has a different name (e.g., `Dockerfile1`), the build will fail unless the `-f` option is used to specify its location explicitly.

- Running `docker build -t img1:sam .` will succeed if the current directory (`.`) contains a valid `Dockerfile`. If no `Dockerfile` exists in the current directory or if it is misnamed, the build will fail.

2. **Specifying an Alternate Dockerfile**:  
- If the `Dockerfile` is located **outside the context directory** or has a **different name**, the `-f` option is used to explicitly specify its path.. For example:  
  ```
  docker build -t img:sam -f ../../../Dockerfile1 /home/ibtisam/docker/files
  ```

  1. **`-f` Option:**

    - The `-f` option tells Docker where to find the `Dockerfile`. In this case, `../../../Dockerfile1` is the path to the `Dockerfile`, not a directory.

    - The `Dockerfile` can have any name (like `Dockerfile1` here) and can be located outside the context directory.

  2. **Context Directory:**

    - `/home/ibtisam/docker/files` is the **context directory**, which is the directory sent to the Docker daemon for the build process.

    - All files referenced in the `Dockerfile` (using `ADD` or `COPY`) **must exist inside this context directory**, even if the `Dockerfile` itself is located outside of it.

    - If any file referenced in the `Dockerfile` is not within `/home/ibtisam/docker/files`, the build will fail.

    - The command will also fail if: `../../../Dockerfile1` does not exist or is not a valid `Dockerfile`.

3. **Role of the Context Directory**:  
- Docker copies the entire context directory to the Docker daemon during the build process. Any files referenced in the `Dockerfile` using commands like `ADD` or `COPY` must be located within the context directory. If the files are outside the context, Docker will return an error.

4. **Common Errors and Their Causes**: 

- **Missing `Dockerfile`**: If no `Dockerfile` is found in the context and the `-f` option is not specified, the build will fail.

- **Invalid Context**: If the context directory does not include files referenced in the `Dockerfile`, the build will fail.

- **Incorrect Dockerfile Path**: If the path provided with the `-f` option is incorrect, Docker will return an error.

To summarize, a successful `docker build` requires:
- A valid context directory containing all necessary files.
- A correctly specified `Dockerfile` path, either by default or using the `-f` option.
- Ensuring that all files referenced in the `Dockerfile` are accessible within the context directory.

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

Docker supports **Volumes**, **Bind Mounts**, and **Tmpfs** for managing container data. Please follow [this](volumes.md) link for more details.

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

# Create the container and start shell without volume mounting.
docker run -it --name cont1 -v /Vo1 alpine /bin/sh  


# Volume type: volume (docker-managed volume)
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
# Docker network creation
docker network create my-network  # Creates a custom Docker network named `my-network`.

# Inspecting network details
docker network inspect my-network  # Displays detailed information about the custom network `my-network`, including connected containers.

# Listing all networks
docker network ls  # Lists all available Docker networks on the host system.

# Removing a network
docker network rm my-network  # Removes the specified network `my-network` from Docker.

# Pruning unused networks
docker network prune  # Removes all unused Docker networks to free disk space.

# Connecting a container to a network
docker network connect my-network container1  # Connects `container1` to the existing `my-network`.

# Disconnecting a container from a network
docker network disconnect my-network container1  # Disconnects `container1` from the `my-network`.
```

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
