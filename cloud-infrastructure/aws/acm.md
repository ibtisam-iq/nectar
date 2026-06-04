# AWS Certificate Manager (ACM)

## 1. What is ACM?

AWS Certificate Manager is a **fully managed TLS/SSL certificate service** —
it provisions, stores, auto-renews, and deploys public and private X.509
certificates to AWS services, eliminating the cost, complexity, and risk
of manual certificate management.

```
Without ACM:
  Buy cert from CA (Comodo, DigiCert) → $50–$300/year
  Generate CSR → submit → wait → download → manually install on each server
  Set calendar reminder 30 days before expiry → manually renew → redeploy → risk of forgetting

With ACM:
  Request cert → verify domain ownership → attached to ALB/CloudFront →
  ACM auto-renews → no expiry risk, no manual install, FREE for public certs
```

---

## 2. Certificate Types ⭐

### Public Certificates (Free)

```
Issued by: Amazon Trust Services (ACM's own CA — trusted by all major browsers)
Cost: FREE — no charge for public ACM certificates
Usage: HTTPS on internet-facing resources
Validity: 198 days (renewed automatically before expiry) [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/email-validation.html)

Can be used with:
  Elastic Load Balancers (ALB, NLB, CLB)
  CloudFront distributions
  API Gateway (custom domain HTTPS)
  AWS AppSync
  Amazon Cognito
  Elastic Beanstalk (via ALB)

Cannot be used with (exported to):
  EC2 instances directly (ACM does NOT allow private key export for public certs)
  On-premises servers
  Self-managed NGINX/Apache (use ACM Private CA or Let's Encrypt instead)
```

### Private Certificates (ACM Private CA)

```
Issued by: YOUR private Certificate Authority (CA) that you create in ACM
Cost: $400/month per private CA (prorated hourly) + $0.75 per certificate
Usage: internal services, microservices, internal load balancers

Can be:
  Exported (private key downloadable) → use on EC2, on-premises, containers
  Used on same AWS services as public certs

Private CA hierarchy:
  Root CA → Subordinate CA → End-entity certificates
  Typical: create one Root CA → create Subordinate CA for each environment

Use cases:
  Internal APIs with mutual TLS (mTLS)
  IoT device certificates
  Internal microservice communication
  On-premises servers needing trusted certificates
```

---

## 3. Domain Validation Methods ⭐

You must prove you own the domain before ACM issues a certificate:

### DNS Validation (Strongly Recommended)

```
Process:
  1. Request certificate for ibtisam-iq.com
  2. ACM provides a CNAME record:
     _abc123.ibtisam-iq.com → _xyz789.acm-validations.aws
  3. Add CNAME record to your DNS (Route 53 or any other registrar)
  4. ACM queries DNS → finds CNAME → validates ownership → issues certificate
  5. Certificate issued ✅

With Route 53: one-click automatic CNAME creation in console

Renewal behavior: [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/dns-renewal-validation.html)
  ACM checks CNAME is still present 60 days before expiry
  If CNAME exists AND certificate attached to AWS service → renews automatically
  NO manual action ever needed ✅

Wildcard certificates:
  Request: *.ibtisam-iq.com
  ACM adds ONE CNAME for wildcard → covers all subdomains
  Covers: api.ibtisam-iq.com, cdn.ibtisam-iq.com, www.ibtisam-iq.com
  Does NOT cover: ibtisam-iq.com (apex) or sub.sub.ibtisam-iq.com
  Request both: *.ibtisam-iq.com AND ibtisam-iq.com → two SANs → same CNAME [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/dns-renewal-validation.html)
```

### Email Validation (Not Recommended)

```
Process:
  1. Request certificate
  2. ACM sends validation email to domain owner addresses:
     admin@ibtisam-iq.com, administrator@, hostmaster@, postmaster@, webmaster@
     + WHOIS-registered contact email
  3. Domain owner clicks approval link in email
  4. Certificate issued ✅

Validity: 198 days [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/email-validation.html)

Renewal:
  ACM begins sending renewal emails 45 days before expiry [oneuptime](https://oneuptime.com/blog/post/2026-02-12-request-manage-ssl-tls-certificates-acm/view)
  Domain owner MUST click link in renewal email → NOT automatic ❌
  Risk: email missed → cert expires → HTTPS breaks

Why avoid email validation:
  Human action required for renewal
  Email may go to shared mailbox, spam folder
  DNS validation is always better
```

