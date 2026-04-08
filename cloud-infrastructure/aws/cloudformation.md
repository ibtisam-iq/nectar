# AWS CloudFormation

## 1. What is CloudFormation?

CloudFormation is AWS's **native Infrastructure-as-Code (IaC) service**.
You describe your entire infrastructure in a template (JSON or YAML),
and CloudFormation provisions, manages, updates, and deletes all those
resources as a single unit called a **stack**.

```
Without IaC:
  Click console → create VPC → create subnets → create EC2 → configure SG
  → manual, error-prone, not repeatable, not versionable

With CloudFormation:
  Write template.yaml → cfn creates everything in correct order automatically
  → identical environment every time
  → version-controlled in Git
  → destroy everything with one command
```

### CloudFormation vs Terraform

| | CloudFormation | Terraform |
|--|---------------|-----------|
| Vendor | AWS native | HashiCorp (multi-cloud) |
| Language | JSON / YAML | HCL |
| State file | AWS-managed (no state file to manage) | Local or remote `.tfstate` |
| Drift detection | ✅ Built-in | ✅ Via `terraform plan` |
| Multi-cloud | ❌ AWS only | ✅ AWS, Azure, GCP, etc. |
| Cost | Free | Free (OSS) / paid (Enterprise) |
| Registry | CloudFormation Registry | Terraform Registry |

> CloudFormation is free — you pay only for the AWS resources it creates,
> not for CloudFormation itself.

---

## 2. Template Anatomy ⭐

A CloudFormation template has up to **10 top-level sections**.
Only `Resources` is mandatory — everything else is optional:

```yaml
AWSTemplateFormatVersion: "2010-09-09"   # Optional — always this value if included

Description: "My application stack"      # Optional — human description

Metadata:                                # Optional — UI hints, CFN-specific config
  AWS::CloudFormation::Interface:
    ParameterGroups: ...

Parameters:                              # Optional — inputs at deploy time
  EnvironmentName:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]
    Description: "Deployment environment"

Mappings:                                # Optional — static lookup tables
  RegionAMI:
    us-east-1:
      AMI: ami-0abcdef1234567890
    eu-west-1:
      AMI: ami-0987654321fedcba

Conditions:                              # Optional — conditional resource creation
  IsProduction: !Equals [!Ref EnvironmentName, prod]

Transform:                               # Optional — macros (SAM uses this)
  - AWS::Serverless-2016-10-31

Resources:                               # REQUIRED — actual AWS resources
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "${EnvironmentName}-my-bucket"
      VersioningConfiguration:
        Status: Enabled

Outputs:                                 # Optional — values to export or display
  BucketName:
    Value: !Ref MyBucket
    Export:
      Name: !Sub "${AWS::StackName}-BucketName"
```

---

## 3. Template Sections In Depth

### Parameters

```yaml
Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
    AllowedValues:
      - t3.micro
      - t3.small
      - t3.medium
    Description: EC2 instance size

  DBPassword:
    Type: String
    NoEcho: true       # ← value hidden in console and logs (for secrets)
    MinLength: 8
    MaxLength: 64
    Description: RDS master password

  VpcId:
    Type: AWS::EC2::VPC::Id       # ← AWS-specific parameter type
    Description: Select existing VPC

  SubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
    Description: Select subnets

# AWS-specific types: auto-validated and shown as dropdowns in console
# Types: AWS::EC2::VPC::Id, AWS::EC2::Subnet::Id, AWS::EC2::KeyPair::KeyName,
#        AWS::EC2::SecurityGroup::Id, AWS::SSM::Parameter::Value<String>
```

### Mappings

```yaml
Mappings:
  EnvironmentConfig:
    dev:
      InstanceType: t3.micro
      MinSize: 1
      MaxSize: 2
    prod:
      InstanceType: t3.large
      MinSize: 3
      MaxSize: 10

# Usage:
Resources:
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      MinSize: !FindInMap [EnvironmentConfig, !Ref EnvironmentName, MinSize]
      MaxSize: !FindInMap [EnvironmentConfig, !Ref EnvironmentName, MaxSize]
```

