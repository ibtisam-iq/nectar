## Kube Controller Manager

### kube-controller-manager-controlplane restarting...

```bash
controlplane ~ ➜  k get po -n kube-system kube-controller-manager-controlplane 
NAME                                   READY   STATUS             RESTARTS      AGE
kube-controller-manager-controlplane   0/1     CrashLoopBackOff   3 (19s ago)   52s

controlplane ~ ➜  k logs -n kube-system kube-controller-manager-controlplane    # clue indetified
Usage:
  kube-controller-manager [flags]
...
Error: unknown flag: --project-sidecar-insertion

controlplane ~ ➜  crictl ps -a | grep kube-controller-manager                    # increase in Attempt is found
8840e8fcbfc5b       a0af72f2ec6d6       About a minute ago   Exited              kube-controller-manager   6                  
controlplane ~ ➜  crictl logs 8840e8fcbfc5b                            # same as k logs <>
Usage:
  kube-controller-manager [flags]
...
Error: unknown flag: --project-sidecar-insertion

controlplane ~ ➜  journalctl -f | grep kube-controller-manager     # no clue
Oct 05 07:52:09 controlplane kubelet[77740]: E1005 07:52:09.236089   77740 pod_workers.go:1324] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kube-controller-manager\" with CrashLoopBackOff: \"back-off 5m0s restarting failed container=kube-controller-manager pod=kube-controller-manager-controlplane_kube-system(9de38e335353dd7b6fea1eb122273ebd)\"" pod="kube-system/kube-controller-manager-controlplane" podUID="9de38e335353dd7b6fea1eb122273ebd"
```

---

## Wrong Command

`video-app` deployment replicas **0**. fix this issue

**expected:** 2 replicas

```bash
controlplane:~$ k get po -A
NAMESPACE            NAME                                      READY   STATUS             RESTARTS      AGE
kube-system          kube-controller-manager-controlplane      0/1     CrashLoopBackOff   1 (4s ago)    6s

controlplane:~$ k describe po -n kube-system kube-controller-manager-controlplane 
Name:                 kube-controller-manager-controlplane
Namespace:            kube-system
    Command:
      kube-controller-manegaar
    State:          Waiting
      Reason:       RunContainerError
    Last State:     Terminated
      Reason:       StartError
      Message:      failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "kube-controller-manegaar": executable file not found in $PATH: unknown
      Exit Code:    128
      Started:      Thu, 01 Jan 1970 00:00:00 +0000
      Finished:     Wed, 27 Aug 2025 23:31:22 +0000
    Ready:          False
    Restart Count:  2
Events:
  Type     Reason   Age               From     Message
  ----     ------   ----              ----     -------

  Warning  Failed   3s (x3 over 27s)  kubelet  Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "kube-controller-manegaar": executable file not found in $PATH: unknown
  Warning  BackOff  3s (x5 over 25s)  kubelet  Back-off restarting failed container kube-controller-manager in pod kube-controller-manager-controlplane_kube-system(c2086dde319f21250262f5d5edcf3af3)

controlplane:~$ k edit po -n kube-system kube-controller-manager-controlplane 
Edit cancelled, no changes made.
controlplane:~$ vi /etc/kubernetes/manifests/kube-controller-manager.yaml 
controlplane:~$ systemctl restart kubelet
controlplane:~$ k get po -A
NAMESPACE            NAME                                      READY   STATUS    RESTARTS      AGE
kube-system          kube-controller-manager-controlplane      1/1     Running   0             56s
controlplane:~$ k get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
video-app   2/2     2            2           4m18s
controlplane:~$ 
```
---

```bash
controlplane ~ ✖ crictl ps -a | grep controller
fea14951ca5e6       1d579cb6d6967       21 seconds ago      Exited              kube-controller-manager   6                   

controlplane ~ ➜  crictl logs fea14951ca5e6
I1007 19:50:51.423712       1 serving.go:386] Generated self-signed cert in-memory
E1007 19:50:51.803107       1 run.go:72] "command failed" err="unable to load client CA provider: open /etc/kubernetes/pki/ca.crt: no such file or directory"

controlplane ~ ➜  ls -l /etc/kubernetes/pki/ca.crt
-rw-r--r-- 1 root root 1107 Oct  7 19:30 /etc/kubernetes/pki/ca.crt

controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-controller-manager.yaml 
apiVersion: v1
kind: Pod

  volumes:

  - hostPath:
      path: /etc/kubernetes/WRONG-PKI-DIRECTORY  # Problem
      type: DirectoryOrCreate
    name: k8s-certs

controlplane ~ ➜  
```

Excellent observation, sweetheart ❤️ — this is one of those subtle Kubernetes control plane debugging cases that often show up in CKA-style troubleshooting questions.

Let’s analyze it carefully 👇

### 🔍 The error:

```
E1007 19:50:51.803107       1 run.go:72] "command failed" err="unable to load client CA provider: open /etc/kubernetes/pki/ca.crt: no such file or directory"
```

Yet when you check on the host:

```
ls -l /etc/kubernetes/pki/ca.crt
-rw-r--r-- 1 root root 1107 Oct  7 19:30 /etc/kubernetes/pki/ca.crt
```

The file **exists** on the host.
So why does the container say **no such file or directory**?

### 🎯 Root cause

The process that’s logging this error (inside the container with ID `fea14951ca5e6`) is **running in a container** — typically one of the static control plane pods (like `kube-apiserver`, `kube-controller-manager`, etc.).

These containers **don’t automatically see** the host’s `/etc/kubernetes/pki` path **unless it’s explicitly mounted** as a volume.

So the problem is almost certainly:

> The host path `/etc/kubernetes/pki` is **not mounted** into the container (or mounted incorrectly).

### 💡 Summary

Kubernetes components (like the API server) run **inside containers** managed by `kubelet`.
They **don’t directly read host files** unless you explicitly share them using a **hostPath volume**.
So even though `/etc/kubernetes/pki/ca.crt` exists on the host, the container will see “file not found” unless that directory is mounted in.

---
