## Q1

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

---

## Q2

You're asked to extract the following information out of kubeconfig file `/opt/course/1/kubeconfig` on cka9412:
- Write all kubeconfig **context names** into  `/opt/course/1/contexts` , one per line
- Write the **name of the current context** into `/opt/course/1/current-context`
- Write the **client-certificate** of user **account-0027** *base64-decoded* into `/opt/course/1/cert`

Here’s how you can solve this step by step in your CKA lab environment:

### 1. **Write all kubeconfig context names into `/opt/course/1/contexts`**

```bash
kubectl config get-contexts --kubeconfig=/opt/course/1/kubeconfig -o name > /opt/course/1/contexts
```

This extracts just the context names (one per line).


### 2. **Write the name of the current context into `/opt/course/1/current-context`**

```bash
kubectl config current-context --kubeconfig=/opt/course/1/kubeconfig > /opt/course/1/current-context
```

### 3. **Write the client-certificate of user `account-0027` base64-decoded into `/opt/course/1/cert`**

The certificate is stored under the `users` section of the kubeconfig file. Extract and decode it:

```bash
kubectl config view --kubeconfig=/opt/course/1/kubeconfig -o jsonpath='{.users[?(@.name=="account-0027")].user.client-certificate-data}' \
  | base64 -d > /opt/course/1/cert
```

---

  
