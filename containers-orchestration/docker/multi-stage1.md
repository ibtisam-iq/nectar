# 🚀 Multi-Stage Docker Build: The Ultimate Guide

Please click below to read more:

- [Using One Stage as a Base for Another](multi-stage2.md)
- [How to Choose the Right Base Image?](multi-stage3.md)

## 📌 1. What is Multi-Stage Docker Build?
A multi-stage build in Docker allows you to create lightweight production images by using multiple stages in a single Dockerfile.

### 🔹 Why?
- Reduces image size 🚀
- Removes unnecessary dependencies 📦
- Improves security 🔐

### 🔹 How?
- Uses multiple `FROM` instructions in a Dockerfile
- The first stage builds the application (heavy with build tools)
- The final stage copies only required files (small, optimized image)

---

## 📌 2. Why Use Multi-Stage Builds?

### 🚫 Traditional Docker Build Problems:
- Large image sizes 📏
- Contains unnecessary build dependencies 🏗️
- Slower deployments ⏳
- Security risks from exposed development tools 🛑

### ✅ Benefits of Multi-Stage Builds:
- ✔ Optimized Image (removes dev tools)
- ✔ Smaller Attack Surface (reduces vulnerabilities)
- ✔ Faster Deployment (smaller size → faster pull/push)
- ✔ Better Caching (leverages Docker build cache)

---

## 📌 3. When to Use Multi-Stage Builds?

| Scenario                     | Why Use Multi-Stage?                  |
|------------------------------|---------------------------------------|
| Large application builds     | Keeps production images small         |
| Compiled languages (Go, Java, C++) | Removes compilers & unnecessary files |
| Frontend + Backend builds    | Optimizes assets & minimizes image size |
| Security-conscious projects  | Reduces attack surface                |

---

## 📌 4. How Multi-Stage Builds Work (Syntax & Example)

### Basic Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build the application
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Create the final lightweight image
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/myapp .
CMD ["./myapp"]
```

### 🔍 Explanation:
1️⃣ **Stage 1 ("builder")**
- Uses a full Golang environment
- Compiles the app inside `/app`

2️⃣ **Stage 2 (Final Image)**
- Uses a lightweight alpine image
- Copies only the compiled binary (no Golang compiler)

**Result:** 🚀 Smaller, faster, secure image!

### 🏗️ Build & Run:
```sh
docker build -t myapp .
docker run myapp
```

---

## 📌 5. Use Cases & Real-World Examples

### 🏆 Use Case 1: Optimizing a Node.js + React App

**Problem:**
- React requires npm install and build steps.
- Final image should not include Node.js.

**Solution: Multi-Stage Build**

```dockerfile
# Stage 1: Build React App
FROM node:alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Use lightweight Nginx
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**✅ Benefits:**
- ✔ Keeps only static files in production
- ✔ Node.js not included in final image
- ✔ Smaller & more secure

### 🏗️ Build & Run:
```sh
docker build -t react-app .
docker run -p 8080:80 react-app
```

### 🏆 Use Case 2: Python Flask App with Dependencies

**Problem:**
- Python apps need many dev libraries.
- Production image should only contain runtime.

**Solution: Multi-Stage Build**

```dockerfile
# Stage 1: Build with dependencies
FROM python:3.10 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Stage 2: Minimal Production Image
FROM python:3.10-slim
WORKDIR /app
COPY --from=builder /app /app
CMD ["python", "app.py"]
```

**✅ Benefits:**
- ✔ Reduces final image size by ~60%
- ✔ Keeps unnecessary dependencies out of production

### 🏗️ Build & Run:
```sh
docker build -t flask-app .
docker run -p 5000:5000 flask-app
```

### 🏆 Use Case 3: Java Spring Boot Optimization

**Problem:**
- Java apps require Maven for building.
- The final image should not include Maven.

**Solution: Multi-Stage Build**

```dockerfile
# Stage 1: Build JAR file
FROM maven:3.9 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Minimal JDK Runtime
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/myapp.jar .
CMD ["java", "-jar", "myapp.jar"]
```

**✅ Benefits:**
- ✔ Removes Maven from the final image
- ✔ Production image only contains JDK + JAR
- ✔ Faster deployment & startup

### 🏗️ Build & Run:
```sh
docker build -t my-java-app .
docker run -p 8080:8080 my-java-app
```

---

## 📌 6. Multi-Stage Build vs. Traditional Docker Build

| Feature          | Traditional Build | Multi-Stage Build |
|------------------|-------------------|-------------------|
| Image Size       | 🚫 Large          | ✅ Small          |
| Security         | 🚫 More dependencies | ✅ Fewer dependencies |
| Build Time       | 🚫 Slower         | ✅ Faster         |
| Best for         | Dev Environments  | Production        |

---

## 📌 7. Key Multi-Stage Build Commands

| Command               | Purpose                                      |
|-----------------------|----------------------------------------------|
| `COPY --from=builder` | Copies files from a previous stage           |
| `AS builder`          | Names the stage (optional but recommended)   |
| `RUN mvn clean package` | Builds Java app inside build stage         |
| `RUN npm run build`   | Compiles React app                           |
| `EXPOSE 80`           | Opens port 80 for HTTP services              |

---

## 📌 8. Summary & Best Practices

- ✅ Use multi-stage builds for all production images
- ✅ Reduce image size by excluding build tools
- ✅ Keep build separate from runtime
- ✅ Use lightweight base images (alpine, slim)
- ✅ Always name your build stages (`AS builder`)

### 🎯 Final Takeaway
Multi-stage builds drastically improve Docker images by making them:
- Smaller (less storage, faster deployment)
- More secure (fewer dependencies)
- Optimized for production

---

