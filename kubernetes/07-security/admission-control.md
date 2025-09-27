# Admission Control in Kubernetes

## 📌 What are Admission Controllers?

* Admission Controllers are **plugins** in the **Kube-API Server** that intercept API requests **after authentication & authorization** but **before persistence in etcd**.
* They act as **“guardians”** that can **validate**, **mutate**, or **reject** requests.
* Purpose: enforce **policies**, apply **defaults**, or inject **configurations** automatically.

---

## ⚙️ Functions of Admission Controllers

1. **Validation** – e.g., reject if namespace doesn’t exist (`NamespaceExists`).
2. **Mutation** – e.g., auto-assign a default storage class (`DefaultStorageClass`).
3. **Security Enforcement** – restrict privileges (e.g., `PodSecurity`).
4. **Policy Control** – control what resources can be created/modified.

---

## 🔍 How to Check Enabled Admission Plugins

### 1. Check running API Server process

```bash
ps -aux | grep apiserver | grep -i admission-plugins
```

### 2. Exec into API Server Pod and check help

```bash
kubectl -n kube-system exec -it kube-apiserver-controlplane -- \
  kube-apiserver -h | grep enable-admission-plugins
```

---

## 🔧 Enable / Disable Admission Controllers

* Enable:

  ```bash
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount
  ```
* Disable:

  ```bash
  --disable-admission-plugins=DefaultStorageClass
  ```

---

## ✅ Default vs Non-default Admission Controllers

* **Enabled by default (examples):**

  * `NamespaceExists` → ensures a namespace must exist before creating objects inside it.
  * `LimitRanger` → enforces resource limits.

* **Not enabled by default (examples):**

  * `NamespaceAutoProvision` → auto-creates a namespace if it doesn’t exist.

🔎 Example:

```bash
kubectl run nginx --image=nginx -n blue
# Error: namespaces "blue" not found
```

This fails because `NamespaceAutoProvision` is NOT enabled by default.

---

## 🧩 Types of Admission Controllers

1. **Mutating Admission Controllers**

   * Can **modify** requests (add/change fields).
   * Example: `DefaultStorageClass` → auto-assigns a default storage class if PVC doesn’t specify one.

2. **Validating Admission Controllers**

   * Can only **accept or reject**, cannot modify.
   * Example: `NamespaceExists` → rejects if namespace does not exist.

---

## 🕒 Order of Execution

1. **Mutating Admission Controllers run first** → they modify the request.
2. **Validating Admission Controllers run next** → they validate the final (mutated) request.

This ensures validation happens on the **final state** of the object.

---

## 🌐 Admission Webhooks

For dynamic/custom policies, Kubernetes allows webhooks:

1. **MutatingAdmissionWebhook**

   * External webhook that can modify requests.

2. **ValidatingAdmissionWebhook**

   * External webhook that validates requests but cannot change them.

---

## ⚡ Steps to Use Admission Webhooks

1. **Build a webhook server** (custom logic in Go/Python).
2. **Deploy webhook server** in cluster as a Deployment.
3. **Expose it as a Service** (so API Server can reach it).
4. **Create a ValidatingWebhookConfiguration or MutatingWebhookConfiguration** object to register the webhook with API Server.
5. API Server now calls the webhook during admission for matching requests.

---

## 🔑 Key Takeaways

* Admission Controllers = “traffic police” at API Server level.
* They enforce policies, mutate requests, and protect the cluster.
* Built-in ones (like `NamespaceExists`) are common; others need enabling.
* Order: **Mutating → Validating**.
* For custom rules → use **Admission Webhooks**.

---

