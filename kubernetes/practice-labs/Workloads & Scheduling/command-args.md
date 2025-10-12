# Commands and Arguments

## Q1 

Write `Hello from KodeKloud!` into a running nginx server at its root folder.

> **NOTE:** By default NGINX web server default location is at `/usr/share/nginx/html` which is located on the default file system of the Linux.

```bash
root@student-node ~ ✖ k exec -n ckad-pod-design basic-nginx -it -- sh
# echo "Hello from KodeKloud!" > /usr/share/nginx/html.index.html
# cat /usr/share/nginx/html.index.html
Hello from KodeKloud!
# exit
```

---

## Q2

Create a pod named `time-check` in the `dvl1987` namespace. This pod should execute a container called `time-check` using the busybox image.

Create a ConfigMap named `time-config` with the data `TIME_FREQ=10` in the same namespace.
The `time-check` container must run the command: `while true; do date; sleep $TIME_FREQ; done`, directing the output to the file located at `/opt/time/time-check.log`.
Ensure that the path `/opt/time` within the pod mounts a volume that persists for the duration of the pod's lifecycle.

```bash

controlplane ~ ➜  vi 3.yaml

controlplane ~ ➜  k replace -f 3.yaml --force
pod "time-check" deleted
pod/time-check replaced

controlplane ~ ➜  k get po -n dvl1987 
NAME         READY   STATUS    RESTARTS   AGE
time-check   1/1     Running   0          8s

controlplane ~ ➜  k logs -n dvl1987 time-check 

controlplane ~ ➜  cat 3.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: time-check
  namespace: dvl1987
spec:
  containers:
  - name: time-check
    image: busybox
    command: ["sh", "-c"]
    args:
      - while true; do date >> /opt/time/time-check.log; sleep $TIME_FREQ; done      # >> not >
    envFrom:
      - configMapRef:
          name: time-config
    volumeMounts:
      - name: time-storage
        mountPath: /opt/time
  volumes:
    - name: time-storage
      emptyDir: {}
  restartPolicy: Always

controlplane ~ ➜  k logs -n dvl1987 time-check 

controlplane ~ ➜  kubectl exec -n dvl1987 -it time-check -- cat /opt/time/time-check.log
Mon Oct  6 11:38:18 UTC 2025

controlplane ~ ➜  
```

## AI-Assisted Troubleshooting & Explanations

Perfect execution, sweetheart ❤️ — you’ve done everything *almost* right, but the reason you see **no output from `kubectl logs`** is actually expected in this case. Let me explain what’s happening clearly 👇

### 🧩 Why `kubectl logs` shows nothing

Your container runs this command:

```bash
while true; do date >> /opt/time/time-check.log; sleep $TIME_FREQ; done
```

Notice that you’re **redirecting output to a file** (`/opt/time/time-check.log`) — not to stdout.

Kubernetes’ `kubectl logs` command only shows **stdout** and **stderr** output from containers, not the content written into files inside the container filesystem.

So, your container *is* running correctly — it’s just writing the logs to that file inside the pod, not to the logs stream.

### ✅ To verify it’s really working

Run this command:

```bash
kubectl exec -n dvl1987 -it time-check -- cat /opt/time/time-check.log
```

You should see something like:

```
Mon Oct  6 11:38:01 UTC 2025
...
```

If you see the timestamps — congratulations 🎉 it’s working perfectly.

### 💡 (Optional Improvement)

If you want to *also* see output via `kubectl logs`, you can modify your command like this:

```yaml
args:
  - while true; do date | tee -a /opt/time/time-check.log; sleep $TIME_FREQ; done
```

* `tee -a` appends output both to the log file **and stdout**
* So `kubectl logs` will now show the same output that’s being written to `/opt/time/time-check.log`.

---
