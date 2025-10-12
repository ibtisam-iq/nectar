## Docker → Kubernetes: ARG, ENV & EXPOSE — Behavior & Mapping

### 1. ARG  

#### In Docker  
* `ARG <name>=<default>` defines a **build-time variable**.  
* Example:
    
  ```dockerfile
  ARG PORT=8000
  ```

* It is available **only during the image build process**.
* You may override it during build via `--build-arg PORT=5000`.
* **It does not persist** into the running container.

#### In Kubernetes

* Kubernetes has **no direct equivalent** for `ARG`.
* At deployment time, the image is already built, so build-time variables are irrelevant.
* Runtime configuration must be done with `ENV`, ConfigMaps, Secrets, etc.

---

### 2. ENV

#### In Docker

* `ENV <name>=<value>` sets an environment variable baked into the image.
* That value becomes the default for containers launched from that image.
* Example:

  ```dockerfile
  ENV DB_HOST=database
  ENV DB_USER=admin
  ENV DB_PASS=secret
  ENV PORT=8000
  ENV DEBUG=false
  ```

#### In Kubernetes

* Kubernetes loads all environment variables baked into the image by default into the container.
* In your Pod or Deployment YAML, you may include an `env:` section to override or supplement them:

  ```yaml
  env:
    - name: DB_USER
      value: "root"
    - name: FEATURE_FLAG
      value: "true"
  ```

* **Override behavior**: If the name matches one from the image (e.g. `DB_USER`), the manifest value takes precedence.
* **Addition behavior**: Variables in manifest not present in the image (e.g. `FEATURE_FLAG`) are simply added.
* **Preservation**: Any image ENV not mentioned in manifest stays unchanged.
* If you **omit** any `env:` block:

  * All image ENV variables remain intact and active.

---

### 3. EXPOSE

#### In Docker

* `EXPOSE <port>` documents which port(s) the container will listen on (example: `EXPOSE 5000`).
* It **does not** publish or map that port to the host automatically.

#### In Kubernetes

* Kubernetes **ignores** Docker’s `EXPOSE` instruction.

* You must **explicitly declare** container ports in your Pod/Deployment YAML if you want them known:

  ```yaml
  ports:
    - containerPort: 5000
  ```

* Even without `containerPort` declared, the container can still listen internally on that port (because the app logic inside does so).

* To expose the application externally or within the cluster, you create a **Service**:

  ```yaml
  kind: Service
  apiVersion: v1
  metadata:
    name: myapp-svc
  spec:
    selector:
      app: myapp
    ports:
      - port: 80
        targetPort: 5000
  ```

  * `targetPort` is the internal port inside the container (must match what your application listens on).
  * `port` is the port exposed via the Service to the cluster or outside.

---

### Summary Table

| Concept  | Docker Phase                       | Kubernetes Phase / Behavior                                           |
| -------- | ---------------------------------- | --------------------------------------------------------------------- |
| `ARG`    | Build-time variable, not persisted | No equivalent; runtime configuration via ENV, ConfigMaps, Secrets     |
| `ENV`    | Sets default variables in image    | Loaded by default; manifest `env:` can override or add                |
| `EXPOSE` | Documentation of listening port    | Ignored by Kubernetes; you must explicitly declare ports and Services |

> **Key Takeaways:**
>
> * Docker’s `ARG` is build-time only — once the image is built, Kubernetes doesn’t use it.
> * Docker’s `ENV` values *do* carry over to Kubernetes containers by default, but you can override or add more via `env:` in the manifest.
> * Kubernetes ignores `EXPOSE` — you need to declare ports manually in Pod specs and Services for proper exposure.

---