### Conditions

```yaml
Conditions:
  IsProduction:  !Equals [!Ref EnvironmentName, prod]
  IsNotProd:     !Not [!Condition IsProduction]
  IsProdOrStage: !Or
    - !Equals [!Ref EnvironmentName, prod]
    - !Equals [!Ref EnvironmentName, staging]

# Use conditions on resources, properties, outputs:
Resources:
  ProdAlarm:
    Type: AWS::CloudWatch::Alarm
    Condition: IsProduction    # ← only created in prod
    Properties: ...

  Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !If [IsProduction, t3.large, t3.micro]  # ← conditional value
```

### Outputs and Exports

```yaml
Outputs:
  VpcId:
    Description: "VPC ID for cross-stack use"
    Value: !Ref MyVPC
    Export:
      Name: !Sub "${AWS::StackName}-VpcId"   # must be unique across account+region

  LoadBalancerDns:
    Description: "ALB DNS name"
    Value: !GetAtt ALB.DNSName
    # No Export → visible in console + CLI, not importable by other stacks
```

---

## 4. Intrinsic Functions ⭐

Functions built into CloudFormation YAML/JSON for dynamic values:

| Function | Purpose | Example |
|----------|---------|---------|
| `!Ref` | Reference parameter or resource's default attribute | `!Ref MyBucket` → bucket name |
| `!GetAtt` | Get a specific attribute of a resource | `!GetAtt ALB.DNSName` |
| `!Sub` | String substitution with variables | `!Sub "arn:aws:s3:::${BucketName}/*"` |
| `!Join` | Join list with delimiter | `!Join [",", [a, b, c]]` → `"a,b,c"` |
| `!Split` | Split string into list | `!Split [",", "a,b,c"]` → `[a, b, c]` |
| `!Select` | Pick item from list by index | `!Select [0, !GetAZs ""]` |
| `!FindInMap` | Look up value in Mappings section | `!FindInMap [Map, Key1, Key2]` |
| `!If` | Conditional value | `!If [Condition, TrueValue, FalseValue]` |
| `!And` | Logical AND of conditions | `!And [!Condition A, !Condition B]` |
| `!Or` | Logical OR of conditions | `!Or [!Condition A, !Condition B]` |
| `!Not` | Negate a condition | `!Not [!Condition IsProduction]` |
| `!Equals` | Check equality | `!Equals [!Ref Env, prod]` |
| `!ImportValue` | Import exported output from another stack | `!ImportValue "NetworkStack-VpcId"` |
| `!GetAZs` | List of AZs in region | `!GetAZs ""` → current region AZs |
| `!Base64` | Base64-encode string (EC2 UserData) | `!Base64 "#!/bin/bash\nyum update -y"` |
| `!Cidr` | Generate CIDR block list | `!Cidr [!Ref VpcCidr, 6, 8]` |

```yaml
# Common real-world examples:

# EC2 UserData (must be Base64):
UserData:
  !Base64 |
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd

# Sub with multiple variables:
Value: !Sub "arn:aws:iam::${AWS::AccountId}:role/${RoleName}"

# GetAtt:
LoadBalancerDns: !GetAtt ApplicationLoadBalancer.DNSName
BucketArn:       !GetAtt MyBucket.Arn
InstanceIP:      !GetAtt MyEC2.PublicIp

# Select first AZ:
AvailabilityZone: !Select [0, !GetAZs ""]
```

### Pseudo Parameters (Built-in, Always Available)

```yaml
AWS::AccountId       → "123456789012"
AWS::Region          → "us-east-1"
AWS::StackName       → "my-app-prod"
AWS::StackId         → full stack ARN
AWS::Partition       → "aws" (or "aws-cn", "aws-us-gov")
AWS::NoValue         → removes property (used with !If to conditionally omit)
AWS::URLSuffix       → "amazonaws.com"
```

---

## 5. Stacks ⭐

