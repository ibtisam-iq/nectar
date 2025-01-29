# Docker Volumes

Docker supports **Volumes**, **Bind Mounts**, and **Tmpfs** for managing container data. Below are the commands grouped by volume type with explanations.

---

## Basic Commands

1. **Create a named volume**
   
   `docker volume create my-volume`  
   - Creates a Docker-managed named volume (`my-volume`) stored in `/var/lib/docker/volumes`.

2. **Inspect a volume**
   
   `docker volume inspect my-volume`  
   - Displays metadata about the specified volume, such as mount paths and usage.

3. **List all volumes**
   
   `docker volume ls`  
   - Lists all Docker-managed volumes on the host system.

4. **Remove unused volumes**
   
   `docker volume prune`  
   - Cleans up all unused volumes to free disk space.

5. **Remove a specific volume**
   
   `docker volume rm my-volume`  
   - Deletes the specified volume permanently.

---

## Implicit vs Explicit

1. **Docker-created volumes (implicit creation)**  
   - When using the `-v` or `--mount` options without prior creation, Docker automatically creates the volume.  
   - The volume is managed by Docker and resides in `/var/lib/docker/volumes/`.  
   - No customization options are available (e.g., labels, drivers).  
   Example:  
   `docker run -it --name container1 -v my-volume:/data alpine`

2. **Explicitly created volumes**  
   - Volumes can be explicitly created using the `docker volume create` command.  
   - This allows customization, such as setting labels or specifying drivers.  
   - The volume is created before being used by any container and can be inspected or managed directly.  
   Example:  
   `docker volume create --name my-volume --label project=myapp`  
   `docker run -it --name container2 -v my-volume:/data alpine`

3. **No functional difference in use**  
   - Both implicitly and explicitly created volumes are managed by Docker, stored in the same location, and function identically when used in containers.  
   - Explicit creation is preferred when you need control over volume configuration or naming consistency.

---

## Docker: Managing Mounts and Volumes

### 1. **Mounting Volumes (Docker-created volumes)**

- A volume may be `named` or `anonymous`. Anonymous volumes are given a random name that's guaranteed to be unique within a given Docker host. Just like named volumes, anonymous volumes persist even if you remove the container that uses them, except if you use the `--rm` flag when creating the container, in which case the anonymous volume associated with the container is destroyed.

- A volume (in case of named volume) is created inside Docker itself (implicitly or explicitly) and then mounted to that container. 

#### Run with anonymous volume
`docker run -it --name cont1 -v /data alpine`
- Anonymous volume is created and mounted to the container. The volume is named automatically. 

#### Run with a named volume
`docker run -it --name cont1 -v my-volume:/Vol alpine /bin/sh`  
- Mounts the Docker-managed volume `my-volume` to `/Vol` in the container.

#### Run with explicit mount type (volume)
`docker run -it --name cont1 --mount type=volume,source=my-volume,target=/Vol alpine /bin/sh`  
- Explicitly specifies the volume type and paths. Equivalent to the `-v` option.

#### Volume sharing between containers

- **Unique Volume IDs**: When using Docker volumes, each container has its own unique volume ID. By default, Docker volumes are isolated, meaning containers can't share the data unless explicitly configured (e.g., using the `--volumes-from` flag or volume sharing).

```bash
docker volume create my-volume
docker run -it --name cont1 -v my-volume:/opt/data alpine /bin/sh
docker run -it --name cont2 -v my-volume:/opt/data alpine /bin/sh
```
  - In this case, even though both containers use the same volume name (`my-volume`), each container has a unique volume ID, and they don’t share data unless the volume is explicitly shared using additional configuration.

```bash
docker create -v /dbdata --name lec-18 postgres:13-alpine /bin/true  
docker run -d --name db1 --volumes-from lec-18 postgres:13-alpine  
docker run -d --name db2 --volumes-from lec-18 postgres:13-alpine
```  
  - `lec-18`: Creates a container with the volume `/dbdata` but does not start it.  
  - `db1` and `db2`: Share the same volume `/dbdata` created by `lec-18`.
---

### 2. **Bind Mounts**

- A directory is created inside the host and then mounted inside the container.

#### Run with a bind mount
`docker run -it --name cont2 -v /HOST/PATH:/CONTAINER/PATH alpine /bin/sh`  
- Maps `/HOST/PATH` on the host to `/CONTAINER/PATH` inside the container.

#### Run with explicit mount type (bind)
`docker run -it --name cont2 --mount type=bind,source=/home/user/data,target=/opt/data alpine /bin/sh`  
- Maps `/home/user/data` to `/opt/data` in the container using an explicit bind mount.

#### Run multiple containers with shared bind mount

- **Sharing Data:** Multiple containers can mount the same host directory to the same path within the container. All containers sharing this bind mount will see the same data and changes made by other containers.

```bash
docker run -it --name cont1 -v /home/user/data:/opt/data alpine /bin/sh
docker run -it --name cont2 -v /home/user/data:/opt/data alpine /bin/sh
```
  - In this case, both containers (`cont1` and `cont2`) share the same `/home/user/data` directory from the host system. Any changes made by `cont1` to `/opt/data` will be visible to `cont2` and vice versa.

---

### 3. **tmpfs Mounts**

#### Run with a tmpfs mount
`docker run -d -it --name cont3 --mount type=tmpfs,destination=/app alpine /bin/sh`  
- Creates a temporary in-memory filesystem mounted at `/app`.

#### Run with `--tmpfs` option
`docker run -d -it --name cont3 --tmpfs /app alpine /bin/sh`  
- Equivalent to the `--mount` option, creating an in-memory filesystem at `/app`.

---

## Special Cases

### Privileged volume sharing
`docker run -it --name container1 --volume /shared-data:/data alpine /bin/sh`  
`docker run -it --name container2 --privileged=true --volume-from container1 alpine /bin/sh`  
- `container2` shares the volume `/shared-data` from `container1` with elevated permissions.

### Container-to-host bind mount
`docker run -it --name container2 -v /home/ec2-user:/ibtisam --privileged=true ubuntu bin/bash`  
- Maps `/home/ec2-user` on the host to `/ibtisam` in the container with elevated privileges.

---

## Key Notes

### Volume vs. Bind Mount
- **Volumes**:  
  - Managed by Docker and stored in `/var/lib/docker/volumes`.
  - Deleting the container does not delete the volume itself. We will delete it later manually.
- **Bind Mounts**:  
  - Map specific host directories to container paths.

### Tmpfs Characteristics
- Tmpfs volumes use host memory.  
- Data is wiped when the container stops.

### Protocol Independence
- Docker uses the **TCP protocol** by default.  
- Services using **UDP ports** (e.g., port `5353` for UDP) do not conflict with Docker binding the same port for TCP.

---
