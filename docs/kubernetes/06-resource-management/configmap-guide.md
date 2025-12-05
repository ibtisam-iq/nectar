# Kubernetes ConfigMap Manifest Deep Dive

## **Introduction**
A **ConfigMap** in Kubernetes is an API object that allows you to store **non-sensitive configuration data** separately from the application code. This helps in maintaining a clear separation of configuration and application logic.

## 🔑 Manifest Key Components

- **apiVersion & kind**: Identifies it as a `ConfigMap`.
- **metadata.name**: Must be a valid DNS subdomain name (e.g., `my-config`).
- **data**: Stores UTF-8 string data as key-value pairs.
  - Example: `app_mode: "production"` or multi-line data like config files.
- **binaryData**: Stores binary data (e.g., images) as base64-encoded strings.
- **immutable**: If `true`, the ConfigMap can't be changed (improves performance).

### 📏 Rules

- Keys in `data` and `binaryData` must be unique and use alphanumeric characters, `-`, `_`, or `.`.
- Both `data` and `binaryData` are optional.

## 🧠 How ConfigMaps Work with Pods

ConfigMaps provide data to Pods in the same namespace. Two primary ways for Pods to consume ConfigMap data:

1. **Environment Variables (Env)**: As variables accessible inside the container.
2. **Files**: As files mounted into the container's filesystem via volumes.

> Note: Advanced apps can also read ConfigMaps via the Kubernetes API, but we’ll focus on common methods.

## 🌱 Providing Data as Environment Variables

ConfigMaps can inject data into Pods as environment variables in two different ways:

### 1. Specific Keys as Env Vars

- Use `env` to map individual ConfigMap keys to environment variables.
- **Example:** `env: { APP_MODE: ${APP_MODE} }` 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo $MY_MODE && sleep 3600"]
    env:
    - name: MY_MODE # Variable name 
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: app_mode
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app_mode: "production"
  log_level: "debug"
```

📌 **Result**: `MY_MODE=production` in the container  
📌 **Use Case**: When you need specific settings with custom variable names.

### 2. All Keys as Env Vars
- Use `envFrom` to import all key-value pairs from a ConfigMap as environment variables.
- **Example:** `envFrom: { configMapRef: { name: my-config } }`
```yaml
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo $app_mode $log_level && sleep 3600"]
    envFrom:
    - configMapRef:
        name: my-config
```

```yaml
data:
  app_mode: "production"
  log_level: "debug"
```

📌 **Result**: `app_mode=production` and`log_level=debug` in the container. 
📌 **Use Case**: When you want all ConfigMap data as variables without specifying each one.

📝 **Notes**:
- Env var names must follow Kubernetes rules (`_` allowed, `-` not allowed).
- Updates to ConfigMap **do not** reflect in env vars unless the Pod restarts.

## 📂 Providing Data as Files (Volume Mount)
ConfigMaps can provide data as files in a Pod’s filesystem, but this **only works through volume mounts**.

### 🔧 How It Works

- Mount a ConfigMap as a volume into a directory in the Pod.
- Each key in the ConfigMap becomes a file, with its value as the file content.
### 📄 Full ConfigMap as Files

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /config/app_mode && sleep 3600"]
    volumeMounts:
    - name: config-vol
      mountPath: "/config"
      readOnly: true
  volumes:
  - name: config-vol
    configMap:
      name: my-config
```

```yaml
data:
  app_mode: "production"
  log_level: "debug"
```

📌 **Files Created**:  
- `/config/app_mode` → content: `production`  
- `/config/log_level` → content: `debug`

### 📁 Specific Keys as Files
- Use `items` to select specific keys and customize file names.
- **Example:**

```yaml
volumes:
- name: config-vol
  configMap:
    name: my-config
    items:
    - key: app_mode
      path: mode.txt
```

📌 **Result**: Only `/config/mode.txt` with content `production`

### 📝 Multi-Line Data

- **ConfigMap:**

```yaml
data:
  settings: |
    debug=true
    port=8080
```

📌 **Result**: `/config/settings` with multi-line content

### 📎 Key Points

- Files are provided **only via volume mounts** -- no other way exists in Kubernetes.
- Updates to the ConfigMap automatically reflect in mounted files after a short delay (depends on kubelet sync).

## 🔁 Combining Env and Files

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: combined-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo $MODE && cat /config/settings && sleep 3600"]
    env:
    - name: MODE
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: app_mode
    volumeMounts:
    - name: config-vol
      mountPath: "/config"
  volumes:
  - name: config-vol
    configMap:
      name: my-config
      items:
      - key: settings
        path: settings
```

```yaml
data:
  app_mode: "test"
  settings: |
    debug=true
    port=8080
```

📌 **Output**:
- Env var: `MODE=test`
- File content: `debug=true` and `port=8080`

## ✨ Additional Features

### 1. 🔄 Automatic Updates

- **Files**: Auto-updated after ConfigMap change (kubelet sync).
- **Env Vars**: Require Pod restart to update.

### 2. 🔒 Immutable ConfigMaps

- Set `immutable: true` to lock a ConfigMap.
- **Example:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: locked-config
data:
  key: "value"
immutable: true
```

✅ **Benefits**:
- Prevents accidental changes.
- Improves performance (less API server load).

⚠️ **Limitation**: Cannot edit. Must delete and recreate.

## 🛠️ Practical Commands (CKA Prep)

### ✅ Creating ConfigMaps

```bash
kubectl apply -f configmap.yaml
kubectl create configmap my-config --from-literal=key=value
```

### 🔍 Checking ConfigMaps

```bash
kubectl get configmap my-config
kubectl describe configmap my-config
kubectl get configmap my-config -o yaml
```

### ❌ Deleting ConfigMaps

```bash
kubectl delete configmap my-config
```

## 🧾 Summary

**What**: ConfigMaps store configuration as key-value pairs.  
**How**:
- **Env Vars**: `env` (specific keys), `envFrom` (all keys)
- **Files**: Volume mounts only  
**Why**: Separates config from code for flexibility & portability.

ConfigMaps are simple yet powerful tools in Kubernetes for managing app configuration. Whether you prefer quick environment variables or structured config files—they’ve got you covered!

## 📚 Further Reading

- [Kubernetes ConfigMap Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [CKA Study Guide](https://github.com/ibtisam-iq/CKA-and-CKAD-prep/blob/main/3.%20Workloads%20%26%20Scheduling/07.%20Use%20ConfigMaps%20and%20Secrets%20to%20Configure%20Applications.md)
- [CKAD Study Guide](https://github.com/ibtisam-iq/CKA-and-CKAD-prep/blob/main/3.%20Workloads%20%26%20Scheduling/08.%20Understand%20ConfigMaps.md)
- [Creating ConfigMap Imperatively](configmap-imp-com.md)
- [ConfigMap Manifest]()