A **stack** is a deployed instance of a template — the live collection of
all resources CloudFormation manages from that template.

```
Template (YAML file) → deploy → Stack (live AWS resources)

Stack states:
  CREATE_IN_PROGRESS   → stack creation running
  CREATE_COMPLETE      → all resources created ✅
  CREATE_FAILED        → creation failed
  ROLLBACK_IN_PROGRESS → rolling back due to failure
  ROLLBACK_COMPLETE    → all resources deleted after failed creation
  UPDATE_IN_PROGRESS   → update running
  UPDATE_COMPLETE      → update succeeded ✅
  UPDATE_ROLLBACK_*    → update failed, rolling back
  DELETE_IN_PROGRESS   → deletion running
  DELETE_COMPLETE      → all resources deleted ✅
  DELETE_FAILED        → deletion failed (usually resource has deletion protection)
```

### Stack Creation and Rollback

```
Create:
  CloudFormation reads template → creates resources in dependency order
  If any resource fails → automatic rollback (delete all created resources)
  Rollback can be disabled (useful for debugging failures)

Update:
  CloudFormation computes diff between old and new template
  Only changes affected resources
  Three update types per resource:
    No interruption:       update in place, no downtime
    Some interruption:     brief restart required
    Replacement:           new resource created, old deleted
                           ← breaks ARN/ID references (important!)

Delete:
  CloudFormation deletes all resources in reverse dependency order
  Resources with DeletionPolicy: Retain → kept after stack delete
  Resources with DeletionPolicy: Snapshot → snapshot taken before delete
  Resources with DeletionPolicy: Delete → deleted (default)
```

### DeletionPolicy and UpdateReplacePolicy

```yaml
Resources:
  Database:
    Type: AWS::RDS::DBInstance
    DeletionPolicy: Snapshot      # Take snapshot before deleting
    UpdateReplacePolicy: Snapshot # Take snapshot before replacing
    Properties: ...

  LogBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain        # Keep bucket even after stack deletion
    Properties: ...

  TempEC2:
    Type: AWS::EC2::Instance
    DeletionPolicy: Delete        # Delete with stack (default)
    Properties: ...
```

---

## 6. Change Sets ⭐

A change set is a **preview of what will change** before you execute an update:

```
Workflow:
  1. Modify template
  2. Create change set (upload new template)
     → CloudFormation computes: what resources will be Added / Modified / Removed
     → No actual changes yet
  3. Review change set output
  4. Execute change set → changes applied
     OR
     Delete change set → no changes made

Change set shows per-resource:
  Action:         Add / Modify / Remove
  Logical ID:     MyEC2Instance
  Resource Type:  AWS::EC2::Instance
  Replacement:    True / False / Conditional  ← CRITICAL — True = resource recreated
  Scope:          Properties, Tags, Metadata
  Details:        Which specific properties change
```

### Drift-Aware Change Sets (New — November 2025)

```
Problem:
  Someone manually changes a security group rule via console (outside CloudFormation)
  → Stack is "drifted" (actual state ≠ template state)
  → Traditional change set doesn't know about manual change
  → Deploy template → manual change silently overwritten

Solution: Drift-Aware Change Set [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/drift-aware-change-sets.html)
  Three-way comparison:
    Actual state       → what the resource looks like RIGHT NOW in AWS
    Previous deployment state → what CloudFormation last deployed
    Desired state      → what your new template defines

  Shows: "This deploy will REVERT this manual change made during incident response"
  CLI: --deployment-mode REVERT_DRIFT [aws.amazon](https://aws.amazon.com/blogs/devops/safely-handle-configuration-drift-with-cloudformation-drift-aware-change-sets/)

  Benefits:
    Preview overwrites of drift before they happen
    Rollback uses actual pre-deployment state (not previous template state)
    Systematic drift reconciliation — bring drifted resources back to template

Use drift-aware change sets for:
  Production deployments where manual hotfixes may have been applied
  Compliance environments where all changes must be tracked
```

---

## 7. Drift Detection ⭐

