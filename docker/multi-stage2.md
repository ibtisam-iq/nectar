# Using One Stage as a Base for Another (Part -II)

```dockerfile
FROM node:alpine as abc
ARG PORT=8000
ENV PORT=$PORT
WORKDIR /app
COPY . .
EXPOSE $PORT
RUN npm install --only=prod
CMD npm run start:prod

FROM abc as xyz
RUN npm install --only=dev
CMD npm start
```

```json
{
    "name": "Ibtisam my sweetheart",
    "version": "1.0.0",
    "scripts": {
        "start": "nodemon src/index.js",
        "start:prod": "node src/index.js"
    },
    "dependencies": {
        "express": "^4.17.3"
    },
    "devDependencies": {
        "nodemon": "^2.0.6"
    }
}
```

### What Happens Here?

1️⃣ **Stage 1 (abc):**
- Starts with `node:alpine`
- Installs only production dependencies (`npm install --only=prod`)
- Sets up the application (`WORKDIR`, `COPY`, `EXPOSE`)
- Uses `CMD npm run start:prod` for production

2️⃣ **Stage 2 (xyz):**
- Starts `FROM` the first stage (abc)
- Installs development dependencies (`npm install --only=dev`)
- Uses `CMD npm start` for development

### 🧐 Key Differences Compared to a Standard Multi-Stage Build

| Approach                       | How It Works                                      | Use Case                                      |
|--------------------------------|--------------------------------------------------|-----------------------------------------------|
| Separate Images per Stage      | `FROM alpine AS build` → `FROM nginx AS final`   | Optimized production builds by copying only required files |
| Using a Named Stage as a Base  | `FROM abc AS xyz`                                | Same base setup, but installs extra dependencies for different environments |

### 🎯 Why Use This Approach?

- ✅ 1. Single Dockerfile for Both Dev & Prod
  - Instead of maintaining two separate Dockerfiles (`Dockerfile.dev` & `Dockerfile.prod`), you can switch between stages easily.
- ✅ 2. Optimized for Multi-Environment Builds
  - Production (abc): Minimal dependencies
  - Development (xyz): Extra tools & debug utilities
- ✅ 3. Saves Build Time & Cache
  - `abc` already has `npm install --only=prod`, so `xyz` only adds dev dependencies instead of reinstalling everything.

### 🛠 How to Use Different Stages?

#### 🔹 Building for Production
```sh
docker build --target abc -t myapp-prod .
docker run -p 8000:8000 myapp-prod
```

#### 🔹 Building for Development
```sh
docker build --target xyz -t myapp-dev .
docker run -p 8000:8000 myapp-dev
```

### 🔥 When to Use This?
- 🔹 You need different dependencies for different environments (prod vs dev).
- 🔹 You want a single Dockerfile for both use cases.
- 🔹 You want to reuse layers instead of creating two separate builds.

---

## 🚀 Conclusion
This is an advanced multi-stage pattern where you build on top of previous stages instead of copying artifacts into a new image. It's not for reducing image size but for managing multiple environments efficiently. 💡
