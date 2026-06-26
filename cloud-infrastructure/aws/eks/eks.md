

### EKS Fargate Profile – Quick Notes

- **What it is**
  - Fargate = serverless compute for EKS pods (no EC2 worker nodes to manage).
  - A *Fargate profile* defines which pods should run on Fargate using namespace + optional label selectors.

- **How selection works**
  - Every profile has:
    - `namespace` (required).
    - Optional `labels` key/value map.
  - If a pod’s namespace and labels match a profile’s selector, that pod is scheduled on Fargate.
  - Multiple profiles can exist; you can target different namespaces or workloads (e.g., `default`, `jobs`, `tenant-a`, etc.).

- **Creation order and Pending pods**
  - If pods are created **before** a matching Fargate profile exists, they often stay in `Pending` because the scheduler has no matching node or profile.
  - After creating the profile, delete/restart Pending pods or rollout restart the Deployment so they get re‑scheduled onto Fargate.

- **Deleting a Fargate profile**
  - Deleting a profile immediately deletes all pods that were running on Fargate using that profile.
  - The Kubernetes Deployment/Job/ReplicaSet objects are **not** deleted. They will try to create new pods.
  - New pods will:
    - Run on another matching Fargate profile or node group if available.
    - Otherwise stay Pending until some valid compute is available.

- **Good practice**
  - Create Fargate profiles **before** deploying workloads meant for Fargate.
  - Use separate namespaces or labels to clearly separate Fargate workloads from node‑group workloads.
  - Be careful when deleting profiles in a prod namespace; it will kill all Fargate pods selected by that profile.