Drift = when a resource's actual configuration differs from its CloudFormation template:

```
Cause: manual changes made outside CloudFormation
  → DevOps manually edits security group rule via console
  → Someone uses CLI to change instance type
  → Auto-scaling changes resource count

Detect drift:
  CloudFormation console → Stack → Actions → Detect Drift
  CLI: aws cloudformation detect-stack-drift --stack-name my-stack
  → CloudFormation reads actual resource configuration
  → Compares with template-expected configuration
  → Reports: DRIFTED / IN_SYNC / NOT_CHECKED

Drift status per resource:
  DRIFTED     → resource configuration differs from template
  IN_SYNC     → matches template
  NOT_CHECKED → resource type doesn't support drift detection (not all do)
  DELETED     → resource was deleted outside CloudFormation

What drift detection finds:
  ✅ SG rule added/removed manually
  ✅ EC2 instance type changed manually
  ✅ S3 bucket policy modified manually
  ❌ Resource created outside CloudFormation (not tracked)

Fix drift:
  Option 1: Update template to match actual state → re-deploy (accepts the drift)
  Option 2: Revert manual change → re-apply CloudFormation (rejects the drift)
  Option 3: Use drift-aware change set → handles automatically [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/drift-aware-change-sets.html)
```

---

## 8. Nested Stacks ⭐

A nested stack is a stack created **inside** another stack using
`AWS::CloudFormation::Stack` resource:

```yaml
# Parent template (root stack)
Resources:
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/my-bucket/network.yaml
      Parameters:
        VpcCidr: "10.0.0.0/16"
        EnvironmentName: !Ref EnvironmentName

  AppStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/my-bucket/app.yaml
      Parameters:
        VpcId: !GetAtt NetworkStack.Outputs.VpcId    # ← use output from sibling nested stack
        SubnetIds: !GetAtt NetworkStack.Outputs.SubnetIds
```

```
Benefits:
  Reuse templates across multiple parent stacks
  Break 500-resource limit per stack (each nested stack has its own limit)
  Isolate and organize: network stack, security stack, app stack, db stack
  Single deploy command deploys everything (parent triggers all children)

Management:
  Update parent → CloudFormation propagates to affected child stacks
  Delete parent → all nested stacks and their resources deleted together
```

---

## 9. Cross-Stack References ⭐

Share resource values **between independently managed stacks** using exports:

```yaml
# Stack A — Network Stack (creates and exports VPC)
Outputs:
  VpcId:
    Value: !Ref MyVPC
    Export:
      Name: !Sub "${AWS::StackName}-VpcId"      # must be globally unique in region

  PublicSubnet1:
    Value: !Ref PublicSubnet1
    Export:
      Name: !Sub "${AWS::StackName}-PublicSubnet1"
```

```yaml
# Stack B — App Stack (imports VPC from Stack A)
Resources:
  AppSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !ImportValue "NetworkStack-VpcId"   # ← import by export name
```

```
Rules:
  Export name must be UNIQUE per region per account
  Stack A cannot be deleted while Stack B imports from it
    → must delete Stack B first (or remove the ImportValue reference)
  Cannot update an export name if it is currently imported anywhere

Cross-stack vs Nested Stack:
  Cross-stack: independently managed stacks, deployed separately, loosely coupled
  Nested:      deployed as one unit via parent, tightly coupled

Use cross-stack when: [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html)
  Network team manages VPC stack, app team manages app stack separately
  Multiple different app stacks all share the same network stack
  Teams have different deployment cadences

Use nested stack when:
  All stacks deploy together as one application unit
  Sharing output values within the same application boundary
```

---

## 10. StackSets ⭐

StackSets deploy the **same stack to multiple AWS accounts and/or regions**
with a single operation:

