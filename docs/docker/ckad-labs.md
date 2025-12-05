## Define, Build, and Modify Container Images

### Task 1: Create a Dockerfile in the current directory for a basic Python application. Use `ubuntu:20.04` as the base image. Install Python 3 and pip via `apt-get`. Copy a file named `app.py` from the current directory to `/app` in the image. Set the working directory to `/app`. Use `CMD` to run `python3 app.py`. Save the file as `Dockerfile`.

```
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*
COPY app.py /app/
WORKDIR /app
CMD ["python3", "app.py"]
```

---

### Task 2: Write a Dockerfile for an Nginx web server. Start from `nginx:alpine`. Add a custom `index.html` file from the host's current directory to `/usr/share/nginx/html`. Expose port 80. Override the default `CMD` to include a custom entrypoint script named `start.sh` that echoes "Server starting" before running nginx.

```
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

*(start.sh content:)*
```
#!/bin/sh
echo "Server starting"
exec "$@"
```

#### Why CMD Cannot Be Removed: A Step-by-Step Rationale

1. **Default Execution Flow**: On `docker run nginx-custom`, Docker constructs: `/usr/local/bin/start.sh nginx -g daemon off;`. The script echoes the message, then `exec` replaces itself with Nginx, ensuring Nginx runs foreground (daemon off) as PID 1.
2. **Impact of Removing CMD**: The command becomes `/usr/local/bin/start.sh` (no arguments). The script echoes but `exec "$@"` (empty) does nothing, so the process exits. Logs show only "Server starting", and the container halts—useless for a web server image.
3. **Flexibility Gains**: Keeping `CMD` allows overrides like `docker run -p 80:80 nginx-custom haproxy`, running the wrapper with haproxy instead, without rebuilding the image.
4. **Signal and PID 1 Handling**: The `exec` ensures Nginx receives signals (e.g., SIGTERM), preventing zombie processes. Without a valid `CMD`, this benefit is moot.

This pattern is echoed in official examples, such as Apache wrappers, where `ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]` uses implicit `CMD` defaults, but custom scripts demand explicit `CMD` for completeness.

#### Interaction Table: ENTRYPOINT and CMD Combinations
To illustrate outcomes, here's a comprehensive table based on Docker's documented behaviors. Assume exec form unless noted.

| Scenario                          | Executed Command Example                          | Outcome/Notes |
|-----------------------------------|---------------------------------------------------|---------------|
| **No ENTRYPOINT, No CMD**        | N/A                                              | Error: Dockerfile must have at least one. |
| **No ENTRYPOINT, CMD ["nginx"]** | `nginx`                                          | Runs CMD directly; overridable by `docker run args`. |
| **ENTRYPOINT ["/script"], No CMD**| `/script`                                        | Script runs empty; likely exits if expecting args (e.g., Task 2 failure). |
| **ENTRYPOINT ["/script"], CMD ["nginx", "-g", "daemon off;"]** | `/script nginx -g daemon off;`                   | Ideal: Wrapper + defaults; args append/override CMD. |
| **Shell Form ENTRYPOINT ["/script"], CMD ["nginx"]** | `/bin/sh -c /script` (ignores CMD)              | CMD discarded; use exec form for integration. |
| **Runtime Override: docker run image custom-nginx** | `/script custom-nginx` (replaces CMD)            | Flexibility preserved; ENTRYPOINT unchanged. |

This table underscores that `CMD` is non-optional for argument-dependent entrypoints, reducing misconfigurations in CKAD-like tasks.

---

### Task 3: Using the Dockerfile from Task 1, build an image tagged `my-python-app:v1.0`. Use the current directory as the build context. Verify the build by listing images and checking the image history for layers.

```
docker build -t my-python-app:v1.0 .
docker images | grep my-python-app
docker history my-python-app:v1.0
```

---

### Task 4: Build a Docker image from a remote GitHub repository URL (e.g., `https://github.com/example/repo.git#branch:main`) that contains a Dockerfile. Tag it as `remote-build:latest`. Inspect the layers to confirm the build used caching effectively.

```
docker build https://github.com/example/repo.git#branch:main -t remote-build:latest
docker history remote-build:latest
```

---

### Task 5: Create a `.dockerignore` file to exclude `node_modules` and `.git` directories. Then, build an image from a Dockerfile in a Node.js project directory, tagging it `node-app:slim`. Prune any dangling images after the build.

*(.dockerignore content:)*
```
node_modules
.git
```

```
docker build -t node-app:slim .
docker image prune -f
```

---

### Task 6: Pull the `busybox` image and run a container interactively. Inside the container, create a directory `/data` and add a file `test.txt` with content "Modified image". Exit the container, then commit the changes to a new image tagged `busybox-modified:v1`. Run the new image to verify the file persists.

```
docker pull busybox
docker run -it --name mod-busybox busybox /bin/sh
mkdir /data
echo "Modified image" > /data/test.txt
exit
docker commit mod-busybox busybox-modified:v1
docker run busybox-modified:v1 cat /data/test.txt
docker rm mod-busybox
```

---

### Task 7: Start from an existing `alpine` image. Run a container, install `curl` using `apk add curl`, and commit the changes to `alpine-with-curl:v1`. Export this image as a tar file named `alpine-export.tar` using `docker save`.

```
docker run -it --name alpine-mod alpine /bin/sh
apk add curl
exit
docker commit alpine-mod alpine-with-curl:v1
docker save -o alpine-export.tar alpine-with-curl:v1
docker rm alpine-mod
```

