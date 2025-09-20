
```bash
controlplane:~$ k get no
E0827 21:54:12.115955   47329 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://172.30.1.2:644333/api?timeout=32s\": dial tcp: address 644333: invalid port"
Unable to connect to the server: dial tcp: address 644333: invalid port

controlplane:~$ vi .kube/config     # edit it to 6443
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   8d    v1.33.2
node01         Ready    <none>          8d    v1.33.2
```