```
StackSet = template + deployment targets

Deployment targets:
  Specific accounts:
  Organizational Units: All accounts in OU "Production"
  All accounts in Org:  entire AWS Organization

Deployment regions:
  ["us-east-1", "eu-west-1", "ap-southeast-1"]

Result:
  Template deployed to each account × each region combination
  → 3 accounts × 3 regions = 9 stack instances

Use cases:
  Deploy GuardDuty or CloudTrail to every account in the organization
  Deploy IAM baseline roles to all accounts
  Deploy security baseline (Config rules, SCPs backup) organization-wide
  Enforce consistent tagging or config standards
```

### StackSet Permissions Models

```
Self-managed:
  You create IAM roles manually in admin + target accounts
  AWSCloudFormationStackSetAdministrationRole (admin account)
  AWSCloudFormationStackSetExecutionRole (each target account)

Service-managed (with AWS Organizations):
  AWS handles IAM automatically
  ✅ Deploy to entire OU or entire Org with one click
  ✅ Automatic deployment to new accounts added to OU
  ✅ Recommended for Organizations setups
```

---

## 11. CloudFormation Registry and Custom Resources

### Registry

CloudFormation Registry lets you use **third-party and custom resource types**
just like built-in AWS resources:

```
Public registry:   AWS-published extensions + community/partner resources
Private registry:  your own resource types for internal tools

Example: deploy a GitHub repository resource, a Datadog monitor,
         a PagerDuty service — all from CloudFormation YAML
```

### Custom Resources

For AWS resources CloudFormation doesn't natively support, use Custom Resources:

```yaml
Resources:
  MyCustomResource:
    Type: Custom::DatabaseSetup      # Custom:: prefix or AWS::CloudFormation::CustomResource
    Properties:
      ServiceToken: !GetAtt CustomLambda.Arn   # ← Lambda to invoke
      DatabaseName: myapp
      Environment: !Ref EnvironmentName

# CloudFormation invokes the Lambda with:
#   RequestType: Create / Update / Delete
#   ResourceProperties: your Properties above
# Lambda does the work → sends success/failure response back to CloudFormation
# CloudFormation waits (up to 1 hour) for Lambda's callback response
```

---

## 12. Stack Policies

Prevent accidental updates to critical resources:

```json
{
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "Update:Replace",
      "Resource": "LogicalResourceId/ProductionDatabase"
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "Update:*",
      "Resource": "*"
    }
  ]
}
```

```
Actions:
  Update:Modify   → in-place property change
  Update:Replace  → replacement (new resource, new ID)
  Update:Delete   → resource deletion
  Update:*        → all update types

Stack policy applies only during stack updates
Does NOT prevent direct AWS Console/CLI changes (that's drift)
```

---

## 13. Resource Dependencies ⭐

CloudFormation automatically determines deployment order from `!Ref` and `!GetAtt`.
For dependencies that aren't expressed through references, use `DependsOn`:

```yaml
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  IGWAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC                   # ← implicit dependency on VPC
      InternetGatewayId: !Ref InternetGateway  # ← implicit dependency on IGW

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    DependsOn: IGWAttachment            # ← explicit: wait for IGW attachment
    Properties:
      VpcId: !Ref VPC

  # CloudFormation order: VPC → IGW (parallel) → IGWAttachment → PublicRouteTable
```

---

## 14. CreationPolicy and WaitConditions

Wait for resources to signal success before CloudFormation marks them complete:

```yaml
Resources:
  AppServer:
    Type: AWS::EC2::Instance
    CreationPolicy:
      ResourceSignal:
        Count: 1
        Timeout: PT10M    # ISO 8601 duration: 10 minutes
    Properties:
      UserData:
        !Base64 |
          #!/bin/bash
          yum install -y aws-cfn-bootstrap
          # ... install application ...
          # Signal success to CloudFormation:
          /opt/aws/bin/cfn-signal -e $? \
            --stack ${AWS::StackName} \
            --resource AppServer \
            --region ${AWS::Region}

# CloudFormation waits up to 10 minutes for signal
# Signal not received → CREATE_FAILED → rollback
# Use for: EC2 bootstrapping, ensuring app is healthy before CloudFormation proceeds
```

---

## 15. CloudFormation Best Practices ⭐

