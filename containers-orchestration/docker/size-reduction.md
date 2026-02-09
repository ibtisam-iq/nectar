# Ways to Reduce Docker Image Size

Reducing Docker image size is essential for improving performance, minimizing network overhead, and ensuring efficient resource usage. Here are several effective techniques to reduce image size:

## 1. Use a Smaller Base Image
- Opt for minimal base images such as `alpine`, `busybox`, or `scratch`, which have smaller footprints compared to larger images like `ubuntu` or `debian`.
- **Example:** Instead of `FROM node:latest`, use `FROM node:alpine`.

## 2. Multi-Stage Builds
- Use multi-stage builds to separate the build environment from the runtime environment, ensuring that only necessary dependencies are included in the final image.
- **Example:** Build dependencies are installed in the first stage, and only production dependencies are copied to the second stage.
- For more details, please click [here](multi-stage1.md).

```dockerfile
  # Stage 1: Build the application
  FROM golang:1.21 AS builder
  WORKDIR /app
  COPY . .
  RUN go build -o myapp

  # Stage 2: Create the final image
  FROM alpine:latest
  WORKDIR /root/
  COPY --from=builder /app/myapp .
  CMD ["./myapp"]
  ```

## 3. Remove Unnecessary Files
- Delete or ignore files that aren’t required for the application to run, such as test files, logs, or development tools.
- Use `.dockerignore` to exclude unnecessary files and directories from being copied into the image.
- **Example:** Avoid copying documentation or temporary files.

## 4. Combine RUN Instructions
- Minimize the number of `RUN` instructions by chaining them together using `&&` to reduce layers.
- **Example:**
  ```Dockerfile
  RUN apt-get update && apt-get install -y package1 package2 && rm -rf /var/lib/apt/lists/*

## 5. Clean Up After Installing Packages
- After installing dependencies or packages, clean up any unnecessary files to avoid bloating the image. This includes clearing cache and temporary installation files.
- **Example:**
  ```Dockerfile
  RUN apt-get install -y package && rm -rf /var/lib/apt/lists/*

## 6. Use `.dockerignore` to Exclude Unnecessary Files
- Add files like `.git`, `node_modules`, logs, and temp files to `.dockerignore` to prevent them from being copied into the Docker image.
- **Example:**
  ```plaintext
  .git/
  node_modules/
  *.log

## 7. Minimize the Number of Layers
- Docker images are composed of layers, and each `RUN`, `COPY`, and `ADD` creates a new layer. The fewer the layers, the smaller the image.
- Combine multiple commands or operations into a single `RUN` command.

## 8. Use a Single Image for Both Build and Run
- Use the same base image for both the build process and the runtime environment, but trim down unnecessary build tools in the final stage.
- **Example:** A Node.js app where you install dev dependencies in one stage and only copy over production dependencies in the final stage.
- Please click [here](multi-stage2.md) for more deatils.

## 9. Strip Debugging Information and Symbols
- For languages like C or C++, strip out debugging symbols and unnecessary development information.
- **Example:**
    ```Dockerfile
    RUN strip --strip-all /usr/local/bin/myapp
    ```

## 10. Use Alpine-based Images (When Possible)
- Alpine Linux is a minimal distribution, making it a great choice for reducing image size.
- Many official Docker images (e.g., `node`, `python`, `golang`) have Alpine variants.

## 11. Avoid Using `latest` Tags
- Avoid using `latest` tags for base images as it might pull in larger and unoptimized versions. Instead, pin to a specific version to reduce unpredictability in size.
- **Example:** `FROM node:16-alpine` instead of `FROM node:latest`.

## 12. Use Squashing (Experimental)
- Docker offers a **squash** option (still experimental) to combine all layers into a single layer, thus reducing the image size.
- **Example:**
    ```bash
    docker build --squash -t myapp .
    ```

### **13. Optimize Dependencies**
* Only install necessary dependencies and use production flags to avoid installing development dependencies.
* **Example:**
  ```dockerfile
  RUN npm install --only=production
  ```

### **14. Use Compressed Files**
* Use compressed files and extract them during the build process to save space.
* **Example:**
  ```dockerfile
  ADD myapp.tar.gz /usr/src/app/
  ```

### **15. Use `--no-install-recommends`**
* When installing packages, use the `--no-install-recommends` flag to avoid installing recommended but unnecessary packages.
* **Example:**
  ```dockerfile
  RUN apt-get install --no-install-recommends -y package
  ```