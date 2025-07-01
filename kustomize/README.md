```text
controlplane ~/code/k8s ➜  tree -a
.
├── base
│   ├── api-deployment.yaml
│   ├── db-configMap.yaml
│   ├── kustomization.yaml
│   └── mongo-depl.yaml
└── overlays
    ├── dev
    │   ├── api-patch.yaml
    │   └── kustomization.yaml
    ├── prod
    │   ├── api-patch.yaml
    │   ├── kustomization.yaml
    │   └── redis-depl.yaml
    ├── QA
    │   └── kustomization.yaml
    └── staging
        ├── configMap-patch.yaml
        └── kustomization.yaml

6 directories, 12 files

controlplane ~/code/k8s ➜  
```