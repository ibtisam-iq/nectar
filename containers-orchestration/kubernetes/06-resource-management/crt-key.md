If you want the TLS for domain **ibtisam-iq.com**, you can **generate a self-signed certificate** and key with OpenSSL using the domain as the “Common Name (CN)”. Then you use those in your Kubernetes Secret and Ingress/Gateway resources.

Here’s how to do it:

---

## 1. Generate `tls.crt` and `tls.key` for `ibtisam-iq.com`

Run this command (on your local machine / terminal):

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=ibtisam-iq.com"
```

* `-x509` = generate a self-signed certificate
* `-nodes` = no passphrase on the key
* `-days 365` = valid for one year
* `-newkey rsa:2048` = generate a new 2048-bit RSA key
* `-keyout tls.key` = output private key file
* `-out tls.crt` = output certificate file
* `-subj "/CN=ibtisam-iq.com"` = set the common name to your domain

After this command, you will have two files:

* `tls.crt` — the certificate
* `tls.key` — the private key

---

## 2. Create a Kubernetes TLS secret with those files

Use `kubectl create secret tls`:

```bash
kubectl create secret tls demo-tls --cert=tls.crt --key=tls.key -n migrate-demo
```

This will create a Secret of type `kubernetes.io/tls` in namespace `migrate-demo` with keys `tls.crt` and `tls.key`.

---

## 3. Use that secret in your Ingress / Gateway manifests

In your Ingress spec you would reference it:

```yaml
spec:
  tls:
  - hosts:
    - ibtisam-iq.com
    secretName: demo-tls
```

In your Gateway you would also reference that secret (depending on TLS mode).