### DNS vs Email Validation

| | DNS Validation | Email Validation |
|--|--------------|-----------------|
| Renewal | Fully automatic ✅ | Manual (email approval) ❌ |
| Setup | Add one CNAME record | Click email link |
| Route 53 integration | One-click automatic | N/A |
| Wildcard support | ✅ | ✅ |
| Recommended | ✅ Always | ❌ Avoid |

---

## 4. ACM Regional Behavior ⭐

```
ACM certificates are REGIONAL — they only work in the region where created:
  Certificate in us-east-1 → only works with ALB in us-east-1
  Certificate in eu-west-1 → only works with ALB in eu-west-1

EXCEPTION — CloudFront:
  CloudFront is a GLOBAL service
  CloudFront certificate MUST be created in us-east-1 ONLY
  Even if your origin is in eu-west-1 → CloudFront cert must be in us-east-1

Rule to remember:
  ALB / API Gateway / Beanstalk → certificate in SAME region as the resource
  CloudFront → certificate ALWAYS in us-east-1 (regardless of anything)
```

---

## 5. Attaching Certificates ⭐

### ALB (Application Load Balancer)

```
ALB listener:
  Port 443 (HTTPS) → select ACM certificate
  → TLS termination at ALB → traffic to targets can be HTTP or HTTPS

Multiple certificates on one ALB listener:
  Add multiple certificates → ALB uses SNI to select correct cert per domain
  → One ALB handles multiple domains (api.example.com + www.example.com)
  SNI (Server Name Indication): client sends hostname in TLS handshake →
  ALB selects matching certificate

HTTPS redirect:
  Port 80 listener → Action: Redirect to HTTPS → Port 443
  → HTTP users automatically upgraded to HTTPS
```

### CloudFront

```
Distribution settings → Alternate domain names (CNAMEs):
  Add: cdn.ibtisam-iq.com
  Select: ACM certificate from us-east-1 that covers cdn.ibtisam-iq.com
  Viewer Protocol Policy: Redirect HTTP to HTTPS (recommended)

CloudFront TLS versions:
  Security policy: TLSv1.2_2021 (recommended — disables older TLS versions)
  Minimum TLS 1.2 required for PCI-DSS compliance
```

### API Gateway

```
Custom domain name: api.ibtisam-iq.com
  Edge-optimized: certificate in us-east-1 (served via CloudFront)
  Regional: certificate in same region as API
Select ACM certificate → Route 53 Alias → API Gateway domain name
```

---

## 6. ACM Certificate Renewal ⭐

```
Validity period: 198 days [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/dns-renewal-validation.html)

DNS-validated — fully automatic renewal: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-request-manage-ssl-tls-certificates-acm/view)
  At 60 days before expiry:
    ACM checks: certificate is attached to an AWS service? AND CNAME record present?
    If both YES → renews automatically → new certificate issued same ARN ✅
    If certificate NOT attached to service → renewal may not happen
    → Always keep certificate attached (even for standby use)

Email-validated — manual renewal required: [docs.aws.amazon](https://docs.aws.amazon.com/acm/latest/userguide/email-validation.html)
  45 days before expiry → ACM sends renewal email
  Domain owner must click link → re-validate
  Missing email → certificate expires → production HTTPS breaks

Renewal best practices:
  1. Always use DNS validation
  2. Keep ACM certificate attached to ALB/CloudFront (even during maintenance)
  3. Verify Route 53 CNAME validation records are NOT accidentally deleted
  4. Set CloudWatch alarm on CertificateExpiryInDays metric:
     aws cloudwatch put-metric-alarm \
       --alarm-name "ACMCertExpiry" \
       --metric-name DaysToExpiry \
       --namespace AWS/CertificateManager \
       --dimensions Name=CertificateArn,Value=<arn> \
       --threshold 45 \
       --comparison-operator LessThanThreshold
  5. Use AWS Health Events for cert expiry notifications
```