```bash
controlplane ~ ➜  k create ns webhook-demo
namespace/webhook-demo created

controlplane ~ ➜  cat /root/keys/webhook-server-tls.crt                      
-----BEGIN CERTIFICATE-----
MIIDjjCCAnagAwIBAgIUYLaOiBmF0X0A94JhDRuvQPbUPo4wDQYJKoZIhvcNAQEL
BQAwLzEtMCsGA1UEAwwkQWRtaXNzaW9uIENvbnRyb2xsZXIgV2ViaG9vayBEZW1v
IENBMB4XDTI1MDkyNzEyMzcwMVoXDTI1MTAyNzEyMzcwMVowKjEoMCYGA1UEAwwf
d2ViaG9vay1zZXJ2ZXIud2ViaG9vay1kZW1vLnN2YzCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAMTWwCoJz5Y+u0QdPJpcII9jSSdgijv0GoJSAfSOZbiZ
wi4FNlJdn6AfUQnTyf/IYuBf74ZVgZub2JZ4BfkCQEe6zIpEJ6JVbW+XBFlTP5Ca
WPBObmvNU7I30mBCJq7iR/mzSiC+i2bQMAjnFTWwH/kVeouEDlhBhLOYPEEzAT61
DvKnaY32jZirX67x+UrxxL8kAP6t2ZA72RRxvY9POdoVzfhLBEWMq2FvjQsc752u
23Rc7wsxhDoKMs67KgnO2DFX1zInfaTDVfn989TkR9JJjI1rOXarlJBrXHRcDGVq
C77oGzAPaRVcuP8JEzF30w0cVVNYucolpnKY15dBeCcCAwEAAaOBpjCBozAJBgNV
HRMEAjAAMAsGA1UdDwQEAwIF4DAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUH
AwEwKgYDVR0RBCMwIYIfd2ViaG9vay1zZXJ2ZXIud2ViaG9vay1kZW1vLnN2YzAd
BgNVHQ4EFgQU9RQ0x0DaOfdQF+Pvulo4P6xJpUIwHwYDVR0jBBgwFoAUJgm2Gb37
zdPIhKZLb2lMl8U4LPAwDQYJKoZIhvcNAQELBQADggEBABi7AdCv54sld4k0TaP1
cMEbv8Jyeyb3liqnwB543uzF1he3MRY2SVfHVclbR6vulMo95VWU13EuqAuZ0Haa
Ty7zlX40AWslwo42Oj+tufbzGpSpPmt7yahjyoPQdaouq2BdK3Ghs23JGrkTqiSd
25DsGp/4KnSK0PVTloH6bS/LcldXPBHtML0Dzpzo27mmNuB5shKRUo9z0vj6mbKc
sf5L8Eai3LqY5fJFQoUI51+4FD3/ryv5K1ztqO3XVSL+G+5sXBmG9chcjW8rDgNU
8ue4o7/GCnAgnUkRj644Xd7UqrBLuvTjTjz+1fzLbfmVBJNim67euKy3O70+uv/Y
7Ok=
-----END CERTIFICATE-----

controlplane ~ ✖ openssl x509 -in /root/keys/webhook-server-tls.crt -noout -text       # extra step
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            60:b6:8e:88:19:85:d1:7d:00:f7:82:61:0d:1b:af:40:f6:d4:3e:8e
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = Admission Controller Webhook Demo CA
        Validity
            Not Before: Sep 27 12:37:01 2025 GMT
            Not After : Oct 27 12:37:01 2025 GMT
        Subject: CN = webhook-server.webhook-demo.svc
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c4:d6:c0:2a:09:cf:96:3e:bb:44:1d:3c:9a:5c:
                    20:8f:63:49:27:60:8a:3b:f4:1a:82:52:01:f4:8e:
                    65:b8:99:c2:2e:05:36:52:5d:9f:a0:1f:51:09:d3:
                    c9:ff:c8:62:e0:5f:ef:86:55:81:9b:9b:d8:96:78:
                    05:f9:02:40:47:ba:cc:8a:44:27:a2:55:6d:6f:97:
                    04:59:53:3f:90:9a:58:f0:4e:6e:6b:cd:53:b2:37:
                    d2:60:42:26:ae:e2:47:f9:b3:4a:20:be:8b:66:d0:
                    30:08:e7:15:35:b0:1f:f9:15:7a:8b:84:0e:58:41:
                    84:b3:98:3c:41:33:01:3e:b5:0e:f2:a7:69:8d:f6:
                    8d:98:ab:5f:ae:f1:f9:4a:f1:c4:bf:24:00:fe:ad:
                    d9:90:3b:d9:14:71:bd:8f:4f:39:da:15:cd:f8:4b:
                    04:45:8c:ab:61:6f:8d:0b:1c:ef:9d:ae:db:74:5c:
                    ef:0b:31:84:3a:0a:32:ce:bb:2a:09:ce:d8:31:57:
                    d7:32:27:7d:a4:c3:55:f9:fd:f3:d4:e4:47:d2:49:
                    8c:8d:6b:39:76:ab:94:90:6b:5c:74:5c:0c:65:6a:
                    0b:be:e8:1b:30:0f:69:15:5c:b8:ff:09:13:31:77:
                    d3:0d:1c:55:53:58:b9:ca:25:a6:72:98:d7:97:41:
                    78:27
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Key Usage: 
                Digital Signature, Non Repudiation, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication, TLS Web Server Authentication
            X509v3 Subject Alternative Name: 
                DNS:webhook-server.webhook-demo.svc
            X509v3 Subject Key Identifier: 
                F5:14:34:C7:40:DA:39:F7:50:17:E3:EF:BA:5A:38:3F:AC:49:A5:42
            X509v3 Authority Key Identifier: 
                26:09:B6:19:BD:FB:CD:D3:C8:84:A6:4B:6F:69:4C:97:C5:38:2C:F0
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        18:bb:01:d0:af:e7:8b:25:77:89:34:4d:a3:f5:70:c1:1b:bf:
        c2:72:7b:26:f7:96:2a:a7:c0:1e:78:de:ec:c5:d6:17:b7:31:
        16:36:49:57:c7:55:c9:5b:47:ab:ee:94:ca:3d:e5:55:94:d7:
        71:2e:a8:0b:99:d0:76:9a:4f:2e:f3:95:7e:34:01:6b:25:c2:
        8e:36:3a:3f:ad:b9:f6:f3:1a:94:a9:3e:6b:7b:c9:a8:63:ca:
        83:d0:75:aa:2e:ab:60:5d:2b:71:a1:b3:6d:c9:1a:b9:13:aa:
        24:9d:db:90:ec:1a:9f:f8:2a:74:8a:d0:f5:53:96:81:fa:6d:
        2f:cb:72:57:57:3c:11:ed:30:bd:03:ce:9c:e8:db:b9:a6:36:
        e0:79:b2:12:91:52:8f:73:d2:f8:fa:99:b2:9c:b1:fe:4b:f0:
        46:a2:dc:ba:98:e5:f2:45:42:85:08:e7:5f:b8:14:3d:ff:af:
        2b:f9:2b:5c:ed:a8:ed:d7:55:22:fe:1b:ee:6c:5c:19:86:f5:
        c8:5c:8d:6f:2b:0e:03:54:f2:e7:b8:a3:bf:c6:0a:70:20:9d:
        49:11:8f:ae:38:5d:de:d4:aa:b0:4b:ba:f4:e3:4e:3c:fe:d5:
        fc:cb:6d:f9:95:04:93:62:9b:ae:de:b8:ac:b7:3b:bd:3e:ba:
        ff:d8:ec:e9

controlplane ~ ➜  cat /root/keys/webhook-server-tls.key                              
-----BEGIN PRIVATE KEY-----
MIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQDE1sAqCc+WPrtE
HTyaXCCPY0knYIo79BqCUgH0jmW4mcIuBTZSXZ+gH1EJ08n/yGLgX++GVYGbm9iW
eAX5AkBHusyKRCeiVW1vlwRZUz+QmljwTm5rzVOyN9JgQiau4kf5s0ogvotm0DAI
5xU1sB/5FXqLhA5YQYSzmDxBMwE+tQ7yp2mN9o2Yq1+u8flK8cS/JAD+rdmQO9kU
cb2PTznaFc34SwRFjKthb40LHO+drtt0XO8LMYQ6CjLOuyoJztgxV9cyJ32kw1X5
/fPU5EfSSYyNazl2q5SQa1x0XAxlagu+6BswD2kVXLj/CRMxd9MNHFVTWLnKJaZy
mNeXQXgnAgMBAAECggEAAwWoP6NhuSHPbqIWrk85yyaWfSQU6AsjmQ3SeXaL00Px
E+A0Nefs4OCtaT3QlryOrN+fZgWY259bhoiwA5aB3CTfEERjNpfVk7M5RHg472rS
cL+tH4fKGcaUbhi16IhEdW37D/oJwKzzmXKXncWaSBDvWuybhJL4JM9Y8kgd/cam
icwFkTyposu1BOeU14itP2c7RyqnhskKA2UadhpQkzWw49ifzMtJpmh63ak0cl85
Oa9Ozs4ZhPTjVB2R1mXLy1WGxoAoCnTyDK/EtPNepunQTOCTAcKw62zpl5dgia8k
w4zRwskHda2lHwkjjy4N7xT8Ov8fiKLNFOWr36hfWQKBgQDKX5lcVKCHAt7TR/L0
lbVDX+5YSOsU2PYc3TqlbnLRFBcVktWjO3iriqgpibTFvBKQX79zk5lIYJH9XgAw
blVKaa5zL8lvZFeP2esCSN1xtzJl2o+IhSOqpY7Y2Bk8p9JVoxWfG1wq6TifHFi+
VJZC04o5ZBxKigfV11TcngY8tQKBgQD4/7QYz4oc6JpFUE0wy6VvFYI4NG34m6ae
pKNcuBiI858iQInFoiZOe2h4YhhMYwr3wUiIT+2jIXgi3dpH7UngiTIW6Y2YwYS7
LUyl9APiZhPXF5ct4a5PqCTEAPghjBy2FbhnUZyJdETE40i7XWlybDitKd3oq9sG
Q8GSHl2G6wJ/GUvZ37C0YCv7rm1P8ULFZaaYJHD48aItIW6F5ifoMjpQqGGyUrUc
YFT0sDyGXDEmIOXXCJtqjaGEnich3uvrvWF4bO2MQGBKkbCrr51sEMrVgeXQC0CZ
NLt9H53jibFwmUPJcBn7a2G7sifY7/Gi1reaj5Hz911JnXFNKkaWgQKBgQCgLGz/
4NGpkv9aQzPEhdvfv2hLG376g7YFK0djJ5Gw13awo+98ULhvl/c2KXQT/0pY4d70
wOXPIIKVez0lM8FoTRkJoCfT8fieJ5+8yWGOS7fLj4NSonBtEW7FHxJ/EhCOGR7M
Z7VYvpBWTxbEYGyqjG9RBTOYrqRwPTnR8vKbDQKBgEPV+TPsBtz2B22qBI7q1lFw
OXTkG6vhPJ9LBNZnQpS0jgGOHA4UvKYidrgNT+3n8H79haWKKHEue1riKa3PVoEw
ctLJ9pLiQ+i7BYyHPm9z1MIWzJzSu48SUsdzyiyU42LcZT+hoWHNSCMpaIdOxm07
1AE5xwkdElq8imkIonf7
-----END PRIVATE KEY-----

controlplane ~ ➜  k create secret tls webhook-server-tls -n webhook-demo --cert=/root/keys/webhook-server-tls.crt --key=/root/keys/webhook-server-tls.key
secret/webhook-server-tls created

controlplane ~ ➜  cat /root/webhook-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-server
  namespace: webhook-demo
  labels:
    app: webhook-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webhook-server
  template:
    metadata:
      labels:
        app: webhook-server
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1234
      containers:
      - name: server
        image: stackrox/admission-controller-webhook-demo:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8443
          name: webhook-api
        volumeMounts:
        - name: webhook-tls-certs
          mountPath: /run/secrets/tls
          readOnly: true
      volumes:
      - name: webhook-tls-certs
        secret:
          secretName: webhook-server-tls

controlplane ~ ➜  k apply -f webhook-deployment.yaml 
deployment.apps/webhook-server created

controlplane ~ ➜  cat webhook-service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: webhook-server
  namespace: webhook-demo
spec:
  selector:
    app: webhook-server
  ports:
    - port: 443
      targetPort: webhook-api

controlplane ~ ➜  k apply -f webhook-service.yaml 
service/webhook-server created

controlplane ~ ➜  cat webhook-configuration.yaml 
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: demo-webhook
webhooks:
  - name: webhook-server.webhook-demo.svc
    clientConfig:
      service:
        name: webhook-server
        namespace: webhook-demo
        path: "/mutate"
      caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURQekNDQWllZ0F3SUJBZ0lVYXFHWVdjN3pGSzJYQlltNDVldmxoZkpvSlhVd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0x6RXRNQ3NHQTFVRUF3d2tRV1J0YVhOemFXOXVJRU52Ym5SeWIyeHNaWElnVjJWaWFHOXZheUJFWlcxdgpJRU5CTUI0WERUSTFNRGt5TnpFeU16Y3dNVm9YRFRJMU1UQXlOekV5TXpjd01Wb3dMekV0TUNzR0ExVUVBd3drClFXUnRhWE56YVc5dUlFTnZiblJ5YjJ4c1pYSWdWMlZpYUc5dmF5QkVaVzF2SUVOQk1JSUJJakFOQmdrcWhraUcKOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXNXVDViSDRxdVZrT1dDS3N1Vk1jdklSZjFJTkVDQjlOYXVmVApXNGRGalRaV0RpK2dzcFA4a2Jva1FsS0pmUG1RaDJYWmNDeVE3UC9mdCtXVG1pY24wM3ZHR3hzM21hVU5Gd2pDCk1jNGIySGFNc1Z2azF2SWtrZmZlWXJvYWdMbmZKNGlUdng4MjRwcE5nZEJKTFFSL2JnY2FMeVRVUFNiZDVrblkKaDZNYkhLWUFqY0h4alZacDBpSldoOWZHVzBlQktnZ2lMSnE5c09sMExKWFU3Ukt1YmhRd3dISXByRWlkbXRpegpUeHorZ0IvWkNVRkhsSnUwSTF2U1dOUnBNSEs1SmdKSHc1MkVrNzRtaHNoMm9BVE1wL01qZmd2RUZ6a0dsMXVRCmxEWlpDemQvV2IySFVSMkhVRVNlUTFhaFVJZUR4UVJhek13QUp0VmJIcVZzNlpiZ1d3SURBUUFCbzFNd1VUQWQKQmdOVkhRNEVGZ1FVSmdtMkdiMzd6ZFBJaEtaTGIybE1sOFU0TFBBd0h3WURWUjBqQkJnd0ZvQVVKZ20yR2IzNwp6ZFBJaEtaTGIybE1sOFU0TFBBd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBTkJna3Foa2lHOXcwQkFRc0ZBQU9DCkFRRUFpbzJSMmJqQkMxaGI3eUtzc0RBTFAyUlJ0b2dHY1BmclVkd25qLzhhQXpkbnJJNHVGeXVJejRjMFM2U00KcGVRSGtIVkZZNExNWktRbTZBdXhBMmU4TnhYakU5QlVqUUwzU0ZHWm5zU1NueFRUMWp1WXkvT2F6WGlEaCtIdQpUZTBqWjgxdWRhMU43T0t5eE9VZHlxSm16d2JCQzVtRmhIQUZjcmlmbEFCdUZqVXdEZ2ttY29JSWo0aGt3QXRCCktVWU5EUkdlaE5TczVFdG5xV2libGZqRHkvaHJTcys1VW55aVQvd3VxT1kvOC9pTUx1SFlPTUYvUUc5akZ3VUUKUGlhZzVBOXpmNkI5bW5GY2RjK1VtdHJxUVRyNmZORHRqN3RISC9YTHBuUUs2ZTdrVnRsNGVmUkswZlR4K014ego4bkxLdlpRdk9qaVUwc29lUzlZVFFWY0VOZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    rules:
      - operations: [ "CREATE" ]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    admissionReviewVersions: ["v1beta1"]
    sideEffects: None

controlplane ~ ➜  k apply -f webhook-configuration.yaml 
mutatingwebhookconfiguration.admissionregistration.k8s.io/demo-webhook created
```

