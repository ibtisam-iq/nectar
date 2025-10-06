## Q1

```bash
controlplane:~$ k describe po space-alien-welcome-message-generator-b7fc8494b-gj2vq 
Name:             space-alien-welcome-message-generator-b7fc8494b-gj2vq
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Warning  Unhealthy  4s (x8 over 34s)  kubelet            Readiness probe failed: stat: can't stat '/tmp/healthy': No such file or directory

## solution 1
Update the container args so each command is properly separated:

args:
  - /bin/sh
  - -c
  - touch /tmp/ready; sleep 30; rm -f /tmp/ready; sleep 600

## solution 2
k get pod # use pod name
k exec space-alien-welcome-message-generator-5c945bc5f9-m9nkb -- touch /tmp/ready
```

---

## Q2

Nice one, sweetheart ❤️ — you’re analyzing the pod YAML correctly.
Let’s go through this in depth and see **why your pod is “Running” but not “Ready.”**

### 🧠 Problem Summary

Your pod `nginx1401` in namespace `dev1401` is:

```
STATUS: Running
READY: 0/1
```

and the condition says:

```
message: 'containers with unready status: [nginx]'
reason: ContainersNotReady
```

That means:

* The container started successfully ✅
* But the **readiness probe failed** ❌

### 🔍 Root Cause

Your **readiness probe** is configured incorrectly:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
```

However, your **containerPort** is defined as:

```yaml
ports:
- containerPort: 9080
```

💥 So the probe is trying to connect to **port 8080**, but the NGINX container is listening on **port 80 (default)** — not 8080 or 9080.

That’s why the readiness probe never succeeds.

### ✅ How to Fix It

You have **two correct options**, depending on what you want:

#### Option 1: Simplest Fix (recommended)

Update both `containerPort` and the readiness probe port to **80**:

```yaml
ports:
- containerPort: 80
readinessProbe:
  httpGet:
    path: /
    port: 80
```

#### Option 2: If your NGINX image listens on a custom port (like 9080)

Then update the probe port to match:

```yaml
ports:
- containerPort: 9080        
readinessProbe:
  httpGet:
    path: /
    port: 9080              # do change here
```

Either way, **the probe’s port and the container’s actual listening port must match**.


---

## Q3

Add a check to restart the container on the same pod if the command `ls /var/www/html/file_check` fails. This check should start after a delay of `10` seconds and run every `60` seconds.

```yaml
# The kubelet uses liveness probes to know when to restart a container.
livenessProbe:
      exec:
        command:
        - ls
        - /var/www/html/file_check
      initialDelaySeconds: 10
      periodSeconds: 60
```
