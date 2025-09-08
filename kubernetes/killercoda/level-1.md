
## Q 10
Create a pod called time-check in the nautilus namespace. The pod should contain a container named time-check, utilizing the busybox image with the latest tag (specify as busybox:latest).

Create a config map named time-config with the data TIME_FREQ=10 in the same namespace.

Configure the time-check container to execute the command: while true; do date; sleep $TIME_FREQ;done. Ensure the result is written /opt/dba/time/time-check.log. Also, add an environmental variable TIME_FREQ in the container, fetching its value from the config map TIME_FREQ key.

Create a volume log-volume and mount it at /opt/dba/time within the container.

```bash
thor@jumphost ~$ k get po -n nautilus 
NAME         READY   STATUS    RESTARTS   AGE
time-check   1/1     Running   0          8s
thor@jumphost ~$ cat /tmp/kubectl-edit-3729583849.yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
# pods "time-check" was not valid:
# * <nil>: Invalid value: "The edited file failed validation": yaml: line 19: could not find expected ':'
#
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: time-check
  name: time-check
  namespace: nautilus
spec:
  containers:
  - image: busybox:latest
    imagePullPolicy: Always
    name: time-check
    command:
    - sh
    - -c 
    - while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ;done
    envFrom:
    - configMapRef:
        name: time-config
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-tnwt6
      readOnly: true
    - mountPath: /opt/dba/time
      name: log-volume
  volumes:
  - name: log-volume
    emptyDir: {}
  - name: kube-api-access-tnwt6
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
thor@jumphost ~$ 
```

Thanks for sharing the full YAML 🙌.
The root cause is this part:

```yaml
args:
- while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ;done
```
👉 Kubernetes treats that whole string as a **binary to execute**, but `while true; do ...` is a shell loop, not an executable.
That’s why you see:

```
exec: "while true; do date ...": no such file or directory
```

### ✅ Fix

Wrap your script inside a shell:

```yaml
args:
- sh
- -c
- while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ; done
```

---
