# Docker Commands Deep Reference

This file is a comprehensive reference for key Docker commands in the “Define, Build, and Modify Container Images” domain.  
It includes **docker run**, **docker build**, **docker save**, **docker export / import**, **docker inspect**, **docker history**, with flags, examples, and caveats.

---

## 1. `docker run`

### Syntax

```text
docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG…]
````

Everything in `[OPTIONS]` is a flag passed to `docker run` before specifying the image. After the image (and optional tag/digest), you may supply a custom command and its arguments that override the image’s CMD or ENTRYPOINT.

### Common / Powerful Flags & Options

Here is a non-exhaustive list of many `docker run` flags you should know and practice:

| Flag / Option                                           | Meaning / Use                                                  | Notes / Examples                                                                    |                                         |                                   |
| ------------------------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------------------------------------- | --------------------------------- |
| `-d, --detach`                                          | Run container in background (daemon mode)                      | `docker run -d nginx:latest`                                      |                                         |                                   |
| `-i, --interactive`                                     | Keep STDIN open                                                | Usually used with `-t` to allow interactive shell              |                                         |                                   |
| `-t, --tty`                                             | Allocate a pseudo-tty                                          | With `-i`, gives you an interactive terminal inside container  |                                         |                                   |
| `--name <name>`                                         | Assign a name to container                                     | Instead of random auto name                              |                                         |                                   |
| `-p <hostPort:containerPort>`                           | Map a host port to container port                              | Expose container service to outside world                           |                                         |                                   |
| `-P`                                                    | Publish all exposed ports to random host ports                 | Docker chooses host ports                                                           |                                         |                                   |
| `-v <hostPath:containerPath[:ro                         | rw]>`                                                          | Bind mount a host directory or file    |
| `--mount type=bind                                      | volume                                                         | tmpfs …`                                |
| `-e, --env KEY=VALUE`                                   | Set environment variable inside container                      | Many exam tasks use this                                                            |                                         |                                   |
| `--env-file <file>`                                     | Read environment variables from file                           | Bulk setting                                                                        |                                         |                                   |
| `--entrypoint <path>`                                   | Override the image’s ENTRYPOINT                                | Useful to run a different process                              |                                         |                                   |
| `--rm`                                                  | Automatically remove container when it exits                   | Good for short-lived containers                                                     |                                         |                                   |
| `--restart <policy>`                                    | Restart policy: `no`, `on-failure`, `always`, `unless-stopped` | For service containers                                                              |                                         |                                   |
| `--network <network>`                                   | Connect container to a particular network                      | `bridge`, `host`, `none`, or a user network                                         |                                         |                                   |
| `--link <container>`                                    | (Legacy) link containers by name                               | Not recommended, deprecated                                                         |                                         |                                   |
| `--privileged`                                          | Give extended privileges to container (all host capabilities)  | Use with extreme caution                                 |                                         |                                   |
| `--security-opt`                                        | Security options (SELinux, AppArmor, seccomp)                  | E.g. `--security-opt seccomp=unconfined`                                            |                                         |                                   |
| `--cap-add`, `--cap-drop`                               | Add or drop Linux capabilities                                 | Fine control over privileges                                                        |                                         |                                   |
| `--device hostDevice[:containerDevice[:permissions]]`   | Give access to a host device (e.g. GPU, block device)          | `--device=/dev/snd:/dev/snd` etc                       |                                         |                                   |
| `--cpu-shares`, `--cpus`, `--cpuset-cpus`               | CPU resource limits / bounds                                   | For performance / isolation                                                         |                                         |                                   |
| `--memory`, `--memory-swap`                             | Memory limits                                                  | Prevent container OOM on host                                                       |                                         |                                   |
| `--ulimit`                                              | Set ulimit values inside container                             | E.g. `--ulimit nofile=1024:2048`                                                    |                                         |                                   |
| `--health-cmd`, `--health-interval`, `--health-retries` | Define health checks                                           | Useful in production containers                                                     |                                         |                                   |
| `--workdir, -w <dir>`                                   | Set working directory inside container                         | Useful if command relies on cwd                                                     |                                         |                                   |
| `--user, -u <uid:gid>`                                  | Run as a specific user inside container                        | Security / permission control                                                       |                                         |                                   |
| `--log-driver`, `--log-opt`                             | Logging options (json-file, syslog, etc)                       | Control how container logs are handled                                              |                                         |                                   |
| `--hostname`, `--add-host`                              | Set container hostname or extra hosts entries                  | For DNS or custom resolution                                                        |                                         |                                   |
| `--label`                                               | Add labels to container                                        | Metadata tagging                                                                    |                                         |                                   |
| `--shm-size`                                            | Size of `/dev/shm` inside container                            | Useful for big shared memory tasks                                                  |                                         |                                   |
| `--timeout`, `--stop-signal`                            | How container is signaled to stop                              | For graceful shutdown                                                               |                                         |                                   |
| `--ipc`, `--pid`                                        | Namespace control (IPC or PID)                                 | Share IPC with host or other container                                              |                                         |                                   |

### Example: Complex `docker run`

```bash
docker run -d \
  --name mywebapp \
  -p 8080:80 \
  -v /home/user/app:/usr/share/nginx/html:ro \
  -e ENV=prod \
  --health-cmd="curl -f http://localhost/ || exit 1" \
  --restart unless-stopped \
  --log-opt max-size=10m \
  --cpus 1.5 \
  --memory 512m \
  --network frontend-net \
  nginx:latest
