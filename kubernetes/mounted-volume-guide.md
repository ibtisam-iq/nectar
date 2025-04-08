# 🔍 What Is a "Mounted Volume"?

In Linux (and in Kubernetes), a **mounted volume** refers to **external storage** (like a directory or disk) that gets **attached** to a specific location in the container’s filesystem — sort of like "plugging in a USB drive" and seeing it appear under `/mnt/usb` or `/media`.

In Kubernetes, mounted volumes are used to:

- Persist data (even after the Pod is deleted)
- Share data between containers
- Inject configuration (like ConfigMaps, Secrets, etc.)

---

### 🧠 Real Analogy

Imagine a blank house. You bring a cabinet (volume) and place it inside the house’s kitchen (mountPath). Now, anything you store in that cabinet is persistent **because it’s not part of the house itself — it's your external cabinet**.

---

## 🔧 Example: Mounted Volume in Kubernetes

Let’s say your Pod has a volume mounted like this:

```yaml
volumeMounts:
  - name: demo-volume
    mountPath: /data
volumes:
  - name: demo-volume
    emptyDir: {}
```

This means:
📦 A temporary volume (emptyDir) is created and mounted into the container's `/data` folder.

Now, when the container writes files into `/data`, it's writing them into the mounted volume.

---

## 🛡️ Where `fsGroup` Comes In

By default, when the container writes files into `/data`, they are owned by the **user** running the container (say UID 1000), and group might be root or unset.

But if you define this in your Pod's `securityContext`:

```yaml
securityContext:
  fsGroup: 2000
```

Then Kubernetes **automatically changes the group ownership** of all files created **inside mounted volumes** (like `/data`) to GID 2000.

---

## 🔍 Visual Example

Imagine your container creates a folder inside `/data`:

```bash
mkdir /data/demo
ls -l /data
```

### Without `fsGroup`:
```bash
drwxr-xr-x 2 1000 root 4096 Apr 8 18:30 demo
```
👎 Group is root (not ideal for sharing)

### With `fsGroup: 2000`:
```bash
drwxrwsrwx 2 1000 2000 4096 Apr 8 18:30 demo
```
👍 Now the group is set to **2000**, as expected

---

## 🧠 Why Is This Important?

In multi-user environments or permission-sensitive apps, group ownership matters:

- Apps might expect files to be owned by a certain group.
- Security policies may restrict which group can access files.
- Shared access among containers may require group coordination.

So setting `fsGroup` helps **ensure correct access control** over mounted storage.

---

## 🧪 Summary

| Term         | What It Does                                             | Where It Applies                                 |
|--------------|----------------------------------------------------------|--------------------------------------------------|
| `fsGroup`    | Sets group ownership of files inside **mounted volumes** | Affects storage like `emptyDir`, `hostPath`, PVCs, etc. |
| `runAsUser`  | Sets the UID for processes in container                  | Affects who owns the running processes           |
| `runAsGroup` | Sets the GID for processes in container                  | Affects primary group of the process             |


