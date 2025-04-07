# `kubectl` Command and Args Overriding Guide

## 📘 Introduction

When using `kubectl run` or `kubectl create cronjob`, it's crucial to understand how to control **what gets executed inside the container**. This is achieved using:

- `--` to separate Kubernetes CLI options from what runs in the container.
- `--command` to explicitly override the default `ENTRYPOINT`.

This guide explains how Kubernetes handles commands and arguments using examples, breaking it down intellectually and practically.

---

## 🧠 Key Concepts

### 1. The Anatomy of a `kubectl` Command

```bash
kubectl run NAME --image=IMAGE [--command] -- [COMMAND] [args...]
```

| Section         | Role                                                                 |
|-----------------|----------------------------------------------------------------------|
| `--image`       | Specifies the container image.                                       |
| `--`            | Separates `kubectl` options from what's passed to the container.     |
| `[--command]`   | Tells Kubernetes to override the image's default command (ENTRYPOINT).|
| `[COMMAND]`     | The new command to run in the container.                             |
| `[args...]`     | Arguments passed to the command.                                     |

---

## 🔍 Behavior Summary

| Scenario                           | `command` field     | `args` field         |
|------------------------------------|----------------------|----------------------|
| `--` (no `--command`)              | *Uses image default* | Everything after `--` |
| `--command -- [cmd] [args...]`     | Explicitly set to `[cmd]`              | Explicitly set to `[args...]`          |

---

## 🔧 Use Cases with Examples

---

### 🔹 1. Only Overriding `args` (Retain Default Command)

```bash
kubectl run nginx --image=nginx -- -g "daemon off;"
```

- ✅ Correct Usage: `--command` is **not** used.
- 🔍 Behavior: Uses the image's default command (`nginx`), and overrides the args.

📄 YAML Equivalent:
```yaml
command: null  # (Default ENTRYPOINT from image)
args: ["-g", "daemon off;"]
```

---

### 🔹 2. Overriding Both Command and Args

```bash
kubectl run mypod --image=busybox --command -- echo "Hello from BusyBox"
```

- ✅ Correct Usage: `--command` is used.
- 🔍 Behavior: Overrides default command with `echo` and passes `"Hello from BusyBox"` as args.

📄 YAML Equivalent:
```yaml
command: ["echo"]
args: ["Hello from BusyBox"]
```

---

### 🔹 3. Using Shell Logic with `sh -c`

```bash
kubectl run shellpod --image=busybox --command -- sh -c "echo Hello && date"
```

- ✅ Correct Usage: `--command` is used.
- 🔍 Behavior:
  - Command: `sh`
  - Args: `-c "echo Hello && date"`

📄 YAML Equivalent:
```yaml
command: ["sh"]
args: ["-c", "echo Hello && date"]
```

---

### 🔹 4. Running Python Inline

```bash
kubectl run pyjob --image=python:3.9 --command -- python -c "print('Hello')"
```

📄 YAML Equivalent:
```yaml
command: ["python"]
args: ["-c", "print('Hello')"]
```

---

## 🧪 Test Case Comparison

### Case A: Without `--command`

```bash
kubectl run test --image=busybox -- echo "Hi"
```

🔍 Behavior:

- Command: Defaults to image's `ENTRYPOINT` (e.g., `sh`)
- Args: `["echo", "Hi"]`

📄 YAML:
```yaml
command: null
args: ["echo", "Hi"]
```

---

### Case B: With `--command`

```bash
kubectl run test --image=busybox --command -- echo "Hi"
```

🔍 Behavior:

- Command: `["echo"]`
- Args: `["Hi"]`

📄 YAML:
```yaml
command: ["echo"]
args: ["Hi"]
```

---

## 🛠️ How Kubernetes Handles This Internally

- Docker images define:
  - `ENTRYPOINT` (→ Kubernetes `command`)
  - `CMD` (→ Kubernetes `args`)
- `--command` **replaces ENTRYPOINT**
- `--` passes everything after it to container
- Use `--command` if you want full control

---

## 🤩 Final Summary

| Purpose                          | Syntax                                                     | Effect                                                   |
|----------------------------------|-------------------------------------------------------------|----------------------------------------------------------|
| Override only args               | `kubectl run pod --image=img -- <args>`                    | Keeps default command, replaces arguments                |
| Override command and args        | `kubectl run pod --image=img --command -- <cmd> <args>`    | Replaces both command and arguments                      |
| Separate container config        | Use `--` between kubectl options and container commands     | Ensures correct parsing                                  |
| Pass shell scripts               | `--command -- sh -c "<script>"`                            | Runs complex logic inside container                      |

---

## 🚀 Bonus: `kubectl create cronjob` Example
```sh
kubectl create cronjob my-cronjob --image=busybox --schedule="*/5 * * * *" -- echo "Hello, Kubernetes!"
```

**What happens?**
The `busybox` container runs `echo "Hello, Kubernetes!"` every 5 minutes.

**Explanation:**

- **COMMAND**: Since the `--command` flag is **not** used, the container will use the **default command** defined in the `busybox` image, which is typically `sh` (the shell).

- **args**: The arguments provided (`"Hello, Kubernetes!"`) will be passed to the default shell (`sh`). The shell will execute `echo "Hello, Kubernetes!"` inside the container.

By passing arguments after `--`, you're effectively overriding the default behavior by passing them to the shell.

**YAML Equivalent:**

To mimic this behavior in YAML, since `sh` is the default command, you don't need to set `command`. You only need to specify the `args` that the shell will execute.

**YAML Equivalent:**
```yaml
spec:
  containers:
    - name: busybox
      image: busybox
      args: ["echo", "Hello, Kubernetes!"]
```
In this case:

- The **default command** (`sh`) is still used.

- The **args** are passed to `sh`, so `sh` will run `echo "Hello, Kubernetes!"` inside the container.

> ❗ Important: `kubectl create cronjob` does not support implicit `[COMMAND] [args...]` like `kubectl run` does. You **must** use `--command --` to override the entrypoint.

**❌ Incorrect:**
```sh
kubectl create cronjob myjob --image=busybox --schedule="*/5 * * * *" -- echo "Hi"
```
> "`echo` is treated as an argument to the image’s default command (likely `sh`), rather than replacing the command itself."

**✅ Correct: Use `--command --`**
```bash
kubectl create cronjob myjob --image=busybox --schedule="*/1 * * * *" --command -- echo "Hello from cron!"
```

📄 YAML Snippet:
```yaml
spec:
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: myjob
              image: busybox
              command: ["echo"]
              args: ["Hello from cron!"]
```

---

## ✅ Best Practices

- Use `--command` only if you want to override the default `ENTRYPOINT`.
- Always add `--` to separate `kubectl` options from container commands.
- When in doubt, inspect the image with `docker inspect <image>` to check `ENTRYPOINT` and `CMD`.

