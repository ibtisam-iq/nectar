# Docker Compose

## Overview
Docker Compose is a tool that simplifies the management of multi-container Docker applications. It enables users to define and manage containerized applications using a single YAML file.

## Installation
Follow the official Docker Compose installation guide based on your operating system:
- [Linux Installation Guide](https://docs.docker.com/compose/install/linux/)
- [Official Documentation](https://docs.docker.com/compose/)
- [GitHub Repository](https://github.com/docker/compose)

### Install Docker Compose on Linux
Run the following commands to install Docker Compose:
```sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
Verify the installation:
```sh
docker-compose --version
```
If the symbolic link (`ln -s`) isn't created, verify using:
```sh
/usr/local/bin/docker-compose --version
```

## Basic Usage
### Start Containers in Detached Mode
```sh
docker-compose up -d
```
### Stop and Remove Containers
```sh
docker-compose down
```
### Rebuild and Start Containers (after modifying the Dockerfile)
```sh
docker-compose up --build -d
```

### Docker Compose V2 (Recommended)
For newer versions (Docker 20.10+), the command syntax has changed slightly:
```sh
docker compose up -d
```
**Note:** No hyphen (-) between `docker` and `compose`.

---
## The Compose Application Model
Docker Compose defines an application using the following key concepts:

### **1. Services**
- A service represents a computing component of an application.
- It is defined by a container image and configuration.
- Multiple instances of a service can run simultaneously.

### **2. Networks**
- Services communicate via **networks**, which establish IP routes between containers.
- Compose provides an abstraction layer over platform-specific network configurations.

### **3. Volumes**
- **Persistent storage** is managed using volumes.
- Data can be shared between services and remain intact even after container shutdowns.

### **4. Configs**
- Configurations required for runtime or platform-specific settings are defined as **configs**.
- These are similar to volumes but are managed separately for structured configurations.

### **5. Secrets**
- Secrets are used for **sensitive data** (e.g., API keys, passwords) that should not be exposed.
- They are mounted as files within the container but are securely managed by the platform.


## The Compose File
The **default** file path for a Compose file is:
```sh
compose.yaml  # (Preferred)
```
Compose also supports:
```sh
compose.yml
docker-compose.yaml
docker-compose.yml  # (Backward Compatibility)
```
If both `compose.yaml` and `docker-compose.yaml` exist, Docker Compose prioritizes **compose.yaml**.


## Docker Compose File Format
The latest and recommended version of the Compose file format is defined by the **Compose Specification**, which merges both **2.x** and **3.x** versions. This format is supported in Docker Compose versions **1.27.0+** (also known as **Compose V2**).

> **Note**: It is optional to add a version number to the file, if you're on Docker Compose v2+. However, If you do, it must be `3.8` or higher.


## Docker CLI Integration
Docker Compose is integrated into the **Docker CLI** using:
```sh
docker compose <command>
```
With this, you can manage the lifecycle of multi-container applications defined in `compose.yaml`, including:
- **Starting services**: `docker compose up`
- **Stopping services**: `docker compose down`
- **Viewing logs**: `docker compose logs`
- **Scaling services**: `docker compose up --scale <service>=<count>`

---
## Importand Docker Compose Commands
```txt
ibtisam@mint-dell:/media/ibtisam/L-Mint/git$ docker compose --help

Usage:  docker compose [OPTIONS] COMMAND

Define and run multi-container applications with Docker

Options:
      --all-resources              Include all resources, even those not used by services
      --dry-run                    Execute command in dry run mode
      --env-file stringArray       Specify an alternate environment file
  -f, --file stringArray           Compose configuration files
      --parallel int               Control max parallelism, -1 for unlimited (default -1)
  -p, --project-name string        Project name

Commands:
  attach      Attach local standard input, output, and error streams to a service's running container
  build       Build or rebuild services
  config      Parse, resolve and render compose file in canonical format
  cp          Copy files/folders between a service container and the local filesystem
  create      Creates containers for a service
  down        Stop and remove containers, networks
  events      Receive real time events from containers
  exec        Execute a command in a running container
  images      List images used by the created containers
  kill        Force stop service containers
  logs        View output from containers
  ls          List running compose projects
  pause       Pause services
  port        Print the public port for a port binding
  ps          List containers
  pull        Pull service images
  push        Push service images
  restart     Restart service containers
  rm          Removes stopped service containers
  run         Run a one-off command on a service
  scale       Scale services 
  start       Start services
  stats       Display a live stream of container(s) resource usage statistics
  stop        Stop services
  top         Display the running processes
  unpause     Unpause services
  up          Create and start containers
  version     Show the Docker Compose version information
  wait        Block until the first service container stops
  watch       Watch build context for service and rebuild/refresh containers when files are updated


ibtisam@mint-dell:/media/ibtisam/L-Mint/git$ docker compose up --help

Usage:  docker compose up [OPTIONS] [SERVICE...]

Create and start containers

Options:
      --build                        Build images before starting containers
  -d, --detach                       Detached mode: Run containers in the background
      --dry-run                      Execute command in dry run mode
      --pull string                  Pull image before running ("always"|"missing"|"never") (default "policy")
      --quiet-pull                   Pull without printing progress information
      --remove-orphans               Remove containers for services not defined in the Compose file
      --scale scale                  Scale SERVICE to NUM instances. Overrides the scale setting in the Compose file if present.
      --timestamps                   Show timestamps
      --wait                         Wait for services to be running|healthy. Implies detached mode.
      --wait-timeout int             Maximum duration to wait for the project to be running|healthy
  -w, --watch                        Watch source code and rebuild/refresh containers when files are updated.

ibtisam@mint-dell:/media/ibtisam/L-Mint/git/LocalOps/07-ReactJSPortfolio$ docker compose build --help

Usage:  docker compose build [OPTIONS] [SERVICE...]

Build or rebuild services

Options:
      --build-arg stringArray   Set build-time variables for services
      --builder string          Set builder to use
      --dry-run                 Execute command in dry run mode
  -m, --memory bytes            Set memory limit for the build container. Not supported by BuildKit.
      --no-cache                Do not use cache when building the image
      --pull                    Always attempt to pull a newer version of the image
      --push                    Push service images
  -q, --quiet                   Don't print anything to STDOUT
      --with-dependencies       Also build dependencies (transitively)


```

---
## Emample Use Cases

```yaml
version: '3.8'  # Defines the Compose file format version 
# If you're on Docker Compose v2+, remove it—it's unnecessary!

services:
  # 🚀 Use case 1: Building an image from a Dockerfile
  app:
    build:
      context: ./app  # Path where the Dockerfile is located
      dockerfile: Dockerfile  # Name of the Dockerfile (default is 'Dockerfile')
      args: # Build-time arguments (not available at runtime)
        - ENV_MODE=production  # Build argument
    container_name: my-app-container
    ports:
      - "8080:8080"  # Expose container port 8080 to host port 8080
    environment:
      - NODE_ENV=production  # Environment variable
    depends_on:
      - database  # Ensures database starts first
    volumes:
      - ./app:/usr/src/app  # Mount local 'app' directory inside container
    networks:
      - my-network

  # 🚀 Use case 2: Running a service from a pre-built image
  frontend:
    image: nginx:latest  # Use official Nginx image
    container_name: frontend-container
    ports:
      - "80:80"  # Expose port 80
    restart: always  # Restart policy: always restart container if it stops
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf  # Custom Nginx config
    depends_on:
      - app
    networks:
      - my-network

  # 🚀 Use case 3: Running a database container
  database:
    image: postgres:15  # Use official PostgreSQL image
    container_name: db-container
    restart: unless-stopped
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydatabase
    ports:
      - "5432:5432"  # Map PostgreSQL default port
    volumes:
      - db-data:/var/lib/postgresql/data  # Persistent storage
    networks:
      - my-network

  # 🚀 Use case 4: Background worker (using a Python script)
  worker:
    build:
      context: ./worker
      dockerfile: Dockerfile
    container_name: worker-container
    command: ["python", "worker.py"]  # Custom command instead of default CMD
    depends_on:
      - database  # Ensure database is ready first
    networks:
      - my-network

  # 🚀 Use case 5: Redis as an in-memory cache
  redis:
    image: redis:latest
    container_name: redis-container
    restart: always
    ports:
      - "6379:6379"
    networks:
      - my-network

  # 🚀 Use case 6: Adminer (Database management UI)
  adminer:
    image: adminer
    container_name: adminer-container
    restart: always
    ports:
      - "8081:8080"  # Adminer UI will be accessible at http://localhost:8081
    depends_on:
      - database
    networks:
      - my-network

volumes:
  db-data:  # Named volume for persistent PostgreSQL storage

networks:
  my-network:  # Custom network to connect all services
```  

---

## **Is `command` Mandatory in Docker Compose?**

### **1️⃣ Is `command` Mandatory?**
No, specifying the `command` directive in the Docker Compose file is **not mandatory**. However, its necessity depends on how the Docker image is configured.

---

### **2️⃣ What Happens if You Specify `command`?**
If you include:

```yaml
command: java -jar /usr/src/app/app.jar
```

✅ The container will run this command explicitly, **overriding** any default `CMD` or `ENTRYPOINT` defined in the Docker image.

---

### **3️⃣ What Happens if You Don't Specify `command`?**
- **If your Dockerfile has a `CMD` or `ENTRYPOINT`,** Docker Compose will execute that command automatically.
- **If your Dockerfile does not define `CMD` or `ENTRYPOINT`,** the container will start and exit immediately because no process is specified to run.

---

### **4️⃣ When Should You Explicitly Use `command`?**
✅ **Overriding the default command** if the base image has a different startup command.
✅ **Ensuring correct execution** if the Dockerfile does not already specify `CMD` or `ENTRYPOINT`.

---

### **5️⃣ How to Check if `command` is Needed?**
Check your `Dockerfile`:

#### **Scenario 1: `CMD` Already Exists (No Need for `command`)**
```dockerfile
CMD ["java", "-jar", "/usr/src/app/app.jar"]
```
❌ `command` is **not needed** in `docker-compose.yml`.

#### **Scenario 2: No `CMD` in Dockerfile (Use `command` in Compose)**
```dockerfile
# No CMD defined
```
✅ `command` **must be added** in `docker-compose.yml` to specify the startup process.

---

### **6️⃣ Conclusion**
- If `CMD` is present in the Dockerfile → **No need for `command`** in `docker-compose.yml`.
- If `CMD` is missing → **Explicitly define `command`** in `docker-compose.yml`.

Would you like me to review your Dockerfile to confirm if `command` is required? 🚀

---

2️⃣ Rebuild the Image

sh
Copy
Edit
docker compose build --no-cache
or

sh
Copy
Edit
docker build --no-cache -t my-react-portfolio .
3️⃣ Restart Your Containers

sh
Copy
Edit
docker compose up -d