## 🔍 What is `fsGroup`?

In Linux, every **file and directory** has:

- An **owner** (`user`)
- A **group**
- A set of **permissions**

When a process **creates files**, they usually belong to:

- The **user ID (UID)** of the process (`runAsUser`)
- The **group ID (GID)** of the process

But in Kubernetes, **files created inside mounted volumes** (especially **shared volumes**, like `emptyDir`, `hostPath`, `PVCs`, etc.) may need to be **shared** across different containers **or** applications.

This is where `fsGroup` comes in:

---

## 💡 `fsGroup` in Kubernetes: The Analogy

🧠 Think of `fsGroup` as a **"shared group owner"** for all volume-mounted files.

> 🔧 **Definition**: When you set `fsGroup`, Kubernetes will:
>
> 1. Change the **group ownership** of **mounted volumes** to the given GID (e.g., 2000),
> 2. Ensure **new files created in these volumes** are **owned by that group** (so other processes with the same group can read/write).

---

## 📂 Real Example Walkthrough

### Let's say you run a Pod like this:

```yaml
securityContext:
  runAsUser: 1000
  fsGroup: 2000
```

This means:

- The process inside the container will run as **user 1000**
- Volumes mounted in the Pod will have **group ownership of 2000**

Now imagine a volume like this:

```yaml
volumes:
  - name: data
    emptyDir: {}
```

And the container writes to `/data/demo`.

### 🔍 Inside the container

Now, you run the following commands inside the pod:

```bash
ps aux          # check running process UID
id              # check UID and GID of current process
ls -l /data     # check ownership of directory
```

### 🧾 Output

```bash
$ ps aux
USER       PID COMMAND
1000         1 sleep 1h      <-- process runs as user 1000

$ id
uid=1000 gid=1000 groups=1000,2000  <-- also belongs to fsGroup (2000)

$ ls -ld /data
drwxrwsrwx 2 root 2000 4096 Apr 8 20:08 demo
               ^     ^    ^
             owner  group  (group ID 2000 assigned by fsGroup)
```

Here:

- The directory `/data/demo` is **owned by root**, but its **group is 2000**
- This allows any other container/user **with group ID 2000** to **read/write** it
- Even if the process runs as `runAsUser: 1000`, it can still write because it’s part of the group `2000`

---

## 🧪 What if I **don’t set** `fsGroup`?

Then:

- Mounted volumes keep their default permissions (usually `root:root`)
- Your app may not have permission to write if it runs as a non-root user

That’s why `fsGroup` is important for:

- Multi-container pods
- Non-root security policies
- Shared volumes

---

## 🔐 Bonus: Sticky Bit Behavior

If the mounted directory has `rwxrwsrwx` permissions (with `s`), it means:

- Files created inside it **inherit** the group ID (`fsGroup`) automatically

This is why Kubernetes sets `drwxrwsrwx` (notice the `s` in group permissions).

---

## 📦 Summary

| Concept      | Meaning                                                        |
|--------------|----------------------------------------------------------------|
| `runAsUser`  | The UID the container process runs as                         |
| `fsGroup`    | The GID applied to mounted volumes and new files              |
| Ownership    | Volume contents will show group = `fsGroup`                   |
| Use Case     | Share volume data across containers running as different users|
| Common GID   | Helps containers in same pod cooperate on files via group ownership |

