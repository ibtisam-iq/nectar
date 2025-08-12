## Managing multiple directories

Let's create a single `kustomization.yaml` file in the **root of the k8s directory** and import all resources defined for `db`, `message-broker`, `nginx` into it.

```bash
controlplane ~/code/k8s ➜  tree -a
.
├── db
│   ├── db-config.yaml
│   ├── db-depl.yaml
│   └── db-service.yaml
├── message-broker
│   ├── rabbitmq-config.yaml
│   ├── rabbitmq-depl.yaml
│   └── rabbitmq-service.yaml
└── nginx
    ├── nginx-depl.yaml
    └── nginx-service.yaml

3 directories, 8 files

controlplane ~/code/k8s ➜  vi kustomization.yaml

controlplane ~/code/k8s ➜  cat kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - db/db-config.yaml
  - db/db-depl.yaml
  - db/db-service.yaml
  - message-broker/rabbitmq-config.yaml
  - message-broker/rabbitmq-depl.yaml
  - message-broker/rabbitmq-service.yaml
  - nginx/nginx-depl.yaml
  - nginx/nginx-service.yaml

controlplane ~/code/k8s ➜  k apply -k .
configmap/db-credentials created
configmap/redis-credentials created
service/db-service created
service/nginx-service created
service/rabbit-cluster-ip-service created
deployment.apps/db-deployment created
deployment.apps/nginx-deployment created
deployment.apps/rabbitmq-deployment created
```

Let's create a `kustomization.yaml` file in each of the `subdirectories` and import only the resources within that directory.

```bash
controlplane ~/code/k8s ➜  vi db/kustomization.yaml

controlplane ~/code/k8s ➜  vi message-broker/kustomization.yaml

controlplane ~/code/k8s ➜  cat db/kustomization.yaml
resources:
  - db-depl.yaml
  - db-service.yaml
  - db-config.yaml

controlplane ~/code/k8s ➜  vi nginx/kustomization.yaml

controlplane ~/code/k8s ➜  vi kustomization.yaml 

controlplane ~/code/k8s ➜  cat kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - db/
  - message-broker/
  - nginx/

controlplane ~/code/k8s ➜  k apply -k .
configmap/db-credentials created
configmap/redis-credentials created
service/db-service created
service/nginx-service created
service/rabbit-cluster-ip-service created
deployment.apps/db-deployment created
deployment.apps/nginx-deployment created
deployment.apps/rabbitmq-deployment created

controlplane ~/code/k8s ➜  tree -a
.
├── db
│   ├── db-config.yaml
│   ├── db-depl.yaml
│   ├── db-service.yaml
│   └── kustomization.yaml
├── kustomization.yaml
├── message-broker
│   ├── kustomization.yaml
│   ├── rabbitmq-config.yaml
│   ├── rabbitmq-depl.yaml
│   └── rabbitmq-service.yaml
└── nginx
    ├── kustomization.yaml
    ├── nginx-depl.yaml
    └── nginx-service.yaml

3 directories, 12 files
```

## Transformers

Assign the following annotation to all `nginx` and `monitoring` resources: `owner: bob@gmail.com`

```bash
controlplane ~/code/k8s ➜  cat nginx/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - nginx-depl.yaml
  - nginx-service.yaml

commonAnnotations:
  owner: bob@gmail.com
controlplane ~/code/k8s ➜  cat monitoring/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - grafana-depl.yaml
  - grafana-service.yaml

namespace: logging

commonAnnotations:
  owner: bob@gmail.com
```
Transform `all postgres` images in the project to `mysql`.

```bash
Since the requirement was to change all postgres images to mysql this means adding an image transformer to the root kustomization.yaml file.

controlplane ~/code/k8s ➜  cat kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - db/
  - monitoring/
  - nginx/

commonLabels:
  sandbox: dev

images:
  - name: postgress
    newName: mysql
```

Transform all `nginx` images in the **nginx directory** to `nginx:1.23`.

```bash
controlplane ~/code/k8s ➜  cat nginx/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - nginx-depl.yaml
  - nginx-service.yaml

commonAnnotations:
  owner: bob@gmail.com

images:
  - name: nginx
    newTag: "1.23"
```

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
