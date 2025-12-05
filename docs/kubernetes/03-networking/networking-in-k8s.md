# NetworkPolicy and Ingress: Networking in Kubernetes

In Kubernetes, **Ingress** provides HTTP/S traffic routing into your cluster. It's often used in conjunction with Ingress Controllers (like NGINX) to manage this traffic. However, the **Ingress Resource** and **Ingress Controller** are separate from **NetworkPolicy**, which controls traffic flow at the network layer (L3/L4) between pods.

## Why Use NetworkPolicy with Ingress?

**NetworkPolicy** can work hand-in-hand with the **Ingress Resource** to create more secure environments by defining which pods can communicate with one another. While **Ingress** ensures HTTP/S routing, **NetworkPolicy** controls the network-level communication between the pods.

## Key Benefits of Using NetworkPolicy with Ingress

| **Feature**                                   | **Value** |
|-----------------------------------------------|-----------|
| 🔒 **Secures internal access to pods**        | ✅        |
| 🔍 **Clear visibility over who talks to what**| ✅        |
| 👮 **Enforces Zero Trust at network layer**   | ✅        |
| 🛡️ **Adds extra layer of defense with TLS**   | ✅        |

## Important Notes:
- Your **CNI plugin** (like Calico, Cilium) must support **NetworkPolicy**. Without a proper CNI, it won’t be enforced.
- **NetworkPolicies** are **L3/L4** controls—they are concerned with IPs and ports, not HTTP-level logic.
- By default, Kubernetes allows all traffic between pods. Only with **NetworkPolicy** defined will it enforce restrictions.

## How Does NetworkPolicy Integrate with Ingress?

While **Ingress** handles the routing of traffic based on HTTP/S rules, **NetworkPolicy** applies to network-level communication. For example, you can restrict which pods can access the backend services defined in your Ingress resource. This adds another layer of defense by ensuring that even if the **Ingress controller** routes traffic to the right service, only authorized pods can actually connect to it.

## Use Case: Restricting Access to App Pods Behind Ingress

You can create a **NetworkPolicy** that restricts access to the backend pods in your application, which are exposed by the **Ingress controller**.

### Example Scenario:
- **Ingress Resource** is routing traffic for a banking application.
- You want to restrict which internal pods or services can communicate with the banking app, even though the **Ingress** is exposing the application to external traffic.

### NetworkPolicy YAML Example:
Here’s an example of a **NetworkPolicy** that restricts access to the banking application pods only to specific internal services:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: bankapp-restrict-access
spec:
  podSelector:
    matchLabels:
      app: bankapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```
In this example:

- The `podSelector` matches the **bankapp** pods.
- Only pods labeled `app: frontend` are allowed to send traffic to the **bankapp** pods on port 80.

## Combining with Ingress Resource:
The **Ingress Resource** is routing external traffic to the backend service (**bankapp-service**), while the **NetworkPolicy** restricts which internal services (like frontend) can actually access the pods that the **Ingress controller** routes to.

## Additional NetworkPolicy Use Cases:

### Blocking External Access to Backend Services:
Use **NetworkPolicy** to block direct access from external IPs to your internal services, ensuring that all external traffic must come through the **Ingress controller**.

### Restricting Traffic to Certain Namespaces:
You can define policies that only allow certain namespaces to communicate with each other, harden production workloads, and prevent cross-namespace access.

### Example: Blocking External Access
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-external-access
spec:
  podSelector:
    matchLabels:
      app: bankapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```

In this case:

- Only pods labeled `app=frontend` are allowed to communicate with the **bankapp** pods on port 80.
- External traffic to **bankapp** is blocked unless it comes via the **Ingress controller**.

## TL;DR on NetworkPolicy + Ingress:
- **Ingress Resource** manages external HTTP/S traffic routing into your cluster.
- **NetworkPolicy** restricts internal network-level communication between pods.
- You don’t apply **NetworkPolicy** to the **Ingress resource** itself—instead, you define it to control which pods the **Ingress** routes traffic to.

By combining both, you achieve secure, controlled traffic flow both externally (via **Ingress**) and internally (via **NetworkPolicy**).
