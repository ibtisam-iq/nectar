# AWS Secrets Manager

## 1. What is Secrets Manager?

AWS Secrets Manager is a **fully managed secrets storage and rotation service** —
it stores sensitive values (database passwords, API keys, OAuth tokens),
injects them into applications at runtime, and automatically rotates them
on a schedule without any application downtime.

```
Without Secrets Manager:
  DB password hardcoded in app code → committed to Git → visible to all devs
  Rotation: manual → update .env → redeploy → downtime → error-prone

With Secrets Manager:
  App calls GetSecretValue at runtime → password never in code or env vars
  Rotation: automatic → new password generated → DB updated → secret updated
  App retries failed DB connection → gets latest secret → reconnects ✅
  Audit: every GetSecretValue call logged in CloudTrail
```

---

## 2. Secret Types and Storage

```
Any key-value JSON or plain string:
  Database credentials:
    {
      "username": "admin",
      "password": "s3cr3tP@ss!",
      "engine": "postgres",
      "host": "prod-db.xyz.rds.amazonaws.com",
      "port": 5432,
      "dbname": "myapp"
    }

  API keys:
    {
      "stripe_secret_key": "sk_live_abc123...",
      "stripe_webhook_secret": "whsec_xyz789..."
    }

  OAuth tokens:
    { "access_token": "...", "refresh_token": "..." }

  Plain string: "my-api-key-value-here"

Encryption:
  Default: encrypted with aws/secretsmanager (AWS managed KMS key) — free
  Custom: specify your own CMK for additional control and audit
  → Secret value never stored in plaintext

Size limit: 65,536 bytes per secret value
```

---

## 3. Versioning ⭐

Secrets Manager maintains multiple versions of a secret simultaneously:

```
Version stages (labels):
  AWSCURRENT  → currently active version (GetSecretValue returns this)
  AWSPENDING  → newly created version during rotation (not yet validated)
  AWSPREVIOUS → previous AWSCURRENT (kept as fallback after rotation)

Version lifecycle during rotation:
  1. createSecret phase:
     → New version created with AWSPENDING label
     → AWSCURRENT still serving old credentials → zero downtime

  2. setSecret phase:
     → New credentials applied to target (DB password changed)
     → Both old and new credentials work at this moment

  3. testSecret phase:
     → Test that AWSPENDING credentials actually work

  4. finishSecret phase:
     → AWSPENDING → promoted to AWSCURRENT
     → Old AWSCURRENT → becomes AWSPREVIOUS
     → Applications now get new credentials on next GetSecretValue call
```

---

## 4. Automatic Rotation ⭐

Secrets Manager rotates secrets **using a Lambda function** you define or
use from AWS-managed templates:

```
Rotation schedule options:
  Every N days:   rotate every 30 days
  Cron expression: "cron(0 0 1 * ? *)" → 1st of every month at midnight
  Immediate + scheduled: rotate now AND on schedule

Built-in managed rotation (no Lambda code needed): [aws.amazon](https://aws.amazon.com/blogs/security/rotate-amazon-rds-database-credentials-automatically-with-aws-secrets-manager/)
  Amazon RDS (MySQL, PostgreSQL, Aurora, Oracle, SQL Server)
  Amazon Redshift
  Amazon DocumentDB
  → AWS provides pre-built Lambda functions for these
  → Select: "Managed rotation" → AWS creates Lambda automatically

Custom rotation (Lambda): [docs.aws.amazon](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotate-secrets_lambda.html)
  For: any other service (API keys, OAuth tokens, custom databases)
  You write Lambda with four handler phases (see below)

Lambda rotation must be in the SAME VPC as the database
(or use Secrets Manager VPC endpoint if Lambda is in private subnet)
```

### Four-Phase Rotation Lambda

```python
def lambda_handler(event, context):
    step = event['Step']

    if step == 'createSecret':
        # Generate new credentials (new random password)
        # Store as AWSPENDING version of the secret
        new_password = generate_password()
        client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps({...new_credentials...}),
            VersionStages=['AWSPENDING']
        )

    elif step == 'setSecret':
        # Apply new credentials to the actual service
        # (ALTER USER in MySQL, update API provider, etc.)
        apply_to_database(new_credentials)

    elif step == 'testSecret':
        # Verify new credentials actually work
        # Raise exception if test fails → rotation aborted, AWSPENDING discarded
        test_database_connection(new_credentials)

    elif step == 'finishSecret':
        # Mark AWSPENDING as AWSCURRENT, old current becomes AWSPREVIOUS
        client.update_secret_version_stage(
            SecretId=arn,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token,
            RemoveFromVersionId=current_version
        )
```

### RDS Read Replica Rotation

```
Challenge: rotating primary DB credentials → read replicas also need update
  Step 1: Lambda rotates primary instance password
  Step 2: Lambda applies same new password to all read replicas
  Step 3: Test connectivity on primary AND all replicas
  Step 4: Promote new secret version to AWSCURRENT

Both primary + replica credential updates happen atomically in one rotation cycle [aws.amazon](https://aws.amazon.com/blogs/database/automate-amazon-rds-credential-rotation-with-aws-secrets-manager-for-primary-instances-with-read-replicas/)
```

---

## 5. Application Integration ⭐

### Retrieve Secret in Application Code

