# AWS KMS (Key Management Service)

## 1. What is AWS KMS?

AWS KMS is a **managed cryptographic key service** — it creates, stores, rotates,
and controls access to encryption keys used across virtually every AWS service.
KMS never exposes the raw key material; all cryptographic operations happen
**inside FIPS 140-2 validated Hardware Security Modules (HSMs)**.

```
Without KMS:
  Generate key yourself → store in env var or config file →
  key visible to anyone with file access → no audit trail → manual rotation

With KMS:
  Key lives in HSM → never leaves AWS → you never see raw key material
  Every API call: who used which key, when, on what → CloudTrail audit trail
  Automatic or on-demand rotation
  IAM + Key Policy = fine-grained access control per key
```

---

## 2. KMS Key Types ⭐

### By Who Manages the Key

| Type | Who Creates | Who Manages | Cost | Key Rotation |
|------|------------|------------|------|-------------|
| **AWS Managed Key** | AWS | AWS (auto) | Free | Every 3 years (auto) |
| **Customer Managed Key (CMK)** | You | You | $1/month | Yearly (configurable) or on-demand |
| **AWS Owned Key** | AWS | AWS | Free | AWS-managed internally |

```
AWS Managed Key:
  Created automatically when you enable encryption on an AWS service
  Example: aws/s3, aws/ebs, aws/rds, aws/secretsmanager
  You CANNOT:
    → use it in your own application code
    → set key policy
    → rotate manually
    → share cross-account
  Identified by alias: aws/<service>

Customer Managed Key (CMK):  ← what the exam focuses on
  YOU create and control
  Full key policy control
  Can use in your application code via API
  Can share cross-account
  Can import your own key material (BYOK)
  Cost: $1/month/key + $0.03/10,000 API calls

AWS Owned Key:
  Completely internal to AWS
  Multiple accounts share same AWS-owned keys (you can't see them)
  Example: some DynamoDB encryption uses AWS-owned keys
  Not visible in your account
```

### By Cryptographic Algorithm

| Key Type | Algorithms | Use Cases |
|----------|-----------|----------|
| **Symmetric** (default) | AES-256-GCM | Encrypt/decrypt data, envelope encryption, most AWS integrations |
| **Asymmetric RSA** | RSA 2048/3072/4096 | Encryption (OAEP-SHA1/256), digital signing |
| **Asymmetric ECC** | P-256, P-384, P-521, secp256k1 | Digital signing, key agreement (no encryption) |
| **HMAC** | HMAC-SHA-224/256/384/512 | Message authentication codes (MAC) |

```
Symmetric key (most common):
  Same key encrypts AND decrypts
  Private — never leaves KMS, never transmitted
  All AWS service integrations use symmetric keys
  Can only be used for: Encrypt, Decrypt, GenerateDataKey

Asymmetric key:
  Public key: downloadable (you can share it freely)
  Private key: stays in KMS (never exported)
  Use: external party encrypts with your public key → you decrypt with private key in KMS
       OR: you sign data with private key → anyone verifies with public key
  Can be used for: Encrypt/Decrypt OR Sign/Verify (not both on same key)

HMAC key: [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html)
  Symmetric but only for MAC generation and verification
  Never used for data encryption
```

---

## 3. Key Material Origin

Where the cryptographic material actually comes from:

```
AWS_KMS (default):
  KMS generates key material inside its HSMs
  Most secure — never leaves HSM boundary
  Supports automatic rotation

EXTERNAL (Bring Your Own Key — BYOK):
  You generate key material outside AWS → import into KMS
  Use case: compliance requiring you retain original key material outside AWS
  Automatic rotation NOT supported (you manually import new material)
  On-demand rotation: YES (from April 2026 release) [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)
  Deletion: you can delete key material from AWS → key becomes unusable
  Responsibility: you manage source key material security

AWS_CLOUDHSM:
  Key material generated in YOUR dedicated CloudHSM cluster
  For highest compliance requirements (FIPS 140-3 Level 3)
  You own and manage the HSM cluster

EXTERNAL_KEY_STORE (XKS):
  Key material lives in YOUR on-premises HSM or third-party key manager
  KMS proxies to your external key store for cryptographic operations
  For air-gapped environments where key material must never touch AWS
```

---

## 4. Key Rotation ⭐

