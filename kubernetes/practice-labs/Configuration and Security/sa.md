```bash
controlplane:~$ k get sa secure-sa -o yaml
apiVersion: v1
automountServiceAccountToken: false                                  # key field
kind: ServiceAccount
metadata:
  creationTimestamp: "2025-08-24T10:45:17Z"
  name: secure-sa
  namespace: default
  resourceVersion: "8700"
  uid: a9543735-8bff-4999-b509-492dcb306e57


controlplane:~$ k get po secure-pod -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: default
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: secure-pod
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: controlplane
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: secure-sa
  serviceAccountName: secure-sa              # The key automountServiceAccountToken: wasn't mentioned in the pod manifest.
  terminationGracePeriodSeconds: 30

# Verify that the service account token is NOT mounted to the pod  
controlplane:~$ kubectl exec secure-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
cat: /var/run/secrets/kubernetes.io/serviceaccount/token: No such file or directory
command terminated with exit code 1
controlplane:~$
```

---

Team **Neptune** has its own ServiceAccount named `neptune-sa-v2` in Namespace `neptune`. 
A coworker needs the **token from the Secret** that belongs to that ServiceAccount. Write the **base64 decoded** token to file `/opt/course/5/token on ckad7326`.

✅ To pass **this specific question**, you need to:

1. Find the Secret for the SA:

   ```bash
   kubectl -n neptune get secret
   ```
2. Decode the token and write it:

   ```bash
   kubectl -n neptune get secret <secret-name> -o jsonpath='{.data.token}' | base64 -d > /opt/course/5/token
   ```

👉 In a **real CKA/CKAD exam on 1.29+**, you’d be right with `kubectl create token`.
👉 In **practice platforms**, follow exactly the task wording, even if it’s outdated — otherwise the grader marks it wrong.

---