---

## 7. ACM Private CA

```
Your own private Certificate Authority hierarchy:
  Root CA: ibtisam-iq-root-ca
    └── Subordinate CA: ibtisam-iq-internal-prod
         ├── ALB internal cert: internal-api.corp.ibtisam-iq.com
         ├── EC2 instance cert: worker-01.corp.ibtisam-iq.com
         └── IoT device cert: device-abc123.iot.ibtisam-iq.com

Features:
  Export private key → install on EC2, containers, on-premises
  Issue certificates programmatically (IssueCertificate API)
  Short-lived certificates (hours or days → reduced revocation need)
  Mutual TLS (mTLS): client must present cert → server verifies client identity

Cost: $400/month per private CA (expensive — share one CA per environment)

mTLS use case (API Gateway + Private CA):
  Issue client certs to trusted API callers
  API Gateway: enable mutual TLS → only requests with valid client cert accepted
  → Strongest authentication for B2B APIs and internal microservices
```

---

## 8. ACM + Route 53 Integration ⭐

```
For DNS validation with Route 53:
  Request certificate → ACM shows CNAME to add
  → Route 53 hosted zone → "Create records in Route 53" button
  → One click → CNAME record added → validation completes in minutes

For CloudFront + ACM:
  CloudFront distribution domain: d1234abcdef.cloudfront.net
  Custom domain: cdn.ibtisam-iq.com
  Route 53: Alias A record → d1234abcdef.cloudfront.net
  Certificate: us-east-1 ACM cert covering cdn.ibtisam-iq.com

For ALB + ACM:
  ALB DNS: my-alb-1234567890.us-east-1.elb.amazonaws.com
  Custom domain: api.ibtisam-iq.com
  Route 53: Alias A record → my-alb-1234567890.us-east-1.elb.amazonaws.com
  Certificate: us-east-1 ACM cert covering api.ibtisam-iq.com
  (or eu-west-1 cert for ALB in eu-west-1)
```

---

## 9. KMS + Secrets Manager + ACM Together ⭐

```
Production architecture layers:

1. ACM (Transport Layer):
   Secures HTTPS connection between client and ALB/CloudFront
   Certificates auto-renewed — never expire
   TLS terminates at ALB → inside VPC can use HTTP

2. Secrets Manager (Application Secrets Layer):
   DB passwords, API keys stored and auto-rotated
   App calls GetSecretValue at runtime → never hardcoded
   Encrypted with KMS CMK

3. KMS (Data Encryption Layer):
   CMK encrypts: Secrets Manager secrets, EBS volumes, RDS databases,
                 S3 objects, CloudTrail logs, Lambda env vars
   Key policy + IAM = granular access control
   Every usage logged to CloudTrail

Request flow:
  Browser → HTTPS (ACM cert) → ALB → Lambda/ECS
  Lambda → GetSecretValue (Secrets Manager) → GetSecretValue decrypts via KMS
  Lambda → INSERT to RDS (encrypted at rest via KMS CMK)
  Everything logged to CloudTrail → alerts via Security Hub
```

---

## 10. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| ACM public certificates cost money | Public ACM certificates are **completely free** |
| ACM certs can be installed on EC2 directly | Public ACM certs **cannot be exported** — use on ALB/CloudFront only; use Private CA for EC2 |
| CloudFront cert can be in any region | CloudFront cert **must be in us-east-1** — no exceptions |
| DNS-validated certs renew automatically forever | Auto-renewal requires cert **attached to an AWS service** AND CNAME still in DNS |
| Email-validated certs also auto-renew | Email validation requires **manual click to renew** — DNS validation always preferred |
| One domain = one ACM certificate needed | Use **Subject Alternative Names (SANs)** — one cert covers multiple domains/subdomains |
| Wildcard cert *.ibtisam-iq.com covers apex domain | Wildcard does NOT cover apex — request **both *.ibtisam-iq.com AND ibtisam-iq.com** |
| ACM certificate validity is 1 year | ACM certs are valid for **198 days** (not 365) — but auto-renewal handles this transparently |
| Domain must be registered on AWS / Route 53 | ACM only needs DNS ownership proof — **any DNS provider works** (Cloudflare, Namecheap, GoDaddy) |

