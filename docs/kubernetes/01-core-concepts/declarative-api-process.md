# 🧠 The Internal Process Behind “API” in Kubernetes (Made Human-Friendly)

## 🚀 Scenario: You create a Pod using a YAML file

### You write this YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
```

**What’s really happening?**

---

## 🔍 Step-by-Step Breakdown

| Step | Action | Behind the Scenes |
|------|--------|-------------------|
| 1️⃣ | You run: `kubectl apply -f pod.yaml` | `kubectl` reads the YAML file |
| 2️⃣ | kubectl converts YAML into an **API request** | It forms an HTTP POST request |
| 3️⃣ | It sends this request to the **Kubernetes API Server** | The API server is the cluster's *control center* |
| 4️⃣ | API Server checks your YAML matches a known **API Object** (`Pod`) | This is an "API Object" – basically, a data structure Kubernetes understands |
| 5️⃣ | If it’s valid, API Server stores the object in **etcd** (database) | This is how Kubernetes remembers what to run |
| 6️⃣ | Then, Scheduler sees there's a new Pod → assigns a node | This starts actual container creation |
| ✅ | Container runtime runs the Pod | Your app is live on a node |

---

## 🧩 Understanding API Components Now

### 🔹 API Object:
- A **type of resource** you want Kubernetes to manage (like Pod, Service, Deployment)
- Each one has a schema (rules, properties)
- Defined in YAML and recognized by the Kubernetes API

### 🔹 API Request:
- The actual **HTTP message** (like `POST`, `GET`) sent to the API Server
- Created **automatically** by `kubectl`, Helm, or the dashboard

### 🔹 API Endpoint:
- A **URL path** on the API server like:  
  `POST /api/v1/namespaces/default/pods`

- Think of this like:  
  `www.kubernetes-cluster.com/api/v1/...`

---

## 💬 kubeadm API?

kubeadm’s API isn’t an HTTP one. Instead, it defines **config object types** like:

- `InitConfiguration`
- `ClusterConfiguration`

When you write `kubeadm-config.yaml`, kubeadm reads it → interprets it → and makes the right decisions to initialize or join the cluster.

Same principle, just not over HTTP.

---

## 📦 Conclusion

Your YAML → gets converted into → **API Object**  
kubectl → sends it as → **API Request**  
API server → receives it on → **API Endpoint**  
Then cluster starts reacting to it.

---

## 🤔 What’s Next?

Click [here](kubernetes-api-guide.md) to learn more about Kubernetes API and how to interact with it in simple way. This is a great resource to learn more about Kubernetes API in-depth.