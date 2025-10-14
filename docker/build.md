# docker build

The `docker build` command is used to create Docker images from a `Dockerfile` and its associated context. The **context** refers to the directory sent to the Docker daemon containing the `Dockerfile` and any files required during the build process. The behavior of the `docker build` command depends on the correct setup of the context and the path to the `Dockerfile`.

### Docker Context:
The *context* is the directory specified at the end of the `docker build` command.
Docker copies the entire context directory to the Docker daemon during the build process.
All files referenced in the `Dockerfile` (e.g., `ADD`, `COPY` commands) must be located within the context directory.

### Dockerfile Path:
By default, Docker looks for a file named `Dockerfile` in the root of the context.
Use the `-f` option to specify a `Dockerfile` with a different name or located outside the default context.

```bash
docker build -t IMAGENAME:version /path/to/docker/context

docker build -t img1:sam  /home/ibtisam/docker/files	# ERROR	   Dockerfile1

docker build -t img1:sam  .		# ERROR	   Dockerfile1

docker build -t img1:sam  /home/ibtisam/docker/files	# EXECUTED  Dockerfile

docker build -t img1:sam  .		# EXECUTED  Dockerfile

docker build -t img:sam -f ../../../Dockerfile1 /home/ibtisam/docker/files    # EXECUTED

docker build -t img:sam -f ../../../Dockerfile2 /home/ibtisam/docker/files    # EXECUTED
```

---

## 1. Execution Based on Context and Dockerfile Location:

- If you run `docker build -t img1:sam /home/ibtisam/docker/files`, the build will succeed if the directory `/home/ibtisam/docker/files` contains a valid `Dockerfile`. If the `Dockerfile` has a different name (e.g., `Dockerfile1`), the build will fail unless the `-f` option is used to specify its location explicitly.

- Running `docker build -t img1:sam .` will succeed if the current directory (`.`) contains a valid `Dockerfile`. If no `Dockerfile` exists in the current directory or if it is misnamed, the build will fail.

---

## 2. Specifying an Alternate Dockerfile:

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

---

## 3. Role of the Context Directory:

- Docker copies the entire context directory to the Docker daemon during the build process. Any files referenced in the `Dockerfile` using commands like `ADD` or `COPY` must be located within the context directory. If the files are outside the context, Docker will return an error.

---

## 4. Common Errors and Their Causes: 

- **Missing `Dockerfile`**: If no `Dockerfile` is found in the context and the `-f` option is not specified, the build will fail.

- **Invalid Context**: If the context directory does not include files referenced in the `Dockerfile`, the build will fail.

- **Incorrect Dockerfile Path**: If the path provided with the `-f` option is incorrect, Docker will return an error.

---

To summarize, a successful `docker build` requires:
- A valid context directory containing all necessary files.
- A correctly specified `Dockerfile` path, either by default or using the `-f` option.
- Ensuring that all files referenced in the `Dockerfile` are accessible within the context directory.

---


## `docker build`

### Syntax

```text
docker build [OPTIONS] PATH | URL | -
```

The final argument is your **build context** (a directory or Git URL or `-` for stdin). The Dockerfile is assumed to be `PATH/Dockerfile` unless overridden.

### Key Flags / Options

| Flag / Option             | Purpose                                                         | Notes / Examples                                                    |                   |
| ------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------- | ----------------- |
| `-t, --tag name:tag`      | Tag the built image                                             | Equivalent to `docker tag` afterward           |                   |
| `-f, --file <Dockerfile>` | Specify alternate Dockerfile name / path                        | E.g. `docker build -f MyDockerfile .`    |                   |
| `--build-arg KEY=VALUE`   | Pass build-time variable `ARG`                                  | You can use multiple `--build-arg` flags       |                   |
| `--no-cache`              | Do not use cache during build                                   | Forces all layers to run fresh           |                   |
| `--pull`                  | Always attempt to pull a newer base image                       | Ensures using latest base rather than cached                        |                   |
| `--rm / --rm=true         | false`                                                          | Remove intermediate containers after a successful build             | Default is `true` |
| `--squash` (experimental) | Squash new layers into single layer                             | Reduces number of layers (experimental)  |                   |
| `--target <stage>`        | Build only up to a specific multi-stage stage                   | Useful when Dockerfile has multiple stages                          |                   |
| `--compress`              | Compress build context before sending to daemon                 | Saves bandwidth for large contexts             |                   |
| `--isolation`             | For Windows containers: specify isolation (`process`, `hyperv`) | On Linux only `default` is supported     |                   |
| `--network <mode>`        | Network setting for build steps (RUN instructions)              | e.g. `--network host` or `none`                                     |                   |
| `--label KEY=VALUE`       | Add metadata label to resulting image                           | e.g. version, maintainer                                            |                   |
| `--ulimit`                | Set ulimit for build containers                                 | Control file descriptor limits etc                                  |                   |
| `-q, --quiet`             | Suppress build output, show only final image ID                 | Useful in scripts or exam concise output mode                       |                   |
| `--platform <os/arch>`    | target platform for build (especially with buildx)              | For multi-arch builds                   |                   |

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
