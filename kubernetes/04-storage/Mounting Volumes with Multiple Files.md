# 📘 Notes: Mounting Volumes with Multiple Files

## 🔹 ConfigMap/Secret Volumes

* A ConfigMap or Secret can contain **multiple key-value pairs**, each key → a file.
* When mounted as a **volume**:

  * By default → **all keys** become files inside the mounted directory.
  * If you only want a **specific key (file)**:

    * Use `subPath` → maps a single key to a file at the given `mountPath`.

👉 Example:

```yaml
volumeMounts:
  - name: cm-vol
    mountPath: /etc/config         # Mount full ConfigMap directory
  - name: cm-vol
    mountPath: /etc/app/config.yaml
    subPath: app-config.yaml       # Mount only this key
```

---

## 🔹 General Rule (applies to all Volumes)

* **Mount directory** → when you need all contents (multiple files/keys).
* **Mount with subPath** → when you need just one file or want to avoid overwriting existing directory.

---

## 🔹 Why use subPath?

* Prevents overwriting default dirs (e.g., `/etc/nginx/nginx.conf`).
* Lets you map one ConfigMap/Secret key into a specific file location.
* Works with any volume type (ConfigMap, Secret, EmptyDir, HostPath, PVC).

---

✅ **Shortcut Rule for Exam:**

* **No `subPath` → whole directory mounted.**
* **With `subPath` → single file/key mounted.**