```
1. Use Parameters + Mappings — never hardcode AMI IDs, account IDs, region names
   → AMI IDs differ per region; use SSM Parameter Store for latest AMI:
   Parameters:
     LatestAMI:
       Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
       Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

2. Use DeletionPolicy: Retain or Snapshot on stateful resources
   → Accidental stack deletion doesn't lose your database

3. Use Change Sets before every production update
   → See exactly what changes before executing
   → Catch replacements (true/false) before they happen

4. Use Drift Detection regularly in production [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/detect-drift-stack.html)
   → Detect manual changes before they cause issues

5. Use drift-aware change sets for deployments after incidents [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/drift-aware-change-sets.html)
   → Prevents overwriting emergency hotfixes silently

6. Organize with nested stacks or cross-stack references
   → Never put everything in one giant template
   → Stay within 500 resource limit per stack

7. Store templates in S3 or Git — never deploy from local machine in prod
   → S3 for nested stacks (TemplateURL required)
   → Git for version history and code review

8. Use NoEcho: true for secrets in Parameters
   → Password never shown in console logs
   → Better: use AWS::SecretsManager or AWS::SSM::Parameter::Value

9. Tag all stacks (Environment, Team, CostCenter)
   → Tags propagate to all resources in stack
   → Essential for cost allocation

10. Test with --no-execute-changeset first:
    aws cloudformation deploy ... --no-execute-changeset
    → Creates change set only → review → execute manually
```

---

## 16. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Delete stack to clean up dev resources but forget RDS | Set **DeletionPolicy: Snapshot** on databases — never lose data on stack delete |
| Change sets show "Replacement: True" but execute anyway | **Replacement: True = new resource with new ARN/ID** — downstream references break; plan carefully |
| Export names can be changed freely | Cannot update an export name **while any stack imports it** — must remove all importers first |
| StackSets need manual role creation in every account | Use **service-managed mode with AWS Organizations** — roles auto-created |
| Drift detection fixes the drift | Detection **only reports** drift — you must fix it manually or via drift-aware change set |
| Traditional change set accounts for manual changes | Use **drift-aware change set** to see impact on manually changed resources |
| `DependsOn` is always needed | CloudFormation infers order from `!Ref` and `!GetAtt` automatically — only use `DependsOn` for non-referenced dependencies |
| Nested stacks can reference parent outputs via `!ImportValue` | Nested stacks use `!GetAtt NestedStack.Outputs.Key` — `!ImportValue` is for cross-stack references only |
| CloudFormation is free but expensive | CloudFormation is free — you pay for the **resources it creates**, not the service |
| `!Ref` on any resource returns its ARN | `!Ref` returns the **default identifier** (often Name or ID, not always ARN) — use `!GetAtt Resource.Arn` for ARN |

---

## 17. Interview Questions Checklist

- [ ] What is IaC? How does CloudFormation implement it?
- [ ] What are the 10 template sections? Which is the only mandatory one?
- [ ] What is a stack? What is the difference between a template and a stack?
- [ ] Walk through stack creation — what happens on failure? (Rollback)
- [ ] What are the three update types for resources? Which one breaks downstream references? (Replacement)
- [ ] What is a change set? Walk through the workflow
- [ ] What is drift? What causes it? How do you detect and fix it?
- [ ] What is a drift-aware change set? How is it different from a regular change set?
- [ ] Nested stacks vs cross-stack references — when to use each?
- [ ] How does `!ImportValue` work? What are its limitations?
- [ ] What are StackSets? What are the two permission models?
- [ ] What is DeletionPolicy? Three values? Which for databases?
- [ ] What does `DependsOn` do? When is it needed vs not needed?
- [ ] What is a CreationPolicy? When would you use it?
- [ ] What is a Custom Resource? When would you need one?
- [ ] What does `NoEcho: true` do on a parameter?
- [ ] What are pseudo parameters? Name five.
- [ ] List 10 intrinsic functions and what each does
- [ ] What is a Stack Policy? What does it protect against?
- [ ] What is the resource limit per stack? (500)
