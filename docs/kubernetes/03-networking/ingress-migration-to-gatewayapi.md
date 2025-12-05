# 🚀 Migrating from Ingress to Gateway API with Conditional Routing

## 📌 The Question

The task is to migrate an existing **Ingress** configuration to a **Gateway API HTTPRoute**.
The old Ingress file is located at `/opt/course/13/ingress.yaml`.

Key requirements:

1. Work in **Namespace `project-r500`**.
2. Use the **already existing Gateway** (reachable at `http://r500.gateway:30080`).
3. Create a new **HTTPRoute** named `traffic-director`.
4. The HTTPRoute must replicate the old Ingress routes:

   * `/desktop` → forwards to service **web-desktop**
   * `/mobile` → forwards to service **web-mobile**
5. Extend the HTTPRoute with a new rule for `/auto`:

   * If `User-Agent` header is exactly `mobile` → forward to **web-mobile**
   * Otherwise (any other header or no header at all) → forward to **web-desktop**

---

## 📌 The Old Ingress

Here’s the original **Ingress** manifest we are migrating:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traffic-director
spec:
  ingressClassName: nginx
  rules:
    - host: r500.gateway
      http:
        paths:
          - backend:
              service:
                name: web-desktop
                port:
                  number: 80
            path: /desktop
            pathType: Prefix
          - backend:
              service:
                name: web-mobile
                port:
                  number: 80
            path: /mobile
            pathType: Prefix
```

👉 This simply maps `/desktop` → `web-desktop` and `/mobile` → `web-mobile`.

---

## 📌 Migrating to Gateway API

Gateway API is the next-generation alternative to Ingress.

* Instead of defining rules in **Ingress**, we use **HTTPRoute**.
* **HTTPRoute** attaches to an existing **Gateway** via `parentRefs`.
* We can match traffic based on hostname, path, headers, and more.

---

## 📌 The New HTTPRoute (With Deep Comments)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: traffic-director                # Same name for clarity
  namespace: project-r500               # Always set the correct namespace
spec:
  parentRefs:
    - name: main                        # Attach to the existing Gateway
      namespace: project-r500
  hostnames:
    - r500.gateway                      # Same hostname as in old Ingress

  rules:
    # -------------------------------
    # Rule 1: /desktop → web-desktop
    # -------------------------------
    - matches:
        - path:
            type: PathPrefix            # PathPrefix = matches /desktop and subpaths
            value: /desktop
      backendRefs:
        - name: web-desktop             # Service name
          port: 80                      # Service port

    # -------------------------------
    # Rule 2: /mobile → web-mobile
    # -------------------------------
    - matches:
        - path:
            type: PathPrefix
            value: /mobile
      backendRefs:
        - name: web-mobile
          port: 80

    # -------------------------------
    # Rule 3a: /auto + User-Agent: mobile → web-mobile
    # -------------------------------
    - matches:
        - path:
            type: PathPrefix
            value: /auto
          headers:                      # Match HTTP header conditions
            - type: Exact               # "Exact" = must match exactly
              name: User-Agent          # The header we are checking
              value: mobile             # Match only if User-Agent = "mobile"
      backendRefs:
        - name: web-mobile
          port: 80

    # -------------------------------
    # Rule 3b: /auto (fallback) → web-desktop
    # -------------------------------
    - matches:
        - path:
            type: PathPrefix
            value: /auto
          # Note: no header match here → this acts as a fallback rule
      backendRefs:
        - name: web-desktop
          port: 80
```

---

## 📌 How the `/auto` Rule Works

* **Two separate rules** are required:

  1. Specific case: `/auto` + `User-Agent: mobile` → **web-mobile**
  2. General case: `/auto` (no header or any other header) → **web-desktop**

* Gateway API processes rules in order:

  * If the header matches `mobile`, the first rule wins.
  * If not, the fallback rule applies.

---

## 📌 Testing the Setup

After applying the manifest:

```bash
# Desktop route
curl r500.gateway:30080/desktop

# Mobile route
curl r500.gateway:30080/mobile

# Auto route with User-Agent: mobile
curl r500.gateway:30080/auto -H "User-Agent: mobile"

# Auto route with no header (falls back to desktop)
curl r500.gateway:30080/auto
```

✅ Expected Results:

* `/desktop` → response from `web-desktop`
* `/mobile` → response from `web-mobile`
* `/auto` with `User-Agent: mobile` → response from `web-mobile`
* `/auto` without header (or any non-mobile header) → response from `web-desktop`

---

## 📌 Key Takeaways

* **Ingress → Gateway API** migration = mostly about moving path-based rules into **HTTPRoute**.
* Gateway API provides **much finer control**, especially with **header-based routing**.
* The `/auto` path demonstrates **conditional routing**: same path but different backend depending on request headers.
* Always define a **fallback rule** when doing conditional routing.
