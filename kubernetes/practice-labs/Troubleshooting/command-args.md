## Q1 wrong command

```bash
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------

  Warning  Failed     10s (x2 over 11s)  kubelet            Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "shell": executable file not found in $PATH: unknown
  Warning  BackOff    9s (x2 over 10s)   kubelet            Back-off restarting failed container echo-container in pod hello-kubernetes_default(547408a1-1adb-44eb-bee2-b2bbfa1d0449)

spec:
  containers:
  - command:
    - shell                  # sh not shell
    - -c
    - while true; do echo 'Hello Kubernetes'; sleep 5; done
```

---

## Q2

```bash
E0912 10:41:23.738713       1 run.go:72] "command failed" err="stat /etc/kubernetes/scheduler.config: no such file or directory" # wrong arg
```
