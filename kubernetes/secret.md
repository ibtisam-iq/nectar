# Kubernetes Secrets

## 1. Introduction
Kubernetes Secrets allow you to store and manage sensitive information, such as passwords, OAuth tokens, and SSH keys, securely in your cluster. Unlike ConfigMaps, Secrets are designed for confidential data and are base64-encoded.

## 2. Types of Secrets
There are three main types of secrets in Kubernetes:

1. **Docker Registry Secret** (`docker-registry`) - Used for pulling images from private registries.
2. **Generic Secret** (`generic`) - Used for storing arbitrary data, such as configuration files, credentials, or certificates.
3. **TLS Secret** (`tls`) - Stores TLS certificate and key pairs for HTTPS communication.

## 3. Creating Secrets Imperatively
Kubernetes provides multiple ways to create secrets using the `kubectl create secret` command.

### 3.1 Creating Generic Secrets
#### **1. From Files (All Keys Automatically Generated)**
```sh
kubectl create secret generic my-secret --from-file=path/to/bar
```
- This command creates a secret named `my-secret` where each file in `path/to/bar` becomes a key with its contents as the value.

#### **2. From Specific Files (Defining Custom Keys)**
```sh
kubectl create secret generic my-secret \
  --from-file=ssh-privatekey=path/to/id_rsa \
  --from-file=ssh-publickey=path/to/id_rsa.pub
```
- In this case, `ssh-privatekey` and `ssh-publickey` are explicitly set as keys, mapping to the respective files.

#### **3. From Literal Values**
```sh
kubectl create secret generic my-secret \
  --from-literal=key1=supersecret \
  --from-literal=key2=topsecret
```
- This command creates a secret with direct key-value pairs stored in memory.

#### **4. Combining Files and Literals**
```sh
kubectl create secret generic my-secret \
  --from-file=ssh-privatekey=path/to/id_rsa \
  --from-literal=passphrase=topsecret
```
- This method allows a mix of files and manually defined key-value pairs.

#### **5. From Environment Files**
```sh
kubectl create secret generic my-secret \
  --from-env-file=path/to/foo.env \
  --from-env-file=path/to/bar.env
```
- This loads environment variables from `.env` files into a Kubernetes Secret.

### 3.2 Creating a TLS Secret
```sh
kubectl create secret tls my-tls-secret \
  --cert=path/to/tls.crt --key=path/to/tls.key
```
- This is used to store a TLS certificate (`tls.crt`) and private key (`tls.key`) securely.

### 3.3 Creating a Docker Registry Secret
```sh
kubectl create secret docker-registry my-reg-secret \
  --docker-server=<registry-server> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>
```
- This is required when pulling images from private registries.

## 4. Understanding Secret Types

The `--type` flag in `kubectl create secret generic` allows you to specify a custom type for the secret. By default, secrets created using `generic` have the type **`Opaque`**, but you can define your own type if needed.

### **Usage Example**
```sh
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=supersecret --type=my-custom-type
```
Here, `my-custom-type` is an arbitrary string that helps categorize the secret.

### **Common Built-in Secret Types**
| Secret Type          | Description |
|----------------------|-------------|
| `Opaque` (default)   | Generic secret for storing arbitrary key-value pairs. |
| `kubernetes.io/dockerconfigjson` | Used for Docker registry credentials. |
| `kubernetes.io/tls` | Stores a TLS certificate and key pair. |
| `bootstrap.kubernetes.io/token` | Used for bootstrap tokens (for cluster joining). |

### **Example: Creating a TLS Secret**
```sh
kubectl create secret tls my-tls-secret --cert=path/to/tls.crt --key=path/to/tls.key --type=kubernetes.io/tls
```

### **How to Check the Type of a Secret**
```sh
kubectl get secret my-secret -o jsonpath='{.type}'
```
This will return the type of the specified secret.

## 5. Viewing Secrets
```sh
kubectl get secrets
```
- Lists all available secrets.

```sh
kubectl describe secret my-secret
```
- Shows details of a specific secret.

## 6. Decoding Secret Data
By default, secrets are stored in base64 encoding. To decode them:

```sh
kubectl get secret my-secret -o jsonpath='{.data.key1}' | base64 --decode
```
- This command fetches the `key1` value from `my-secret` and decodes it.

## 7. Summary
- Kubernetes Secrets are used to store sensitive data securely.
- They can be created from files, literals, environment files, TLS certificates, and Docker credentials.
- Secrets are base64-encoded, not encrypted—additional security measures (RBAC, encryption at rest) should be applied.

By mastering secrets, you can ensure secure configuration management within your Kubernetes cluster. 🚀