---

## 11. Interview Questions Checklist

- [ ] Public vs Private certificates — key differences? Cost?
- [ ] DNS vs Email validation — which is recommended and why?
- [ ] How does DNS validation auto-renewal work? What two conditions are required?
- [ ] Where MUST CloudFront certificates be created? (us-east-1)
- [ ] ACM certificate validity period? (198 days)
- [ ] Can you export a public ACM certificate private key? (NO)
- [ ] What is ACM Private CA? When is it needed?
- [ ] Wildcard cert — does *.example.com cover example.com? (NO)
- [ ] What CloudWatch metric monitors certificate expiry?
- [ ] Does the domain need to be on Route 53 for ACM? (NO — any DNS provider works with DNS validation)

---

## 12. CLI Workflow — Certificate with Third-Party DNS (Cloudflare) + EKS

This is the real-world flow when your domain lives on **Cloudflare** (or any non-Route 53 DNS) and you want HTTPS on an EKS service via ALB Ingress.

### The key insight

ACM does **not** care where your domain is registered or who manages your DNS.
It only needs you to add one CNAME record to prove ownership.
Route 53 is never required — Cloudflare, Namecheap, GoDaddy all work identically.

```
ACM (AWS)                      Cloudflare (your DNS)
    │                                  │
    │  "Prove you own                   │
    │   ibtisam-iq.com"                │
    │──────────────────────────────────▶│
    │                                  │
    │  You add a CNAME                  │
    │  record ACM gives you             │
    │◀──────────────────────────────────│
    │                                  │
    │  ACM polls DNS every few minutes  │
    │  CNAME found ✅                    │
    │  Certificate issued ✅             │
```

---

### Step 1 — Request the certificate

```bash
export CERT_ARN=$(aws acm request-certificate \
  --domain-name retail-microservices.ibtisam-iq.com \
  --validation-method DNS \
  --region us-east-1 \
  --query 'CertificateArn' \
  --output text)

echo $CERT_ARN
# arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

> The certificate ARN is returned immediately but stays in **PENDING_VALIDATION** until you add the DNS record in Step 2.

---

### Step 2 — Retrieve the CNAME record ACM needs

```bash
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'
```

Example output:

```json
{
    "Name":  "_abc123def456.retail-microservices.ibtisam-iq.com.",
    "Type":  "CNAME",
    "Value": "_xyz789qrs012.acm-validations.aws."
}
```

> The `Name` always starts with `_` — this is ACM's proof-of-ownership token.
> Cloudflare strips trailing dots automatically; ignore them.

---

### Step 3 — Add the CNAME in Cloudflare

Go to **Cloudflare Dashboard → ibtisam-iq.com → DNS → Add Record**:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | `_abc123def456.retail-microservices` (subdomain part only, without `.ibtisam-iq.com`) |
| Target | `_xyz789qrs012.acm-validations.aws` |
| Proxy status | ☁️ **DNS only (grey cloud)** — NOT orange proxied |

> ⚠️ **Critical:** The validation CNAME **must be grey cloud (DNS only)** in Cloudflare.
> If it is orange (proxied), Cloudflare rewrites the DNS response and ACM
> cannot see the real CNAME value → validation never completes and the
> certificate stays stuck in PENDING_VALIDATION forever.

---

### Step 4 — Wait for validation

```bash
# Blocks until certificate status = ISSUED (usually 1–5 minutes)
aws acm wait certificate-validated \
  --certificate-arn $CERT_ARN \
  --region us-east-1

# Verify
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.Status'
# "ISSUED" ✅
```

> The validation CNAME must **stay in Cloudflare permanently** — ACM checks it
> every 60 days to auto-renew the certificate. Deleting it breaks renewal.

---

### Step 5 — Use the ARN in your EKS Helm values

In your service's `values.yaml` (e.g., `ui-values.yaml`):

```yaml
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    alb.ingress.kubernetes.io/certificate-arn: "<paste $CERT_ARN here>"
    alb.ingress.kubernetes.io/group.name: ecom-eks
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  tls: []
  hosts:
    - "retail-microservices.ibtisam-iq.com"
