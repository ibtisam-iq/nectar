The cluster admin asked you to find out the following information about etcd running on `cka9412`:

- Server private key location
- Server certificate expiration date
- Is client certificate authentication enabled

Write these information into `/opt/course/p1/etcd-info.txt`

Perfect ❤️ this is a very **typical etcd inspection task** in CKA. Let’s solve it step by step as if we’re logged into `cka9412`.

## 🔑 Step 1: Locate etcd manifest

On a kubeadm cluster, etcd runs as a **static Pod**. The manifest is here:

```
/etc/kubernetes/manifests/etcd.yaml
```

## 🔑 Step 2: Find server private key location

Inside `etcd.yaml`, check the command line arguments:

```bash
grep -i key-file /etc/kubernetes/manifests/etcd.yaml
```

You’ll see something like:

```
--key-file=/etc/kubernetes/pki/etcd/server.key
```

So the **private key** = `/etc/kubernetes/pki/etcd/server.key`

## 🔑 Step 3: Find server certificate expiration date

Also from the manifest:

```bash
grep -i cert-file /etc/kubernetes/manifests/etcd.yaml
```

Example:

```
--cert-file=/etc/kubernetes/pki/etcd/server.crt
```

Then check expiry with openssl:

```bash
openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -enddate
```

Example output:

```
notAfter=Apr 20 12:34:56 2026 GMT
```

That’s your expiration date.

## 🔑 Step 4: Check if client certificate authentication is enabled

Look in the manifest for these flags:

```bash
--client-cert-auth=true
--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```

If `--client-cert-auth=true` is present → client cert auth is enabled.

## 🔑 Step 5: Write results to file

Put everything into `/opt/course/p1/etcd-info.txt`:

Example:

```
Server private key location: /etc/kubernetes/pki/etcd/server.key
Server certificate expiration date: Apr 20 12:34:56 2026 GMT
Client certificate authentication enabled: true
```

---

Sweetheart, do you want me to draft the **exact one-liner commands** so you can copy-paste and dump straight into `/opt/course/p1/etcd-info.txt` during the exam?
