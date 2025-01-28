# Docker Volumes

Docker supports **Volumes**, **Bind Mounts**, and **Tmpfs** for managing container data. Below are the commands grouped by volume type with explanations and conditions.

---

## 1. **Create and Inspect Volumes**

### Create a named volume
`docker volume create|inspect|ls|prune|rm my-volume`  
- Creates a Docker-managed named volume `my-volume`, stored under `/var/lib/docker/volumes`.

### Inspect a volume
`docker volume inspect my-volume`  
- Displays metadata about the specified volume, such as mount paths and usage.

### List all volumes
`docker volume ls`  
- Lists all Docker-managed volumes on the host system.

### Remove unused volumes
`docker volume prune`  
- Cleans up all unused volumes to free disk space.

### Remove a specific volume
`docker volume rm my-volume`  
- Deletes the specified volume permanently.

---

## 2. **Mounting Volumes**

### Run with a volume mount
`docker run -it --name cont1 -v my-volume:/Vol alpine /bin/sh`  
- Mounts the Docker-managed volume `my-volume` to `/Vol` in the container.

### Run with explicit mount type (volume)
`docker run -it --name cont1 --mount type=volume,source=my-volume,target=/Vol alpine /bin/sh`  
- Explicitly specifies the volume type and paths. Equivalent to the `-v` option.

### Volume sharing between containers
```bash
docker create -v /dbdata --name lec-18 postgres:13-alpine /bin/true
docker run -d --name db1 --volumes-from lec-18 postgres:13-alpine
docker run -d --name db2 --volumes-from lec-18 postgres:13-alpine
lec-18: Creates a container with the volume /dbdata but does not start it.
db1 and db2: Share the same volume /dbdata created by lec-18.
```

---

## 3. **Bind Mounts**

### Run with a bind mount
`docker run -it --name cont2 -v /HOST/PATH:/CONTAINER/PATH alpine /bin/sh`  
- Maps `/HOST/PATH` on the host to `/CONTAINER/PATH` inside the container.

### Run with explicit mount type (bind)
`docker run -it --name cont2 --mount type=bind,source=/home/user/data,target=/opt/data alpine /bin/sh`  
- Maps `/home/user/data` to `/opt/data` in the container using an explicit bind mount.

### Run multiple containers with shared bind mount
```bash
docker run -it --name cont-v3 -v /home/user/data:/opt/data busybox /bin/sh
docker run -it --name cont-v4 -v /home/user/data:/opt/data busybox /bin/sh
Both containers share /home/user/data. Changes in the bind mount are reflected across all containers and the host.
```

---

## 4. **Tmpfs Mounts**

### Run with a tmpfs mount
`docker run -d -it --name cont3 --mount type=tmpfs,destination=/app alpine /bin/sh`  
- Creates a temporary in-memory filesystem mounted at `/app`.

### Run with --tmpfs option
`docker run -d -it --name cont3 --tmpfs /app alpine /bin/sh`  
- Equivalent to the `--mount` option, creating an in-memory filesystem at `/app`.

---

## 5. **Special Cases**

### Privileged volume sharing
```bash
docker run -it --name container1 --volume /shared-data:/data alpine /bin/sh
docker run -it --name container2 --privileged=true --volume-from container1 alpine /bin/sh
container2 shares the volume /shared-data from container1 with elevated permissions.
```

### Container-to-host bind mount
`docker run -it --name container2 -v /home/ec2-user:/rajput --privileged=true ubuntu bin/bash`  
- Maps `/home/ec2-user` on the host to `/rajput` in the container with elevated privileges.

---

## 6. **Key Notes**

### Volume vs. Bind Mount:
- Volumes are managed by Docker and stored in `/var/lib/docker/volumes`.
- Bind mounts map specific host directories to container paths.

### Tmpfs Characteristics:
- Tmpfs volumes use host memory. Data is wiped when the container stops.

### Protocol Independence:
- Docker uses TCP protocol by default.
- Services using UDP ports (e.g., port 5353 for UDP) do not conflict with Docker binding the same port for TCP.

---

# Docker `run` Command Use Cases

The `docker run` command is used to create and start a container from a specified image. It is often the first step to interact with a containerized application.

## Table of Contents
1. [Basic Syntax](#basic-syntax)
2. [Key Concepts](#key-concepts)
3. [Use Case Examples](#use-case-examples)
    - [Override ENTRYPOINT and CMD](#override-entrypoint-and-cmd)
    - [Run and Remove the Container Automatically on Exit](#run-and-remove-the-container-automatically-on-exit)
    - [Run with a Shell Command](#run-with-a-shell-command)
    - [Run with a Custom Command and Arguments](#run-with-a-custom-command-and-arguments)
    - [Run with the Sleep Command](#run-with-the-sleep-command)
    - [Run with a Shell Command to Echo a Message](#run-with-a-shell-command-to-echo-a-message)
    - [Run with Default Command](#run-with-default-command)
    - [Run with Custom Mount](#run-with-custom-mount)
    - [Run with Capability Drop](#run-with-capability-drop)
    - [Run with Specific User](#run-with-specific-user)
    - [Run with Environment Variable and Bind Mount](#run-with-environment-variable-and-bind-mount)

---

## Basic Syntax

```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]