```python
import boto3, json

def get_db_credentials():
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(
        SecretId='production/database/master'
    )
    return json.loads(response['SecretString'])
# Usage
creds = get_db_credentials()
conn = psycopg2.connect(
    host=creds['host'],
    port=creds['port'],
    dbname=creds['dbname'],
    user=creds['username'],
    password=creds['password']
)
```

### Handle Rotation Gracefully

```python
# Robust pattern — retry on auth failure (rotation may have just happened)
import time

def get_connection(retries=2):
    for attempt in range(retries):
        try:
            creds = get_secret()      # always get latest from Secrets Manager
            return connect(creds)
        except AuthenticationError:
            if attempt < retries - 1:
                time.sleep(1)         # brief wait then retry with fresh secret
                continue
            raise
# Why: during rotation, AWSPENDING becomes AWSCURRENT
# Your cached credentials → connection fails → retry → get new secret → success
```

### ECS / Lambda Integration

```
ECS Task Definition:
  secrets:
    - name: DB_PASSWORD
      valueFrom: "arn:aws:secretsmanager:us-east-1:123:secret:prod/db/password"
  → Injected as environment variable at container startup
  → Container gets fresh value on each new task launch

Lambda:
  environment:
    Variables:
      SECRET_ARN: !Sub "arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:prod/db"
  In code: boto3.client('secretsmanager').get_secret_value(SecretId=os.environ['SECRET_ARN'])

Better pattern for Lambda (avoid cold start latency):
  Cache secret in module scope (outside handler)
  Refresh if secret is > 5 minutes old
  → Avoids Secrets Manager API call on every invocation
```

---

## 6. Cross-Account Access

```
Account A owns the secret: production/database/master
Account B (Lambda in B) needs to read it

Steps:
  1. Secret resource policy in Account A:
     {
       "Effect": "Allow",
       "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B:role/MyLambdaRole" },
       "Action": "secretsmanager:GetSecretValue",
       "Resource": "*"
     }

  2. KMS key policy in Account A (if custom CMK used):
     {
       "Effect": "Allow",
       "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B:role/MyLambdaRole" },
       "Action": ["kms:Decrypt", "kms:DescribeKey"],
       "Resource": "*"
     }

  3. IAM policy in Account B for MyLambdaRole:
     {
       "Effect": "Allow",
       "Action": "secretsmanager:GetSecretValue",
       "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT-A:secret:production/database/master"
     }

  All three required for cross-account secrets access
```

---

## 7. Secrets Manager vs SSM Parameter Store ⭐

| Feature | Secrets Manager | SSM Parameter Store |
|---------|----------------|-------------------|
| **Primary purpose** | Secrets lifecycle management | Configuration + secrets storage |
| **Automatic rotation** | ✅ Built-in (Lambda-based) | ❌ Manual or custom Lambda |
| **Cost** | $0.40/secret/month + $0.05/10K API calls | Free (Standard) / $0.05/advanced param/month |
| **Versioning** | Automatic (AWSCURRENT/PENDING/PREVIOUS) | Up to 100 versions, manual |
| **Cross-account** | ✅ Resource policy | Limited (Advanced tier) |
| **Max value size** | 65,536 bytes | 4 KB (Standard) / 8 KB (Advanced) |
| **Hierarchical naming** | Flat (use / in name as convention) | Native hierarchies: `/app/prod/db-pass` |
| **GetParameters by path** | ❌ | ✅ GetParametersByPath |
| **Native RDS integration** | ✅ Managed rotation templates | ❌ |
| **Use case** | Database passwords, API keys needing rotation | App config, feature flags, non-rotating secrets |

```
Rule of thumb:
  Needs rotation?          → Secrets Manager
  Static config values?    → SSM Parameter Store (free, simpler)
  Hierarchical config?     → SSM Parameter Store
  Database credentials?    → Secrets Manager always
```

---

## 8. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| GetSecretValue in a Lambda on every request | **Cache the secret** (module scope) + refresh after TTL — avoid per-invocation API calls |
| Rotation causes downtime | Rotation is **zero-downtime** — AWSPENDING created before AWSCURRENT swapped |
| Lambda rotation function can be in any VPC | Rotation Lambda **must be in the same VPC** as the target DB (or use Secrets Manager VPC endpoint) |
| Old secret versions deleted after rotation | **AWSPREVIOUS version kept** — applications can still decrypt with it during transition |
| Secrets Manager encrypts with its own key | Default: uses **aws/secretsmanager** (AWS managed KMS key) — or specify your CMK |
| SSM Parameter Store can auto-rotate | Parameter Store has **no built-in rotation** — must build custom Lambda rotation |
| Resource policy alone allows cross-account | Requires: **secret resource policy + KMS key policy + IAM policy** in target account — all three |

---

## 9. Interview Questions Checklist

- [ ] How does automatic rotation work? Name the four Lambda phases
- [ ] What are AWSCURRENT, AWSPENDING, AWSPREVIOUS?
- [ ] Why is AWSPREVIOUS kept after rotation? (apps may still use old version briefly)
- [ ] How do you handle rotation gracefully in your application?
- [ ] Secrets Manager vs SSM Parameter Store — when to use each?
- [ ] What three things are needed for cross-account secrets access?
- [ ] Where must the rotation Lambda be deployed? (same VPC as target DB)
- [ ] How to rotate RDS with read replicas?
