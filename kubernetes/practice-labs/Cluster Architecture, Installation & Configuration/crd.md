**Important Points:**

- CRD manifest is long → watch **indentation carefully**.
- Generate CR template with `k get crd <crd-name> -o yaml`.
- List CR instances/objects with `k get <crd-full-name> -A`.
- Use `k explain <crd-plural> --recursive` for schema help.
  
---

## Q 1

Write the list of all installed CRDs into `/root/crds`. Write the list of all DbBackup *objects* into `/root/db-backups`.

```bash
controlplane:~$ k get crd > /root/crds
controlplane:~$ k get crd | grep -i backup
db-backups.stable.killercoda.com                      2025-08-28T07:48:31Z

controlplane:~$ k describe crd db-backups.stable.killercoda.com | grep -i singular
    Singular:   db-backup
    Singular:   db-backup
controlplane:~$ k get db-backups.stable.killercoda.com -A
NAMESPACE     NAME                       AGE
default       postgres-sunny-sunshine    2m55s
default       postgres-walking-waveart   2m55s
kube-system   mysql-total-tolly          2m55s
controlplane:~$ k get db-backups.stable.killercoda.com -A > /root/db-backups
```

---

## Q 2
Define a Kubernetes custom resource definition (CRD) for a new resource kind called `Foo` (plural form - foos) in the `samplecontroller.example.com group`.

This CRD should have a version of `v1alpha1` with a schema that includes two properties as given below:

`deploymentName` (a `string` type) and `replicas` (an `integer` type with minimum value of `1` and maximum value of `5`).

It should also include a status subresource which enables retrieving and updating the status of Foo object, including the `availableReplicas` property, which is an `integer` type.

The `Foo` resource should be namespace scoped.

```bash
root@student-node ~ ➜  cat foo-crd-aecs.yaml 
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: samplecontroller.example.com
spec:
  scope: Cluster
  names:
    kind: Foo
  versions:
    - served: true
      storage: true
      schema:
        # schema used for validation
        openAPIV3Schema:
          type: object
          properties:
            spec:
            status:
              type: object
              properties:
                availableReplicas:
                  type: integer
      # subresources for the custom resource
      subresources:
        # enables the status subresource
        status: {}

root@student-node ~ ➜  vi foo-crd-aecs.yaml 

root@student-node ~ ➜  k apply -f foo-crd-aecs.yaml 
customresourcedefinition.apiextensions.k8s.io/foos.samplecontroller.example.com created

root@student-node ~ ➜  cat foo-crd-aecs.yaml 
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: foos.samplecontroller.example.com                   ## corrected
spec:
  scope: Namespaced                                         # corrected
  group: samplecontroller.example.com ## added
  names:
    kind: Foo
    plural: foos                                             ## added
    singular: foo                                            ## added
  versions:
    - served: true
      storage: true
      name: v1alpha1                                         ## added
      schema:
        # schema used for validation
        openAPIV3Schema:
          type: object
          properties:
            spec:
              ## -------------------------- this portion added
              type: object
              properties:
                deploymentName:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
              ## ---------------------
            status:
              type: object
              properties:
                availableReplicas:
                  type: integer
      # subresources for the custom resource
      subresources:
        # enables the status subresource
        status: {}
```

