# Advanced HTTPRoute Filters in Kubernetes Gateway API

This document provides a detailed reference on how to use **HTTPRoute** with advanced filters in the Gateway API. It includes real-world use cases and complete YAML examples.

---

## 📌 Prerequisites

Ensure you have the following deployed:

- A Gateway controller (e.g., NGINX Gateway)
- A Gateway resource named `my-nginx-gateway` in namespace `nginx-gateway`

Each `HTTPRoute` will reference this Gateway using:

```yaml
parentRefs:
- name: my-nginx-gateway
  namespace: nginx-gateway
  sectionName: http
```

---

## 🔀 Filter Use Cases

### 1. 🚦 Request Redirection (HTTP → HTTPS)

```yaml
rules:
- filters:
  - type: RequestRedirect
    requestRedirect:
      scheme: https
      statusCode: 301
```

> Redirects all incoming HTTP requests to HTTPS.

---

### 2. 🔄 URL Rewrite (`/old` → `/new`)

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /old
  filters:
  - type: URLRewrite
    urlRewrite:
      path:
        replacePrefixMatch: /new
  backendRefs:
  - name: my-app
    port: 80
```

> Rewrites `/old` paths to `/new` before forwarding to backend.

---

### 3. 🧠 Request Header Modification

```yaml
rules:
- filters:
  - type: RequestHeaderModifier
    requestHeaderModifier:
      add:
        x-env: staging
      set:
        x-country: PK
      remove:
      - x-remove-this
  backendRefs:
  - name: my-app
    port: 80
```

> Adds, sets, and removes headers in the request before it hits the backend.

---

### 4. 🪞 Request Mirroring

```yaml
rules:
- filters:
  - type: RequestMirror
    requestMirror:
      backendRef:
        name: mirror-service
        port: 80
  backendRefs:
  - name: my-app
    port: 80
```

> Sends a copy of the request to `mirror-service` without affecting the original flow.

---

### 5. 🧰 Combined Filters

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /products
  filters:
  - type: URLRewrite
    urlRewrite:
      path:
        replacePrefixMatch: /items
  - type: RequestHeaderModifier
    requestHeaderModifier:
      add:
        x-service-version: v2
  backendRefs:
  - name: product-service
    port: 8080
```

> Chains rewrite and header modification for advanced routing.

---

### 6. 🧪 Default Basic Match

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /
  backendRefs:
  - name: frontend-svc
    port: 80
```

> Acts as a fallback catch-all route.

---

## 🧱 Filter Summary

| Filter Type             | Description                                    |
| ----------------------- | ---------------------------------------------- |
| `RequestRedirect`       | Redirects requests (e.g., HTTP → HTTPS)        |
| `URLRewrite`            | Rewrites the path before sending to backend    |
| `RequestHeaderModifier` | Add/Set/Remove headers on incoming requests    |
| `RequestMirror`         | Mirrors request to another backend silently    |
| `ExtensionRef`          | Custom filters (defined by controller vendors) |

---

## 🧠 Tip

You can define multiple rules in one `HTTPRoute`, each with different matches and filters for microservices routing, A/B testing, canary deployments, and more.
