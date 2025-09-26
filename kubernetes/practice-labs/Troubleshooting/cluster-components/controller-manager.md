## Kube Controller Manager


### kube-controller-manager-controlplane restarting...

```bash
crictl logs 9cef2cf7061d6  # no clue
cat /var/log/syslog | grep kube-controller-manager # no clue
journalctl | grep kube-controller-manager
cat /var/log/containers/kube-controller-manager-controlplane_kube-system_kube-controller-manager-d559f74bec79087e6e77a69ff8a9c42f46c4666b7310898f2132eea9b6e72dce.log
2025-08-23T13:10:02.535173834Z stderr F Error: unknown flag: --project-sidecar-insertion
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
