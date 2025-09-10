```bash
root@student-node ~ ➜  k describe svc route-apd-svc
Name:                     route-apd-svc
Labels:                   app=route-apd-svc
Selector:                 version=v1         # one label, which shares between 2 pods, so it routed the traffic to both pods.
Type:                     NodePort

Endpoints:                172.17.1.5:8080,172.17.1.7:8080    # 2 pods

root@student-node ~ ➜  k get po -o wide --show-labels
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE                 LABELS
blue-apd-5ffd7768b8-lt2jj    1/1     Running   0          17m     172.17.1.5    cluster3-node01      type-one=blue,version=v1
green-apd-84bb78c876-k9bnr   1/1     Running   0          12m     172.17.1.7    cluster3-node01      type-two=green,version=v1
```
---

Create two environment variables for the above pod with below specifications:
`GREETINGS` with the data from configmap `ckad02-config1-aecs`

```bash
env:                                # not envFrom, it doesn't support key value.
      - name: GREETINGS
        valueFrom:
          configMapKeyRef:
            key: greetings.how
            name: ckad02-config1-aecs
```
