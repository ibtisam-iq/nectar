# 🛡️ Kubernetes `securityContext` Deep Dive

Official Kubernetes documentation: [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

## 📘 What is `securityContext`?

In Kubernetes, the `securityContext` defines privilege and access control settings for a **Pod or Container**. It’s crucial for securing workloads by configuring:

- Which user the container runs as
- Access to the file system
- Ability to escalate privileges
- POSIX group access
- Linux capabilities and kernel-level security features like SELinux

These settings help enforce **principle of least privilege** and **compliance**.

---

## 🔎 Why Use `securityContext`?
Kubernetes runs applications in **isolated containers**. To strengthen **security**, we need control over how containers run processes, access files, escalate privileges, etc. This is where `securityContext` comes in.

- Helps run containers as **non-root users**
- Prevents privilege escalation
- Controls access to filesystem
- Assigns ownership to volumes

---

## 🔐 `securityContext` Fields Explained with Impact

Below are the most commonly used fields and their real impact in containers:

### 1. `runAsUser`
Defines the **UID** that the container's processes run as.

📄 YAML:
```yaml
securityContext:
  runAsUser: 1000
```

📌 **Effect:**
Inside the container, all processes will run as user ID `1000`. Example:

```bash
ps aux
```
Output:
```
PID   USER     TIME  COMMAND
  1   1000     0:00  sleep 1h
  6   1000     0:00  sh
```

🧠 Use it when you want to run containers as non-root users.

---

### 2. `runAsGroup`
Defines the **GID** that the container’s processes run as.

📄 YAML:
```yaml
securityContext:
  runAsGroup: 3000
```

📌 **Effect:**
All processes will run with the specified group ID `3000`.
Check with:
```bash
id
```
Output:
```
uid=1000 gid=3000 groups=3000
```
**Note:**
The `runAsGroup` field specifies the primary group ID of 3000 for all processes within any containers of the Pod. If this field is omitted, the primary group ID of the containers will be root(0). Any files created will also be owned by user 1000 and group 3000 when `runAsGroup` is specified.

---

### 3. `fsGroup`
- **Gives group ownership of mounted volumes** to specified GID.
- **New files created in mounted volumes** (e.g., `/data`) are owned by this group.

```yaml
securityContext:
  fsGroup: 2000
```

🧪 Example Walkthrough:
```bash
$ id
uid=1000 gid=3000 groups=3000,2000

$ ls -ld /data
# Directory shows group ID = 2000 (from fsGroup)
drwxrwsrwx 2 root 2000 4096 Apr 8 20:08 demo
```
- Helps multiple containers **share** access to volume files.
- **Prevents** unauthorized access to shared files.
- Useful when shared storage must be writable by group.

> **Want a detailed documentation? Click [here](fsGroup.md)!**

---

### 4. `seLinuxOptions`
- **What it does**: Defines SELinux labels for process and file access.
- **Use Case**: Fine-grained access control for systems using SELinux.

```yaml
securityContext:
  seLinuxOptions:
    level: "s0:c123,c456"
    role: "system_r"
    type: "spc_t"
    user: "system_u"
```

---

### 5. `supplementalGroups`
Adds **additional groups** the container's processes will be part of.

📄 YAML:
```yaml
securityContext:
  supplementalGroups: [4000, 5000]
```
Alternatively, you can use a list of integers:
```yaml
securityContext:
  supplementalGroups:
  - 4000
  - 5000
```

📌 **Effect:**
Inside container:
```bash
id
```
Output:
```
uid=1000 gid=3000 groups=3000,4000,5000
```
Allows access to shared volumes or devices owned by those groups.

---

### 6. `runAsNonRoot`
Ensures container **cannot** run as root.

📄 YAML:
```yaml
securityContext:
  runAsNonRoot: true
```

📌 **Effect:**
If container tries to run as UID 0 (root), it will be blocked.
Useful for ensuring least privilege.

---

### 7. `allowPrivilegeEscalation`
Prevents processes from gaining more privileges than their parent.

📄 YAML:
```yaml
securityContext:
  allowPrivilegeEscalation: false
```

📌 **Effect:**
Disallows tools like `sudo`, `setuid`, etc. Useful for untrusted containers.

**Note**: 
`allowPrivilegeEscalation` is always true when the container:
- is run as privileged, or
- has `CAP_SYS_ADMIN`

---

### 8. `readOnlyRootFilesystem`
Mounts root filesystem as read-only.

📄 YAML:
```yaml
securityContext:
  readOnlyRootFilesystem: true
```

📌 **Effect:**
Prevents writing to `/`. App must write to mounted volumes instead.
Useful for hardened environments.

---

### 9. `capabilities`
Controls Linux kernel capabilities granted to the container.
- Official documentation: [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)

📄 YAML:
```yaml
securityContext:
  capabilities:
    drop:                   # ["ALL"]
      - ALL
    add:                    # ["NET_BIND_SERVICE", "NET_RAW"]
      - NET_BIND_SERVICE
      - CHOWN
```

📌 **Effect:**
Removes all privileges and adds back only necessary ones like binding to ports <1024.

---

## 🏗️ Pod-level vs Container-level `securityContext`

Kubernetes allows you to define `securityContext`:

- At the **Pod level**: applies defaults to **all containers**
- At the **Container level**: overrides pod-level for that container

### 🔁 Precedence
| Defined At | Takes Effect? |
|------------|---------------|
| Pod-level only | ✅ Applied to all containers |
| Container-level only | ✅ Applied only to that container |
| Both | ✅ Container-level **overrides** Pod-level |

---

## ✅ Full Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:  # Pod-level security context
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    supplementalGroups: [4000]
    runAsNonRoot: true
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "sleep 1h"]
    securityContext:  # Container-level security context
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
```

---

## 🧪 What This Means in Practice
- Pod processes run as UID 1000, GID 3000
- All mounted volumes (like /data) get GID 2000
- Extra group access for GID 4000
- Root FS is read-only (container level)
- All kernel capabilities dropped except for port binding

---

### 🔐 Kubernetes `securityContext` Key Reference

| 🧩 Field Name              | 📍 Applies To        | 📘 Description                                                      |
| -------------------------- | -------------------- | ------------------------------------------------------------------- |
| `runAsUser`                | ✅ Pod & ✅ Container  | Runs the process inside container as a specific UID.                |
| `runAsGroup`               | ✅ Pod & ✅ Container  | Runs the process with specified GID.                                |
| `fsGroup`                  | ✅ Pod Only           | Sets GID for mounted volumes (shared among containers).             |
| `fsGroupChangePolicy`      | ✅ Pod Only           | Controls when `fsGroup` is applied to volume files.                 |
| `supplementalGroups`       | ✅ Pod Only           | Additional GIDs added to all containers in the Pod.                 |
| `supplementalGroupsPolicy` | ✅ Pod Only *(Alpha)* | Controls how supplementalGroups are applied (only in strict mode).  |
| `capabilities.add`         | ✅ Container Only     | Add Linux capabilities (e.g., `NET_ADMIN`, `SYS_TIME`).             |
| `allowPrivilegeEscalation` | ✅ Container Only     | Prevents gaining more privileges than parent process.               |
| `readOnlyRootFilesystem`   | ✅ Container Only     | Mounts the container's root filesystem as **read-only** to prevent tampering. |
| `privileged`                | ✅ Container Only     | Gives full host privileges to the container (dangerous!). |
| `runAsNonRoot` | ✅ Pod & ✅ Container  | Ensures container doesn't run as UID 0 (root). |
| `seccompProfile.type`      | ✅ Pod & ✅ Container  | Defines seccomp profile (`RuntimeDefault`, `Unconfined`, etc.).     |
| `appArmorProfile.type`     | ✅ Pod & ✅ Container  | Specifies AppArmor profile to apply (usually only on supported OS). |
| `seLinuxOptions.level`     | ✅ Pod & ✅ Container  | Sets SELinux context for more fine-grained control.                 |

---

### 🎯 Summary

| Scope              | Fields                                                                             |
| ------------------ | ---------------------------------------------------------------------------------- |
| **Pod Only**       | `fsGroup`, `fsGroupChangePolicy`, `supplementalGroups`, `supplementalGroupsPolicy` |
| **Container Only** | `capabilities`, `allowPrivilegeEscalation`, `privileged`, `readOnlyRootFilesystem`                                           |
| **Both**           | `runAsUser`, `runAsGroup`, `runAsNonRoot`, `seccompProfile`, `appArmorProfile`, `seLinuxOptions`   |

