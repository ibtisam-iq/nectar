# Task Definition, IAM, and CloudWatch Logs

!!! info "Goal"
    Capture all dependencies around Task Definitions, IAM roles, and CloudWatch logging.  
    Avoid “task immediately stopped” failures by setting up IAM and log groups correctly.

## Execution role (ecsTaskExecutionRole)

!!! note "Execution role responsibilities"
    Execution role is used by ECS itself, not by the application code.

Responsibilities:

- Pull images from ECR.
- Create or use a CloudWatch log group.
- Create log streams.
- Write container logs to CloudWatch.

Create the execution role:

```bash
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'
```

Attach the managed policy:

```bash
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

Confirm the role:

```bash
aws iam get-role --role-name ecsTaskExecutionRole
```

## Log configuration in Task Definition

!!! info "awslogs driver fields"
    Use the `awslogs` driver with three required options: `awslogs-group`, `awslogs-region`, `awslogs-stream-prefix`.

Example container definition snippet:

```json
"logConfiguration": {
  "logDriver": "awslogs",
  "options": {
    "awslogs-group": "/ecs/portfolio",
    "awslogs-region": "us-east-1",
    "awslogs-stream-prefix": "portfolio"
  }
}
```

Understand behaviour:

- `awslogs-group` points to a CloudWatch Logs group.
- `awslogs-region` must match ECS region.
- `awslogs-stream-prefix` prefixes log stream names.

If the log group does not exist and the execution role does not have `logs:CreateLogGroup`, the Task may fail at log initialization and stop immediately.

!!! warning "AmazonECSTaskExecutionRolePolicy limitation"
    The AWS managed `AmazonECSTaskExecutionRolePolicy` **does not** include the `logs:CreateLogGroup` permission. This is why explicit log group creation is recommended unless manually adding inline policies to the role.

## Creating the CloudWatch log group

!!! example "Create a log group explicitly"
    Create the log group before registering the Task Definition.

```bash
REGION=us-east-1
LOG_GROUP="/ecs/portfolio"

aws logs create-log-group \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" || true

aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP" \
  --region "$REGION"
```

Prefer explicit creation during learning:

- Avoid depending on `awslogs-create-group=true` and implicit log group creation.
- Keep control over naming and retention settings.

## Task Definition minimal fields

!!! note "Minimal Task Definition content"
    Start with the minimal valid Task Definition and extend as needed.

Minimal fields for Fargate:

- `family`
- `requiresCompatibilities: ["FARGATE"]`
- `networkMode: "awsvpc"`
- `cpu`, `memory`
- `executionRoleArn`
- one or more `containerDefinitions`:
  - `name`
  - `image`
  - `portMappings`
  - `logConfiguration`

Example:

```bash
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
EXEC_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT}:role/ecsTaskExecutionRole"

cat > portfolio-taskdef.json <<EOF
{
  "family": "portfolio-task",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "${EXEC_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "portfolio",
      "image": "ghcr.io/ibtisam-iq/ibtisam-iq:latest",
      "portMappings": [
        { "containerPort": 8080, "protocol": "tcp" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/portfolio",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "portfolio"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition \
  --cli-input-json file://portfolio-taskdef.json \
  --region "$REGION"
```

## Network mode inside Task Definition

!!! warning "Network mode is not VPC selection"
    `networkMode` configures how networking works for the Task, but not which VPC or subnet it uses.

For Fargate:

- Set `networkMode` to `awsvpc`.
- Treat this as enabling “each Task gets its own ENI and IP address”.

Actual VPC, subnet, and security groups are only chosen later when running the Task or creating the Service.
