# Centralized Logging with Elastic Stack (ECK, Elasticsearch, Kibana, Beats)

## 1. Goal and scope

This stack provides **centralized logging** for Kubernetes workloads:

- Collects container and node logs from all cluster nodes.  
- Stores them in a searchable backend.  
- Exposes a UI to explore, filter, and build dashboards on top of logs.

It is an **open‑source, cloud‑agnostic alternative** to using AWS CloudWatch Logs, suitable for EKS and any other Kubernetes cluster.

---

## 2. High‑level logging process

At a process level, the logging pipeline mirrors the pattern:

1. **Collect logs on nodes**  
   - Agents (Beats) run as DaemonSets, read container logs, and send them out.

2. **Store and index logs**  
   - Elasticsearch stores logs as JSON documents and indexes them.

3. **Visualize and search logs**  
   - Kibana connects to Elasticsearch for queries, dashboards, and visualizations.

In this stack, the roles are implemented by:

- **Filebeat/Beats** – log agents.  
- **Elasticsearch** – log store and index.  
- **Kibana** – UI and query layer.  
- **Elastic Cloud on Kubernetes (ECK)** – operator that manages all of the above.

---

## 3. Component responsibilities

### 3.1 Role overview

| Component type      | Component      | Responsibility                                   | Notes                              |
|---------------------|---------------|--------------------------------------------------|------------------------------------|
| Operator            | ECK           | Manages ES, Kibana, Beats via CRDs               | One operator per cluster/namespace |
| Log store / index   | Elasticsearch | Persist and index log documents                  | Uses PVs (e.g., EBS) for data      |
| UI                  | Kibana        | Search, filter, dashboards, visualizations       | Auth + role‑based access           |
| Agent / collector   | Filebeat/Beats| Read pod/node logs and send to Elasticsearch     | Deployed as DaemonSet in K8s       |
| Optional pipeline   | Logstash      | Parse/enrich/route logs before Elasticsearch     | Often skipped in simple setups     |

### 3.2 ECK – Elastic Cloud on Kubernetes

**Responsibility:** Act as the control plane for Elastic components in Kubernetes.

- Extends Kubernetes with CRDs like `Elasticsearch`, `Kibana`, `Beat`.  
- Watches these resources and creates/updates StatefulSets, Deployments, Services, Secrets, etc.  
- Handles version upgrades, scaling, TLS, and other operational aspects.

Without ECK you would have to manually write and maintain all ES/Kibana/Beat deployments.

### 3.3 Elasticsearch

**Responsibility:** Main log storage and search engine.

- Stores logs as JSON documents with fields (timestamp, namespace, pod, container, severity, message, etc.).  
- Provides rich query and aggregation capabilities for log analysis.  
- Needs persistent volumes (e.g., EBS) to keep data across pod restarts.

### 3.4 Kibana

**Responsibility:** Web UI for exploring logs and building visualizations.

- Connects to Elasticsearch and exposes search and dashboards.  
- Lets you create index patterns, saved searches, visualizations, and dashboards.  
- Can be exposed externally via Ingress / Gateway / AWS Load Balancer Controller, similar to Argo CD/Grafana in your instructor’s repo.

### 3.5 Beats (Filebeat, etc.)

**Responsibility:** Log collection on nodes.

- Filebeat runs as a **DaemonSet**, reading container logs from node paths like `/var/log/containers/*`.  
- Autodiscover mode can automatically pick up pods and add Kubernetes metadata (namespace, pod, container, labels).  
- Sends logs directly to Elasticsearch or via Logstash.

---

## 4. Installation options for this stack

There are two main ways to install this logging stack in Kubernetes.

### 4.1 Manual installation (all components separately)

You can deploy each component yourself:

1. **Elasticsearch** – StatefulSet, headless Service, PVCs for data, ConfigMaps/Secrets.  
2. **Kibana** – Deployment + Service, configured to connect to Elasticsearch.  
3. **Filebeat (or Fluent Bit)** – DaemonSet configured to ship logs to Elasticsearch.  
4. **Optional Logstash** – Deployment/StatefulSet that receives logs and forwards to ES.

Pros:

- Full control over every detail.  
- Works even without an operator.

Cons:

- More YAML/Helm to maintain.  
- Upgrades, TLS, scaling, and credentials are your responsibility.

### 4.2 Operator‑based installation with ECK (recommended)

This is the approach used in the production‑grade GitOps demo and is ideal for GitOps‑style management.

High‑level steps:

1. **Install the ECK operator**  
2. **Create an Elasticsearch cluster (CR)**  
3. **Create a Kibana instance (CR)**  
4. **Deploy Filebeat (Beat CR or DaemonSet)**  
5. **Expose Kibana for access**

