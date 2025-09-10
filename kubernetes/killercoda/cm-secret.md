Create a ConfigMap named ckad04-config-multi-env-files-aecs in the default namespace from the environment(env) files provided at /root/ckad04-multi-cm directory.

```bash
root@student-node ~ ➜  kubectl create configmap ckad04-config-multi-env-files-aecs \
         --from-env-file=/root/ckad04-multi-cm/file1.properties \
         --from-env-file=/root/ckad04-multi-cm/file2.properties
configmap/ckad04-config-multi-env-files-aecs created

root@student-node ~ ➜  ls /root/ckad04-multi-cm/
file1.properties  file2.properties

root@student-node ~ ➜  k describe cm ckad04-config-multi-env-files-aecs 
Name:         ckad04-config-multi-env-files-aecs
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
difficulty:
----
fairlyEasy

exam:
----
ckad

modetype:
----
openbook

practice:
----
must

retries:
----
2

allowed:
----
true


BinaryData
====

Events:  <none>

root@student-node ~ ➜  
```
