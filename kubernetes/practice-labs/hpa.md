## Q1
```bash
cluster1-controlplane ~ ➜  k autoscale deployment web-ui-deployment -n ck1967 --name web-ui-hpa --cpu-percent 65 --min 2 --max 12 -o yaml > 5.yaml

cluster1-controlplane ~ ➜  vi 5.yaml 

cluster1-controlplane ~ ➜  k explain hpa.spec.behavior --recursive 
GROUP:      autoscaling
KIND:       HorizontalPodAutoscaler
VERSION:    v2

FIELD: behavior <HorizontalPodAutoscalerBehavior>


DESCRIPTION:
    behavior configures the scaling behavior of the target in both Up and Down
    directions (scaleUp and scaleDown fields respectively). If not set, the
    default HPAScalingRules for scale up and scale down are used.
    HorizontalPodAutoscalerBehavior configures the scaling behavior of the
    target in both Up and Down directions (scaleUp and scaleDown fields
    respectively).
    
FIELDS:
  scaleDown     <HPAScalingRules>
    policies    <[]HPAScalingPolicy>
      periodSeconds     <integer> -required-
      type      <string> -required-
      value     <integer> -required-
    selectPolicy        <string>
    stabilizationWindowSeconds  <integer>
  scaleUp       <HPAScalingRules>
    policies    <[]HPAScalingPolicy>
      periodSeconds     <integer> -required-
      type      <string> -required-
      value     <integer> -required-
    selectPolicy        <string>
    stabilizationWindowSeconds  <integer>

cluster1-controlplane ~ ➜  vi 5.yaml 

cluster1-controlplane ~ ➜  k replace -f 5.yaml --force
Error from server (BadRequest): HorizontalPodAutoscaler in version "v1" cannot be handled as a HorizontalPodAutoscaler: strict decoding error: unknown field "spec.behavior"

cluster1-controlplane ~ ✖ cat 5.yaml 
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  creationTimestamp: "2025-09-14T13:34:09Z"
  name: web-ui-hpa
  namespace: ck1967
  resourceVersion: "3730"
  uid: 11352250-74f6-4878-9d07-a715e6f5bc3e
spec:
  behavior:
    scaleUp:
      policies:
        - periodSeconds: 45
          type: Percent    
          value: 20
    scaleDown:
      policies:
        - periodSeconds: 60
          type: Percent
          value: 10
  maxReplicas: 12
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-ui-deployment
  targetCPUUtilizationPercentage: 65

status:
  currentReplicas: 0
  desiredReplicas: 0

cluster1-controlplane ~ ➜  rm -f 5.yaml 

cluster1-controlplane ~ ➜  vi 5.yaml

cluster1-controlplane ~ ➜  k apply -f 5.yaml 
horizontalpodautoscaler.autoscaling/web-ui-hpa created

cluster1-controlplane ~ ➜  k get hpa -n ck1967 
NAME         REFERENCE                      TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-ui-hpa   Deployment/web-ui-deployment   cpu: 0%/65%   2         12        2          19s
```

Sweetheart ❤️ the error is because you’re using the wrong API version.

👉 The `behavior` field was **introduced in `autoscaling/v2beta2`** and carried into **`autoscaling/v2`**.
It does **not** exist in `autoscaling/v1`.

That’s why `kubectl` says:

```
HorizontalPodAutoscaler in version "v1" cannot be handled as a HorizontalPodAutoscaler: 
strict decoding error: unknown field "spec.behavior"
```

### 🔹 Fix: Change `apiVersion` to `autoscaling/v2`

Here’s the corrected YAML:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-ui-hpa
  namespace: ck1967
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-ui-deployment

  minReplicas: 2
  maxReplicas: 12

  # This replaces targetCPUUtilizationPercentage in v1
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 65

  behavior:
    scaleUp:
      policies:
      - type: Percent
        value: 20
        periodSeconds: 45
    scaleDown:
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```


⚠️ Note:

* `autoscaling/v1` only supports `minReplicas`, `maxReplicas`, and `targetCPUUtilizationPercentage`.
* Advanced features (`behavior`, multiple metrics, scaleDown policies, etc.) require `autoscaling/v2`.

---

## Q2

Create a Horizontal Pod Autoscaler (HPA) named `backend-hpa` in the `cka0841` namespace for a `deployment` named `backend-deployment`, which scales based on **CPU usage**. The HPA should be configured with:

- A minimum of 3 replicas
- A maximum of 15 replicas

Specify a resource-based metric to scale based on CPU utilization, maintaining the average utilization of the pods at **50%** of the requested CPU.

Additionally, set the scale-down behavior to allow:

- Reducing the number of pods by a maximum of 5 at a time
- Or by 20% of the current replica count, whichever results in fewer pods being removed
- This should occur within a time frame of `60 seconds`.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: cka0841
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 3
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      policies:
      - type: Pods
        value: 5
        periodSeconds: 60
      - type: Percent
        value: 20
        periodSeconds: 60
      selectPolicy: Min
```