This option:

- Reduces YAML you write.  
- Centralizes lifecycle (upgrades, scaling, TLS).  
- Aligns with GitOps: ES/Kibana/Beats are just CRs in your Git repo.

---

## 5. Detailed ECK‑based installation flow

Below is the installation described in **process order**, matching a typical ECK logging deployment.

### Step 1: Requirements

Before installing:

- Kubernetes cluster (e.g., EKS).  
- Storage class backed by EBS for persistent volumes.  
- `kubectl` configured for the cluster.  
- (Recommended) Separate namespace for ECK and for logging stack.

### Step 2: Install the ECK operator

**Why?**  
You need the operator before you can create `Elasticsearch`, `Kibana`, and `Beat` CRs; it is the brain that interprets those specs.

**How (example methods):**

- Apply operator manifest:  
  - Single YAML from Elastic (all‑in‑one).  
  - Creates CRDs and operator Deployment.

- Or install via Helm chart for ECK (recommended for configurable, versioned deployment).

After this step, Kubernetes understands CRDs like:

- `elasticsearch.elasticsearch.k8s.elastic.co`  
- `kibana.kibana.k8s.elastic.co`  
- `beat.beat.k8s.elastic.co`

### Step 3: Deploy Elasticsearch via CR

**Why?**  
You need a persistent, clustered log store first; everything else depends on it.

**What you define in the CR:**

- Cluster name and version.  
- Node roles and counts (simple: 1–3 nodes for demo).  
- Storage class and size for data volumes (EBS).  
- Resources (CPU/memory) for pods.

Once applied, ECK:

- Creates StatefulSets for ES nodes.  
- Creates Services for internal access.  
- Creates Secrets for credentials.

You wait for pods to be `Running` and `Ready` before continuing.

### Step 4: Deploy Kibana via CR

**Why?**  
This is the UI you’ll use to see logs.

**What you define:**

- Kibana version.  
- Reference to the Elasticsearch cluster created in previous step.  
- Resources, replica count.

ECK:

- Creates a Deployment and Service for Kibana.  
- Manages environment variables/credentials to connect to ES.

Later, you would expose Kibana with Gateway API + AWS Load Balancer Controller, similar to Argo CD and other UIs.

### Step 5: Deploy Filebeat (Beats) for log collection

**Why?**  
Now that the backend and UI are ready, you need agents to actually send logs there.

Options with ECK:

- Deploy **Beats via ECK Beat CR** (e.g., `kind: Beat`, type Filebeat).  
- Or deploy Filebeat as a regular DaemonSet YAML (not via CR) and point it at Elasticsearch.

Typical configuration:

- Run as DaemonSet on every node.  
- Use **autodiscover** to find pods and containers.  
- Parse container logs (CRI format) and add Kubernetes metadata.  
- Output to the Elasticsearch Service created by ECK.

After this step, logs from all pods start flowing into Elasticsearch, visible in Kibana indices.

### Step 6: Expose Kibana and log in

**Why?**  
You need external access to explore logs.

Patterns:

- `kubectl port-forward` for local debugging (demo).  
- In production: Ingress / Gateway API / AWS Load Balancer Controller, plus DNS and TLS via ExternalDNS + ACM, similar to how other UIs are exposed.

You obtain the Kibana URL and credentials (from ES user Secret) and log in. From there you:

- Define index patterns.  
- Search logs.  
- Build dashboards and visualizations.

---

## 6. Alternative logging stacks in the same component model

To keep the process‑first view clear, here is how other stacks line up against the Elastic/ECK approach.

| Component type  | Elastic/ECK stack                           | Loki stack                      | AWS‑native stack               |
|-----------------|---------------------------------------------|----------------------------------|--------------------------------|
| Operator        | ECK (optional but used here)                | – (Helm/Jsonnet/operator options) | –                              |
| Log store/index | Elasticsearch / OpenSearch                  | Loki                             | CloudWatch Logs                |
| UI              | Kibana                                      | Grafana                          | CloudWatch Logs console        |
| Agent           | Beats (Filebeat, etc.)                      | Promtail/Alloy                   | Fluent Bit / CloudWatch agent  |
| Optional pipe   | Logstash (ingest)                           | Processors inside Loki/OTel      | Kinesis/Data Firehose (optional) |

All of them implement the same pipeline:

> Agent → (optional pipeline) → Log store → UI

This stack chooses **Elastic/ECK** because it is fully open‑source, cloud‑agnostic, and integrates well with GitOps and Kubernetes CRDs.
