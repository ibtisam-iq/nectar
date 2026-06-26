# End-to-end Fargate Deployment (portfolio image)

!!! info "Goal"
    Deploy the existing image `ghcr.io/ibtisam-iq/ibtisam-iq:latest` on ECS Fargate behind an ALB.  
    Use only AWS CLI.  
    Keep roles, log groups, and networking explicit.

## 1. Set variables

```bash
REGION=us-east-1

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# VPC and subnets
VPC_ID="vpc-05a6419ca06bf9bc3"

# Public subnets for ALB
PUB1="subnet-089e228cf7ee80566"
PUB2="subnet-0541e370b746c6f49"

# Private subnets for ECS tasks
# Note: Since the Tasks are assigned private IPs, these subnets MUST have a route
# to a NAT Gateway to pull the public image from ghcr.io.
PRI1="subnet-0385bb3d51caafd0f"
PRI2="subnet-00bac6899d334ced1"

# Names
CLUSTER_NAME="ibtisam-iq"
APP_NAME="portfolio"
LOG_GROUP="/ecs/portfolio"
ALB_SG_NAME="alb-sg-portfolio"
ECS_SG_NAME="ecs-sg-portfolio"

# Container
CONTAINER_IMAGE="ghcr.io/ibtisam-iq/ibtisam-iq:latest"
CONTAINER_PORT=8080
ALB_LISTEN_PORT=80
```

## 2. Create cluster

```bash
aws ecs create-cluster \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION"
```

## 3. Create execution role

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

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

sleep 10

EXEC_ROLE_ARN=$(aws iam get-role \
  --role-name ecsTaskExecutionRole \
  --query 'Role.Arn' \
  --output text)
```

## 4. Create security groups

```bash
# ALB SG
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name "$ALB_SG_NAME" \
  --description "ALB SG for $APP_NAME" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$ALB_SG_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# ECS SG
ECS_SG_ID=$(aws ec2 create-security-group \
  --group-name "$ECS_SG_NAME" \
  --description "ECS SG for $APP_NAME" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$ECS_SG_ID" \
  --protocol tcp \
  --port "$CONTAINER_PORT" \
  --source-group "$ALB_SG_ID"
```

## 5. Create log group

```bash
aws logs create-log-group \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" || true
```

## 6. Register Task Definition

```bash
cat > portfolio-taskdef.json <<EOF
{
  "family": "${APP_NAME}-task",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "${EXEC_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "${APP_NAME}",
      "image": "${CONTAINER_IMAGE}",
      "portMappings": [
        { "containerPort": ${CONTAINER_PORT}, "protocol": "tcp" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP}",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "${APP_NAME}"
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

## 7. Optional: run a one-off Task for testing

```bash
aws ecs run-task \
  --cluster "$CLUSTER_NAME" \
  --launch-type FARGATE \
  --task-definition "${APP_NAME}-task" \
  --network-configuration "awsvpcConfiguration={
    subnets=[$PUB1,$PUB2],
    securityGroups=[$ECS_SG_ID],
    assignPublicIp=ENABLED
  }" \
  --count 1
```

Use this step to verify:

- Task moves to RUNNING.
- Logs appear in `/ecs/portfolio`.
- Application responds on port 8080 through the task’s public IP.

## 8. Create Target Group and ALB

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name "${APP_NAME}-tg" \
  --protocol HTTP \
  --port "${CONTAINER_PORT}" \
  --vpc-id "$VPC_ID" \
  --target-type ip \
  --health-check-path "/" \
  --query 'TargetGroups.TargetGroupArn' \
  --output text)

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "${APP_NAME}-alb" \
  --subnets "$PUB1" "$PUB2" \
  --security-groups "$ALB_SG_ID" \
  --query 'LoadBalancers.LoadBalancerArn' \
  --output text)

aws elbv2 wait load-balancer-available \
  --load-balancer-arns "$ALB_ARN"

aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port "$ALB_LISTEN_PORT" \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"
```

## 9. Create Service

```bash
aws ecs create-service \
  --cluster "$CLUSTER_NAME" \
  --service-name "${APP_NAME}-svc" \
  --task-definition "${APP_NAME}-task" \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[$PRI1,$PRI2],
    securityGroups=[$ECS_SG_ID],
    assignPublicIp=DISABLED
  }" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=${APP_NAME},containerPort=${CONTAINER_PORT}" \
  --region "$REGION"
```

## 10. Get ALB DNS name

```bash
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers.DNSName' \
  --output text)

echo "Portfolio app URL:"
echo "  http://$ALB_DNS"
```

At this point:

- Tasks run inside private subnets without public IPs.
- ALB runs in public subnets.
- ALB routes traffic to Tasks on port 8080.
- Logs go to `/ecs/portfolio` in CloudWatch Logs.

## 11. Alternative: Testing without a Load Balancer (Hack)

!!! tip "Testing directly via Run Task"
    To test the deployment without creating the Target Group and Application Load Balancer, run a standalone task. However, since the ECS security group (`$ECS_SG_ID`) was configured to only accept traffic from the ALB, patch it to allow direct internet access.

**Step 1: Patch the ECS Security Group**
Allow inbound traffic on port 8080 (or all traffic) from anywhere (`0.0.0.0/0`):

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$ECS_SG_ID" \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
```

**Step 2: Run a Task in Public Subnets**
Use `run-task` to launch the container in the public subnets with a public IP enabled:

```bash
aws ecs run-task \
  --cluster "$CLUSTER_NAME" \
  --launch-type FARGATE \
  --task-definition "${APP_NAME}-task" \
  --network-configuration "awsvpcConfiguration={
    subnets=[$PUB1,$PUB2],
    securityGroups=[$ECS_SG_ID],
    assignPublicIp=ENABLED
  }" \
  --count 1
```

Once the task is running, find its Public IP in the AWS Console (or via CLI) and access the application directly at `http://<PUBLIC_IP>:8080`.
