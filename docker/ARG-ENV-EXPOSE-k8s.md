# Docker → Kubernetes: Deep Mapping & Behavior Guide

This document explains how Dockerfile instructions (`ARG`, `ENV`, `EXPOSE`, `ENTRYPOINT`, `CMD`) map to Kubernetes concepts and runtime behavior. It describes both “what happens in Docker” and “what happens (or must be done) in Kubernetes,” including all override rules and special cases.

---

## 1. ARG  

### In Docker  
- `ARG <name>=<default>` defines a **build-time variable**.  
- Example:  

  ```dockerfile
  ARG PORT=8000
  ```

* You may override it when building the image:

  ```bash
  docker build --build-arg PORT=5000 -t myapp .
  ```
* `ARG` variables **only exist during build time** and are *not* present in the running container or its environment.

### In Kubernetes

* No direct equivalent for `ARG`. Kubernetes doesn’t deal with build-time variables.
* Once the image is built, Kubernetes only handles runtime configuration (via ENV, ConfigMaps, Secrets, etc.).
* Any configuration variability must be expressed in Kubernetes manifest (or via external config injection), not via `ARG`.

---

## 2. ENV

### In Docker

* `ENV <name>=<value>` sets environment variables **inside the image**.
* These become defaults for any container started from that image.
* Example:

  ```dockerfile
  ENV DB_HOST=database
  ENV DB_USER=admin
  ENV DB_PASS=secret
  ENV PORT=8000
  ENV DEBUG=false
  ```

### In Kubernetes

* Kubernetes loads all ENV variables baked into the image into the container by default.
* You can additionally define an `env:` section in the Pod/Deployment manifest:

  ```yaml
  containers:
    - name: myapp
      image: myapp:latest
      env:
        - name: DB_USER
          value: "root"
        - name: NEW_FEATURE
          value: "enabled"
  ```

* **Override behavior**: If the manifest’s `env` includes a name that matches an image ENV, the value in the manifest replaces the image’s default.
* **Addition**: If the manifest defines new names not present in the image, they are simply added.
* **Preservation**: Any image ENV not overridden or mentioned remains present.
* If you omit `env:` entirely in your manifest, the container will simply run with the exact environment defined in the image.

---

## 3. EXPOSE

### In Docker

* `EXPOSE <port>` acts as *documentation*, telling others (and Docker tools) which port the application listens to (e.g. `EXPOSE 5000`).
* It does **not** automatically publish or bind that port to the host.

### In Kubernetes

* Kubernetes **ignores** Docker’s `EXPOSE` instruction. It does *not* read that metadata to configure anything.
* If you want Kubernetes (or tools, network policy, or Services) to be aware of ports, you must explicitly set them in your manifest:

  ```yaml
  containers:
    - name: myapp
      image: myapp:latest
      ports:
        - containerPort: 5000
  ```

* But even if you don’t declare `containerPort`, the container can still listen internally on 5000 (since your app is bound to it).
* To make the port reachable externally (within cluster or beyond), you must define a **Service**:

  ```yaml
  kind: Service
  apiVersion: v1
  metadata:
    name: myapp-service
  spec:
    selector:
      app: myapp
    ports:
      - port: 80
        targetPort: 5000
  ```

  * `targetPort` maps to the container’s internal listening port
  * `port` is the Service’s external port (or cluster-visible port)

---

## 4. ENTRYPOINT & CMD

### In Docker

* **ENTRYPOINT**
  Defines the executable (command) that always runs when the container starts, regardless of arguments passed.
  Example:

  ```dockerfile
  ENTRYPOINT ["python3"]
  ```

* **CMD**
  Specifies default arguments or commands for the container to run. If `ENTRYPOINT` exists, `CMD` becomes the default arguments to it. If `ENTRYPOINT` does not exist, `CMD` acts as the command itself.
  Examples:

  ```dockerfile
  CMD ["app.py"]
  # or
  CMD ["python3", "app.py"]
  ```

* **Combined Usage**
  Use both when you want a fixed executable but flexible arguments:

  ```dockerfile
  ENTRYPOINT ["python3"]
  CMD ["app.py"]
  ```

  Default behavior: runs `python3 app.py`
  You can override `CMD` by passing a different argument in `docker run`
  You can override `ENTRYPOINT` using `--entrypoint` flag in `docker run`.

### In Kubernetes

Kubernetes container spec has two fields:

* `command` → analogous to Docker’s `ENTRYPOINT`
* `args` → analogous to Docker’s `CMD`

From the official Kubernetes docs:

> The `command` field corresponds to ENTRYPOINT, and the `args` field corresponds to CMD in Docker.

#### Override Rules & Behavior

| Pod Spec Fields Provided           | Behavior / What Runs                                                           |
| ---------------------------------- | ------------------------------------------------------------------------------|
| Neither `command` nor `args` set   | Kubernetes runs the image’s default ENTRYPOINT + CMD                         |
| `command` provided, `args` omitted | Kubernetes ignores both image’s ENTRYPOINT and CMD; runs only your `command` |
| `args` provided, `command` omitted | Kubernetes uses image’s ENTRYPOINT + your `args` (overrides CMD)               |
| Both `command` and `args` provided | Kubernetes ignores both entries in the image and uses your `command` + `args`  |

Examples:

* Image:

  ```dockerfile
  ENTRYPOINT ["sleep"]
  CMD ["5"]
  ```
* In YAML:

  * **No override** → runs `sleep 5`
  * **args: ["10"]** → runs `sleep 10`
  * **command: ["echo"]** → runs `echo` (ignores defaults)
  * **command: ["sleep2"], args: ["15"]** → runs `sleep2 15`

#### Important Tips & Caveats

* Once a Pod is created, you cannot change `command` or `args` — you must recreate or update the Pod definition.
* If you override `command`, ensure that the binary/executable exists in the container image.
* For complex commands (pipes, chaining, shell logic), use shell wrapper style:

  ```yaml
  command: ["/bin/sh"]
  args: ["-c", "echo hello && sleep 3600"]
  ```

  This ensures the shell processes the logic.
* You can refer to environment variables in `args` using `"$(VAR_NAME)"` syntax.

---

## Summary & Best Practices

* **ARG** is build-time only — Kubernetes does not use it.
* **ENV** values in the image carry into Kubernetes; they can be overridden or extended via manifest `env:` fields.
* **EXPOSE** is ignored by Kubernetes — always explicitly declare `containerPort` (if needed) and use a Service for external access.
* **ENTRYPOINT** and **CMD** map to Kubernetes `command` and `args`, respectively. Override behavior is explicit and sharp: `command` replaces the executable, `args` replaces CMD, and both override defaults entirely.
---
