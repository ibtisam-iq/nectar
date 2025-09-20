
- `/var/log/pods`
- `/var/log/containers`
- `crictl ps` + `crictl logs`
- `docker ps` + `docker logs` (in case when Docker is used)
- kubelet logs: `/var/log/syslog` or `journalctl`
```bash
journalctl | grep apiserver
cat /var/log/syslog | grep apiserver
```
---

## vim setup
```bash
set expandtab
set tabstop=2
set shiftwidth=2
```
---