```

In this example:

* Detached (`-d`), named `mywebapp`, listening on port 8080
* Host folder mapped readonly into container
* Env var set
* Health check defined
* Restart policy
* CPU & memory limits
* Logging constraint
* Network assignment

### Quiz / Exam angle

Tasks may ask:

* Run a container with specific port mapping, environment variable, memory/CPU constraints
* Use a bind mount
* Define custom hostname or DNS
* Override entrypoint, using `--entrypoint` and passing commands
* Run interactively (`-it`) or detach (`-d`) depending on context
* Use `--health-cmd` or limits flags

---

## 2. `docker build`

### Syntax

```text
docker build [OPTIONS] PATH | URL | -
```

The final argument is your **build context** (a directory or Git URL or `-` for stdin). The Dockerfile is assumed to be `PATH/Dockerfile` unless overridden.

### Key Flags / Options

| Flag / Option             | Purpose                                                         | Notes / Examples                                                    |                   
| ------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------- |
| `-t, --tag name:tag`      | Tag the built image                                             | Equivalent to `docker tag` afterward          |                   
| `-f, --file <Dockerfile>` | Specify alternate Dockerfile name / path                        | E.g. `docker build -f MyDockerfile .`    |                   
| `--build-arg KEY=VALUE`   | Pass build-time variable `ARG`                                  | You can use multiple `--build-arg` flags       |                   
| `--no-cache`              | Do not use cache during build                                   | Forces all layers to run fresh         |                   
| `--pull`                  | Always attempt to pull a newer base image                       | Ensures using latest base rather than cached                        |
| `--rm / --rm=true         | false`                                                          | Remove intermediate containers after a successful build             |
| `--squash` (experimental) | Squash new layers into single layer                             | Reduces number of layers (experimental) |                   
| `--target <stage>`        | Build only up to a specific multi-stage stage                   | Useful when Dockerfile has multiple stages                          |
| `--compress`              | Compress build context before sending to daemon                 | Saves bandwidth for large contexts            |                   
| `--isolation`             | For Windows containers: specify isolation (`process`, `hyperv`) | On Linux only `default` is supported   |                   
| `--network <mode>`        | Network setting for build steps (RUN instructions)              | e.g. `--network host` or `none`                                     |
| `--label KEY=VALUE`       | Add metadata label to resulting image                           | e.g. version, maintainer                                            | 
| `--ulimit`                | Set ulimit for build containers                                 | Control file descriptor limits etc                                  |
| `-q, --quiet`             | Suppress build output, show only final image ID                 | Useful in scripts or exam concise output mode                       |
| `--platform <os/arch>`    | target platform for build (especially with buildx)              | For multi-arch builds                |                   

### Example: Complex `docker build`

```bash
docker build -f Dockerfile.prod \
  --tag myuser/app:2.0 \
  --build-arg ENV=production \
  --build-arg VERSION=2.0 \
  --no-cache \
  --pull \
  --compress \
  --network host \
  --label maintainer="me@example.com" \
  --target release-stage \
  .