```
Automatic rotation (symmetric CMKs with AWS_KMS origin only): [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)
  Default: ENABLED, rotates yearly (365 days)
  Configurable: 90–2,560 days
  What rotates: the backing key material (cryptographic secret)
  What stays the SAME: key ID, key ARN, alias, key policy
  → Applications need ZERO changes after rotation

How decryption works after rotation: [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)
  Old data encrypted with key material version 1
  → KMS tracks which version encrypted what (via encrypted ciphertext metadata)
  → Automatically uses correct version to decrypt — transparent to caller
  Key ID/ARN unchanged → your application just calls Decrypt() as normal

On-demand rotation: [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)
  Available for:
    Symmetric CMKs (AWS_KMS origin)
    Symmetric CMKs with EXTERNAL origin (BYOK) ← NEW
    Symmetric multi-region keys (EXTERNAL origin) ← NEW
  Trigger immediately regardless of schedule:
    aws kms rotate-key-on-demand --key-id alias/my-key

Automatic rotation NOT supported for: [tocconsulting](https://tocconsulting.fr/best-practices/kms-security)
  Asymmetric keys (RSA, ECC) ← manual only
  HMAC keys                   ← manual only
  Keys with imported material  ← on-demand only (no auto schedule)
  AWS managed keys             ← AWS rotates these every 3 years

Manual rotation workaround (for unsupported types):
  Create a NEW key → update the alias to point to new key
  → Applications using alias: alias/my-key see no change
  Old key: kept for decrypting old ciphertext → disable but don't delete
```

---

## 5. Envelope Encryption ⭐

The **standard pattern** for encrypting large data with KMS:

```
Problem: KMS Encrypt API only accepts up to 4 KB of plaintext
Solution: encrypt the data with a local data key → encrypt the data key with KMS

Envelope Encryption flow:
  1. Call KMS GenerateDataKey(KeyId=my-cmk)
     → Returns: PlaintextDataKey (in memory) + EncryptedDataKey (by CMK)
  2. Encrypt your data (any size) using PlaintextDataKey locally (AES-256)
  3. Store: EncryptedData + EncryptedDataKey together (e.g., in S3 object)
  4. IMMEDIATELY discard PlaintextDataKey from memory

To decrypt:
  1. Read EncryptedData + EncryptedDataKey from storage
  2. Call KMS Decrypt(CiphertextBlob=EncryptedDataKey)
     → Returns: PlaintextDataKey (requires IAM permission + key policy)
  3. Decrypt your data locally using PlaintextDataKey
  4. IMMEDIATELY discard PlaintextDataKey from memory

Why envelope encryption:
  Data never sent to KMS (only the small data key is)
  Network transfer of large data avoided
  KMS only handles small key material (fast, cheap)
  Offline decryption possible (if you already have the data key)
  This is exactly what AWS SDK Encryption Client and S3 CSE use
```

```
AWS services that use envelope encryption internally:
  S3 SSE-KMS:           S3 generates data key → encrypts object locally → stores encrypted key in S3
  EBS encryption:       KMS generates data key → EC2 uses it locally → EBS stores encrypted key
  Secrets Manager:      KMS-generated data key encrypts the secret value
  Lambda env vars:      KMS CMK encrypts environment variables
```

---

## 6. Key Policies ⭐

Key policies are the **primary access control mechanism for KMS keys** —
IAM policies alone are NOT sufficient; the key policy must also allow access:

```yaml
# Minimal key policy (every KMS key must have this or similar):
{
  "Sid": "Enable IAM User Permissions",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:root"   # account root
  },
  "Action": "kms:*",
  "Resource": "*"
}
# This allows IAM policies in this account to control access to this key
# Without this: IAM policies CANNOT grant access to this key, even for account root
# Grant specific IAM role permission to use key:
{
  "Sid": "AllowAppEncryption",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:role/MyAppRole"
  },
  "Action": ["kms:GenerateDataKey", "kms:Decrypt"],
  "Resource": "*"
}
# Grant another AWS account access (cross-account):
{
  "Sid": "AllowCrossAccountUse",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT-B:root"
  },
  "Action": ["kms:Decrypt", "kms:GenerateDataKey"],
  "Resource": "*"
}
# Account B must ALSO have IAM policy allowing kms:Decrypt — both needed
```

### Key Policy Separation of Duties

```
Key Administrator:
  kms:Create*, kms:Describe*, kms:Enable*, kms:List*, kms:Put*,
  kms:Update*, kms:Revoke*, kms:Disable*, kms:Delete*, kms:ScheduleKeyDeletion
  → Can manage but typically NOT decrypt data

Key User:
  kms:Encrypt, kms:Decrypt, kms:ReEncrypt*, kms:GenerateDataKey*
  → Can use key for crypto but cannot modify key settings

Best practice: different IAM roles for key management vs key usage
```

---

## 7. KMS Key Aliases

```
Human-readable name for a key:
  alias/my-production-database-key
  alias/my-s3-encryption-key

Benefits:
  Application uses alias → key can be rotated (alias updated to new key)
  → No ARN change needed in application config

Commands:
  aws kms create-alias --alias-name alias/my-key --target-key-id <key-id>
  aws kms update-alias --alias-name alias/my-key --target-key-id <new-key-id>
  aws kms delete-alias --alias-name alias/my-key
```

---

## 8. Multi-Region Keys

