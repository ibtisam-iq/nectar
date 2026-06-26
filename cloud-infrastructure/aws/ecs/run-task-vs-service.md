# Run Task versus Service

!!! info "Goal"
    Use Task Definition in two ways:  
    - Run Task for quick tests or one-off jobs.  
    - Service for long-running workloads, ALB, and auto scaling.

## Run Task

!!! example "Run Task behaviour"
    Run a Task to test a Task Definition or execute a one-off job.

Typical command:

```bash
aws ecs run-task \
  --cluster ibtisam-iq \
  --launch-type FARGATE \
  --task-definition portfolio-task \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-abc,subnet-def],
    securityGroups=[sg-ecs],
    assignPublicIp=ENABLED
  }" \
  --count 1
```

Understand parameters:

- `--cluster`: choose Cluster.
- `--task-definition`: choose Task Definition revision.
- `--launch-type`: choose Fargate or EC2.
- `--network-configuration`: choose subnets and security groups.
- `assignPublicIp=ENABLED`: assign a public IP for direct access.
- `--count`: run a small number of Tasks.

Behaviour:

- Start Tasks once.
- Allow Tasks to exit or fail without replacement.
- Do not attach Tasks to load balancers.
- Use for testing images, validating database connectivity, running batch jobs.

## Service

!!! example "Service behaviour"
    Use a Service to maintain a desired number of Tasks and integrate with ALB.

Typical command:

```bash
aws ecs create-service \
  --cluster ibtisam-iq \
  --service-name portfolio-svc \
  --task-definition portfolio-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-private-a,subnet-private-b],
    securityGroups=[sg-ecs],
    assignPublicIp=DISABLED
  }" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=portfolio,containerPort=8080"
```

Behaviour:

- Create Tasks from the Task Definition.
- Maintain `desired-count` by replacing failed Tasks.
- Integrate with ALB or NLB.
- Support auto scaling policies.

Compare to Kubernetes:

- Service (ECS) ≈ Deployment + Service (LB) + HPA.
- `desired-count` ≈ Deployment `replicas`.
- Auto scaling policies ≈ HPA rules.

## Choosing between Run Task and Service

!!! tip "Practical rules"
    - Use **Run Task** for short-lived experiments and manual tests.  
    - Use **Service** for long-lived workloads that must always be available.  
    - Use **Run Task** as the equivalent of `kubectl run` or `kubectl port-forward`.  
    - Use **Service** as the equivalent of a Deployment fronted by a Service and Ingress.

Summary:

- Run Task = no self-healing, no LB, no auto scaling.
- Service = self-healing, LB capable, auto scaling available.