```

This builds using custom Dockerfile, tags it, passes build args, forces fresh build, pulls latest base, compresses context, uses host network mode, labels the image, and stops at `release-stage` in multi-stage build.

### Buildx / Multi-platform

If using `buildx`, you get more flags and multi-platform support:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myuser/app:multiarch \
  --push \
  .
```

* `--platform` chooses target architectures
* `--push` sends built images to registry directly
* `--call`, `--check`, etc, are advanced features in buildx

---

## 3. `docker save`

### What is `docker save`

- `docker save` (alias: `docker image save`) exports one or more Docker **images** into a tar archive. It preserves **all layers, metadata, tags, and history**.
- By default, its output is streamed to STDOUT. You can redirect it or use `-o / --output <file>` to save into a file directly.
- It is *not* for containers. That is, it doesn’t capture running container state changes (for that you use `docker export`).

### Syntax & Common Usage

| Use Case | Command |
|---|---|
| Save an image into a `.tar` file | `docker save -o image.tar myrepo/myimage:tag` |
| Save an image (via STDOUT) and redirect | `docker save myrepo/myimage:tag > image.tar` |
| Save & compress (gzip) in one step | `docker save myrepo/myimage:tag \| gzip > image.tar.gz` |
| Save multiple images to one archive | `docker save -o images.tar image1:tag image2:tag` |
| Save a specific platform variant (multi-arch) | `docker save --platform linux/arm64 -o image_arm64.tar myrepo/myimage:tag` |

### Flags / Options

- `-o, --output <file>` — write output to given file instead of STDOUT.
- `--platform <os[/arch[/variant]]>` — save only a particular platform’s variant of the image. If the specified variant is not present, the command fails.

### Loading What You Saved: `docker load`

To restore an image from a tar (or compressed tar):

```bash
# Load from file
docker load -i image.tar

# Or via STDIN
cat image.tar | docker load

# If compressed (gzip)
gunzip -c image.tar.gz | docker load

# Alternatively, decompress first then load:
gzip -d image.tar.gz
docker load -i image.tar
```

- `docker load` reads from a tar archive (either from `STDIN` or `-i <file>`) and reconstructs the image in the local Docker daemon.
- Newer Docker versions support loading compressed archives (gzip, bzip2, xz, zstd) directly. 
- You can also specify `--platform` in `docker load` for multi-arch images (API v1.48+).

### What Is Preserved vs What Is Lost

**What is preserved by `docker save` / `docker load`:**

* Full **layer structure** and content
* **Build history** (which commands produced which layer)
* **Metadata**: `ENTRYPOINT`, `CMD`, `ENV`, `LABELS`
* **Tags / repository mapping** (if included in manifest)
* Multi-architecture variants (if the image had them)

**What is *not* lost:**

* Since this is meant to faithfully reproduce the image, nothing crucial (in terms of image runtime) is lost.

**What *docker save* does *not* capture:**

* Any changes made in a running container (unless those changes were committed into an image via `docker commit`)
* State in external volumes
* Dynamically runtime data

### Examples & Scenarios

#### Basic Save & Load

```bash
docker save -o myapp_v1.tar myuser/app:latest
```

Transfer the `myapp_v1.tar` to another machine, then:

