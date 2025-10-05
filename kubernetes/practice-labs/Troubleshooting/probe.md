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