```

**What each annotation does:**

| Annotation | What it controls | Why this value |
|-----------|-----------------|----------------|
| `scheme: internet-facing` | ALB placed in public subnets | Users on the internet must reach the UI |
| `target-type: ip` | ALB routes directly to Pod IPs | EKS uses VPC CNI — pods have real VPC IPs, no NodePort hop needed |
| `healthcheck-path: /actuator/health/liveness` | URL ALB pings to test pod health | Spring Boot exposes this endpoint; using `/` may return redirect/404 |
| `certificate-arn` | TLS certificate for HTTPS | ACM cert you just issued; TLS terminates at ALB, pod sees plain HTTP |
| `group.name: ecom-eks` | Merges all services onto one shared ALB | Avoids creating one ALB per service (~$18/month each) |
| `backend-protocol: HTTP` | Protocol ALB uses to talk to pods | Pods speak HTTP; ALB handles TLS termination |
| `listen-ports` | Ports ALB opens to internet | Port 80 catches HTTP (for redirect); port 443 serves HTTPS |
| `ssl-redirect: '443'` | Redirects HTTP → HTTPS automatically | Any `http://` request gets a 301 to `https://` |
| `tls: []` | Empty — not used with ALB | ALB/ACM manage TLS; `tls:` block is the nginx/cert-manager pattern only |

---

### Step 6 — Deploy

```bash
kubectl create ns ui --dry-run=client -o yaml | kubectl apply -f -

helm show values oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 > helm-values/ui-values.yaml

# Edit helm-values/ui-values.yaml — set endpoints, ingress, certificate-arn, host

helm upgrade -i ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 \
  -f helm-values/ui-values.yaml \
  -n ui
```

Verify the pod is running:

```bash
kubectl get po -n ui
kubectl get ingress -n ui
```

Expected `kubectl get ingress` output:

```
NAME   CLASS   HOSTS                                    ADDRESS                                              PORTS
ui     alb     retail-microservices.ibtisam-iq.com     k8s-ecomeks-xxxxxxxx.us-east-1.elb.amazonaws.com   80, 443
```

---

### Step 7 — Point the domain to the ALB in Cloudflare

Copy the `ADDRESS` from `kubectl get ingress` and add a second DNS record in Cloudflare:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | `retail-microservices` |
| Target | `k8s-ecomeks-xxxxxxxx.us-east-1.elb.amazonaws.com` |
| Proxy status | 🟠 Orange (proxied) — optional, your choice |

> Unlike the validation CNAME (which must be grey), this record can be orange-proxied
> if you want Cloudflare's DDoS protection and CDN in front of your ALB.

---

### Complete end-to-end flow

```
Browser
  │
  │  http://retail-microservices.ibtisam-iq.com
  ▼
Cloudflare DNS → resolves to ALB hostname
  │
  │  HTTP :80
  ▼
AWS ALB (internet-facing, group: ecom-eks)
  │  ssl-redirect annotation → 301 to HTTPS
  │
  │  HTTPS :443  ← ACM certificate terminates TLS here
  ▼
AWS ALB Target Group (target-type: ip)
  │  backend-protocol: HTTP
  │  healthcheck: /actuator/health/liveness (only healthy pods receive traffic)
  ▼
UI Pod (port 80, Java/Spring Boot)
```

---

### CLI quick-reference (all 7 steps)

```bash
# 1. Request certificate
export CERT_ARN=$(aws acm request-certificate \
  --domain-name retail-microservices.ibtisam-iq.com \
  --validation-method DNS --region us-east-1 \
  --query 'CertificateArn' --output text)

# 2. Get CNAME to add in Cloudflare
aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# 3. Add CNAME in Cloudflare (grey cloud / DNS only) — manual step in UI

# 4. Wait for ISSUED
aws acm wait certificate-validated --certificate-arn $CERT_ARN --region us-east-1

# 5. Paste $CERT_ARN into ui-values.yaml under certificate-arn annotation

# 6. Deploy
helm upgrade -i ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 -f helm-values/ui-values.yaml -n ui

# 7. Get ALB hostname → add CNAME in Cloudflare (orange cloud optional)
kubectl get ingress -n ui
```