---

### Task 8: Create a multi-stage Dockerfile for a Go application. In the first stage, use `golang:1.20` to build the binary from source code in `/src`. In the second stage, copy the binary to a scratch image and set `ENTRYPOINT` to run it. Build and tag the final image `go-app:prod`.

```
FROM golang:1.20 AS builder
WORKDIR /src
COPY . .
RUN go build -o app .

FROM scratch
COPY --from=builder /src/app /app
ENTRYPOINT ["/app"]
```

```
docker build -t go-app:prod .
```

---

### Task 9: Modify an existing Dockerfile for a Java app to include `ENV JAVA_OPTS="-Xmx512m"` and `HEALTHCHECK --interval=30s CMD curl -f http://localhost:8080/health || exit 1`. Rebuild the image as `java-app:updated` and test the health check in a running container.

*(Modified Dockerfile snippet addition:)*
```
ENV JAVA_OPTS="-Xmx512m"
HEALTHCHECK --interval=30s CMD curl -f http://localhost:8080/health || exit 1
```

```
docker build -t java-app:updated .
docker run -d --name test-java java-app:updated
docker inspect --format='{{json .State.Health}}' test-java | jq .
docker stop test-java && docker rm test-java
```

---

### Task 10: Given a base image `python:3.9-slim`, create a Dockerfile that uses `ARG VERSION=latest` for build-time versioning. Copy requirements.txt, run `pip install -r requirements.txt --no-cache-dir`, and copy app code. Build twice: once with default arg and once with `--build-arg VERSION=3.9.1`, tagging as `python-app:${VERSION}`.

```
FROM python:3.9-slim
ARG VERSION=latest
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir
COPY . /app
WORKDIR /app
CMD ["python", "app.py"]
```

```
docker build -t python-app:${VERSION} .
docker build --build-arg VERSION=3.9.1 -t python-app:${VERSION} .
```

---

### Task 11: For a Ruby app, create a Dockerfile with multi-stage: First stage (`FROM ruby:3.1 AS builder`) installs gems via `bundle install`. Second stage (`FROM ruby:3.1-slim`) copies `/app` from builder. Build with `docker build -t ruby-app:prod .`. Compare layer count to a single-stage version.

*(Multi-stage Dockerfile:)*
```
FROM ruby:3.1 AS builder
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN bundle exec rake build

FROM ruby:3.1-slim
WORKDIR /app
COPY --from=builder /app /app
CMD ["bundle", "exec", "ruby", "app.rb"]
```

```
docker build -t ruby-app:prod .
docker history ruby-app:prod | wc -l
```

*(Single-stage for comparison:)*
```
FROM ruby:3.1-slim
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ["bundle", "exec", "ruby", "app.rb"]
```

```
docker build -t ruby-app:single .
docker history ruby-app:single | wc -l
docker rmi ruby-app:single
```

---

### Task 12: Build an image from a subdirectory context: `docker build -f subdir/Dockerfile -t sub-build:latest subdir/`. Then, push to a registry (e.g., Docker Hub) with `docker push <repo>/<image>:<tag>`, assuming login.

```
docker build -f subdir/Dockerfile -t sub-build:latest subdir/
docker tag sub-build:latest yourusername/sub-build:latest
docker push yourusername/sub-build:latest
```

---

### Task 13: Pull `postgres:13`, run a container, create a database `testdb` via `psql`, commit to `postgres-custom:v1`. Save as `postgres.tar` and verify by loading/running it.

```
docker pull postgres:13
docker run -it --name pg-mod -e POSTGRES_PASSWORD=pass postgres:13 /bin/bash
apt-get update && apt-get install -y postgresql-client
psql -U postgres -c "CREATE DATABASE testdb;"
exit
docker commit pg-mod postgres-custom:v1
docker save -o postgres.tar postgres-custom:v1
docker rmi postgres-custom:v1 && docker load -i postgres.tar
docker run postgres-custom:v1 psql -U postgres -l | grep testdb
docker rm pg-mod
```

---

### Task 14: Modify a running `httpd` container by mounting a volume (`-v /host/dir:/usr/local/apache2/htdocs`), add files, commit changes, and update the image's `EXPOSE` in a new Dockerfile rebuild.

```
docker run -it --name httpd-mod -v /host/dir:/usr/local/apache2/htdocs -p 80:80 httpd /bin/bash
# Add files to /usr/local/apache2/htdocs inside container
exit
docker commit httpd-mod httpd-custom:v1
```

*(New Dockerfile for rebuild:)*
```
FROM httpd-custom:v1
EXPOSE 8080
```

```
docker build -t httpd-updated:latest .
docker rm httpd-mod
```

---

### Task 15: Build a custom image for a hello-world Go app, push to a registry, then create a Kubernetes Deployment YAML using it. Apply and verify with `kubectl get pods`.

*(Go Dockerfile:)*
```
FROM golang:1.20 AS builder
WORKDIR /src
COPY main.go .
RUN go build -o hello main.go

FROM alpine:latest
COPY --from=builder /src/hello /hello
CMD ["/hello"]
```

```
docker build -t yourusername/hello-go:v1 .
docker push yourusername/hello-go:v1
```

*(deployment.yaml:)*
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-go
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-go
  template:
    metadata:
      labels:
        app: hello-go
    spec:
      containers:
      - name: hello
        image: yourusername/hello-go:v1
        ports:
        - containerPort: 8080
```

```
kubectl apply -f deployment.yaml
kubectl get pods
```

---
