```bash
set expandtab
set tabstop=2
set shiftwidth=2
```
---
```bash
watch crictl ps     #  kube-apiserver pod is not found
controlplane:~$ ls /var/log/pods/kube-system_kube-apiserver-controlplane_e3fce191b74711a772350e45757b9c50/kube-apiserver/
0.log  1.log        #  no update here, because pod is not created yet
controlplane:~$ cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-ace5309febe6b93e42a1d04d055bc4025b85d8511ddcd1aa83a995129c3c
c03c.log 
2025-08-23T08:26:41.615226434Z stderr F Error: unknown flag: --this-is-very-wrong
```
---