In the previous steps, you have set up and deployed a `demo-webhook` with the following behaviors:

- ***Denies** all requests for pods to run as root in a container **if no `securityContext` is provided**.
- **Defaults**: If `runAsNonRoot` is not set, the webhook **automatically adds** `runAsNonRoot: true` and sets the user ID to `1234`.
- **Explicit root access**: The webhook **allows containers to run as root only if you explicitly set `runAsNonRoot: false`** in the pod's `securityContext`.

In the next steps, you will find pod definition files for each scenario. Please deploy these pods using the provided definition files and validate the behavior of our webhook.

```bash
controlplane ~ ➜  cat /root/pod-with-defaults.yaml
# A pod with no securityContext specified.
# Without the webhook, it would run as user root (0). The webhook mutates it
# to run as the non-root user with uid 1234.
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-defaults
  labels:
    app: pod-with-defaults
spec:
  restartPolicy: OnFailure
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "echo I am running as user $(id -u)"]

controlplane ~ ➜  k apply -f /root/pod-with-defaults.yaml
pod/pod-with-defaults created

controlplane ~ ➜  k logs pod-with-defaults 
I am running as user 1234

controlplane ~ ➜  k get po -o yaml pod-with-defaults | grep securityContext -A3
  securityContext:
    runAsNonRoot: true
    runAsUser: 1234
  serviceAccount: default

controlplane ~ ➜  cat /root/pod-with-override.yaml
# A pod with a securityContext explicitly allowing it to run as root.
# The effect of deploying this with and without the webhook is the same. The
# explicit setting however prevents the webhook from applying more secure
# defaults.
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-override
  labels:
    app: pod-with-override
spec:
  restartPolicy: OnFailure
  securityContext:
    runAsNonRoot: false
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "echo I am running as user $(id -u)"]

controlplane ~ ➜  k apply -f /root/pod-with-override.yaml
pod/pod-with-override created

controlplane ~ ➜  k logs pod-with-override 
I am running as user 0

controlplane ~ ➜  k get po -o yaml pod-with-override | grep securityContext -A3
  securityContext:
    runAsNonRoot: false
  serviceAccount: default
  serviceAccountName: default
```

Deploy a pod that specifies a conflicting `securityContext`.

- The pod requests to run with `runAsUser: 0 (root)`.
- But it does not explicitly set `runAsNonRoot: false`.

According to our webhook rules, this request should be **denied**.

```bash
controlplane ~ ➜  cat /root/pod-with-conflict.yaml
# A pod with a conflicting securityContext setting: it has to run as a non-root
# user, but we explicitly request a user id of 0 (root).
# Without the webhook, the pod could be created, but would be unable to launch
# due to an unenforceable security context leading to it being stuck in a
# 'CreateContainerConfigError' status. With the webhook, the creation of
# the pod is outright rejected.
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-conflict
  labels:
    app: pod-with-conflict
spec:
  restartPolicy: OnFailure
  securityContext:
    runAsNonRoot: true
    runAsUser: 0
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "echo I am running as user $(id -u)"]

controlplane ~ ➜  k apply -f /root/pod-with-conflict.yaml
Error from server: error when creating "/root/pod-with-conflict.yaml": admission webhook "webhook-server.webhook-demo.svc" denied the request: runAsNonRoot specified, but runAsUser set to 0 (the root user)
```