```bash
docker load -i myapp_v1.tar
```

#### Save + Compression

```bash
docker save myuser/app:latest | gzip > myapp_v1.tar.gz
```

On the target:

```bash
gunzip -c myapp_v1.tar.gz | docker load
```

#### Save Multiple Images at Once

```bash
docker save -o many_images.tar ubuntu:latest nginx:stable
```

Then load:

```bash
docker load -i many_images.tar
```

#### Save a Specific Architecture Variant

If your image supports multiple architectures:

```bash
docker save --platform linux/arm64 -o app_arm64.tar myuser/app:latest
```

### Pitfalls & Tips

* Attempting `docker load -i image.tar.gz` *without* decompressing may fail on older Docker versions. Better to use `gunzip -c | docker load`.
* Be careful with `--platform`: choosing a variant not present locally causes an error.
* Large images create large tar files — using compression helps reduce size and transfer time.
* If you save by image **ID** instead of name:tag, when loading you might get `<none>` as tag — always use a name:tag to preserve tag.
* You can pipeline across SSH to transfer image directly:

  ```bash
  docker save myimage | gzip | ssh user@remote 'gunzip -c | docker load'
  ```

  This avoids creating a local tar file.
* When saving many images, use a list of image names rather than `docker images -q` directly, to preserve tags.

---

## 4. `docker export` / `docker import`

### Commands & Flags

```bash
docker export -o container_fs.tar container_name
docker export container_name > container_fs.tar

docker import container_fs.tar newimage:tag
cat container_fs.tar | docker import - newimage:tag

# With metadata
docker import --change "ENV DEBUG=true" container_fs.tar newimage:tag
docker import --change "ENTRYPOINT [\"/bin/sh\"]" container_fs.tar newimage:tag
docker import --message "snapshot" container_fs.tar newimage:tag
```

### Explanation, Use Cases & Pitfalls

* `docker export` snapshots container filesystem only (no layers, no metadata)
* `docker import` builds an image from snapshot, but by default has no metadata; use `--change` to add metadata
* Use when you care only about files and not build lineage; not ideal for production image workflows

---

## 5. `docker inspect`

### Commands

```bash
docker inspect image:tag
docker image inspect image:tag

docker inspect --format '{{json .Config}}' image:tag
docker inspect image:tag | jq '.[0].Config.Env, .[0].Config.Entrypoint, .[0].Config.Labels'
```

### Use / What You See

* Inspect gives full JSON metadata: `.Config`, `.RootFS`, `.RepoTags`, `.Created`, `.Architecture`, etc
* Useful to verify that metadata was preserved after save/load/import/commit
* Use formatting to extract specific fields easily

---

## 6. `docker history`

### Commands

```bash
docker history image:tag
docker history --no-trunc image:tag
docker history --format '{{.CreatedBy}} ({{.Size}})' image:tag
docker history --platform linux/amd64 image:tag
docker history -q image:tag  # only layer IDs
```

### Use / Interpretation

* Shows commands (RUN, COPY, etc) and resulting layers (size, creation time)
* Helps you find which layer is bloated / inefficient
* In multi-stage builds, earlier build stage layers often not shown in final history
* Use `--no-trunc` when you want full command text

---

## 7. Summary & Study Tips

* For **docker run**, memorize the most common flags (`-d`, `-it`, `-v`, `-p`, `-e`, `--name`, `--entrypoint`) and practice combining them.
* For **docker build**, practice using `-t`, `-f`, `--build-arg`, `--no-cache`, `--pull`, `--target`, `--compress`.
* For **docker save / load**, know how to compress / decompress and pipe in/out.
* Understand the difference between **save/load** vs **export/import** — metadata and history preservation vs flattened snapshot.
* Use `inspect` and `history` after operations to verify what changed or what was preserved.
* Practice complex chained scenarios (e.g. build → save → load → run with flags) under time constraints.

---