```
Problem: data encrypted in us-east-1 → want to decrypt in eu-west-1
Standard key: impossible — KMS keys are regional

Multi-region key:
  Primary key:  us-east-1 (mrk-abc123...)
  Replica keys: eu-west-1, ap-southeast-1 (same key ID prefix: mrk-)
  → All replicas are cryptographically identical
  → Ciphertext encrypted in us-east-1 can be decrypted in eu-west-1
  → No need to re-encrypt data when accessing from another region

Use cases:
  Global DynamoDB tables: encrypt/decrypt in any region
  Disaster recovery: primary fails → decrypt data in DR region
  Multi-region active-active: same data served and encrypted across regions

Rotation for multi-region keys: [docs.aws.amazon](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)
  Primary key rotated → replicas automatically updated
  On-demand rotation propagates to all replica keys
```

---

## 9. AWS KMS + Services Integration

```
S3 (SSE-KMS):
  PutObject: S3 generates data key from CMK → encrypts object → stores encrypted key
  GetObject: S3 calls KMS Decrypt → gets data key → decrypts object
  Bucket key: enable to reduce KMS API calls by 99% (bucket-level data key)

EBS:
  Volume encryption at creation: kms:GenerateDataKey → data key → encrypts volume
  Snapshot: encrypted with same CMK (or re-encrypt with new CMK)
  Cross-account snapshot share: share snapshot → re-encrypt with target account's CMK

RDS:
  Enable at database creation (CANNOT encrypt existing unencrypted RDS) [mindmeshacademy](https://www.mindmeshacademy.com/certifications/aws/aws-certified-cloudops-engineer-associate/study-guide/5-2-1-encryption-at-rest-kms-key-types-and-policies)
  Workaround: create encrypted snapshot → restore to new encrypted instance
  Read replicas: encrypted with same CMK as primary
  Cross-region replica: must encrypt with key in destination region

Lambda:
  Environment variable encryption: uses aws/lambda or your CMK
  Client-side encryption: use KMS to encrypt env vars before upload

Secrets Manager:
  Encrypted with aws/secretsmanager (AWS managed) by default
  Or specify your CMK for additional control

CloudTrail:
  Log file encryption: specify CMK → CloudTrail encrypts log files
  Only accounts with access to CMK can read log files
```

---

## 10. KMS Pricing

```
Customer Managed Keys:
  $1.00/month per CMK (prorated by the hour)
  Free: AWS managed keys (aws/<service>)

API Requests:
  Symmetric encrypt/decrypt:   $0.03 per 10,000 requests
  Asymmetric operations:       $0.03–$0.15 per 10,000 requests (varies by algorithm)
  Data key generation:         $0.03 per 10,000 requests
  HMAC:                        $0.03 per 10,000 requests

Free tier:
  20,000 requests/month free
  AWS managed key operations: free

S3 Bucket Keys:
  Reduce KMS API calls by ~99% (one data key per bucket per hour)
  → Dramatically reduces KMS cost for S3-heavy workloads
  Enable: S3 bucket → Properties → Default encryption → Enable Bucket Key
```

---

## 11. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| IAM policy alone controls KMS key access | KMS requires **both key policy AND IAM policy** — key policy must enable IAM permissions first |
| Rotating a CMK changes its ARN/ID | Rotation changes **only key material** — ARN, ID, alias stay the same |
| Old data must be re-encrypted after rotation | KMS **transparently decrypts** with the correct version — no re-encryption needed |
| Asymmetric keys support automatic rotation | Asymmetric, HMAC, and imported-material keys **cannot auto-rotate** — manual only |
| KMS Encrypt works on files of any size | KMS Encrypt max = **4 KB** — use envelope encryption for larger data |
| Deleting a CMK is reversible immediately | CMK deletion has a **7–30 day waiting period** — schedule deletion, then cancel if needed |
| AWS Managed Keys can be used in your app code | AWS Managed Keys **cannot be called directly** from your application — use CMKs |
| Existing RDS can be encrypted with KMS | Must encrypt **at creation** — unencrypted RDS: snapshot → copy with encryption → restore |
---

## 12. Interview Questions Checklist

- [ ] Three key management types — who creates/manages each? Cost?
- [ ] Symmetric vs Asymmetric — which supports automatic rotation?
- [ ] What is key rotation? What stays the same after rotation?
- [ ] What is envelope encryption? Why is it needed? Walk through the full flow
- [ ] What is the KMS Encrypt API size limit? (4 KB)
- [ ] Key policy vs IAM policy — which takes precedence? (both required)
- [ ] How do you enable cross-account KMS key access?
- [ ] EXTERNAL key material — what is BYOK? Does it support auto-rotation?
- [ ] How do you encrypt an existing unencrypted RDS instance?
- [ ] What is a multi-region key? When do you need one?
