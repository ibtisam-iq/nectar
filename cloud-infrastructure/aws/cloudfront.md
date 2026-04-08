# Amazon CloudFront

## 1. What is CloudFront?

Amazon CloudFront is AWS's **global Content Delivery Network (CDN)**.
It caches your content at **edge locations** around the world — so users
receive responses from a nearby server instead of traveling all the way
to your origin.

```
Without CloudFront:
  User in Lahore → HTTP request → origin server in us-east-1 (Virginia)
  Round-trip distance: ~12,000 km → latency: ~200–300ms

With CloudFront:
  User in Lahore → HTTP request → CloudFront edge in Mumbai (~500 km)
  Cache HIT → response from edge: ~5–20ms ← 10–50× faster
  Cache MISS → edge fetches from origin once → caches → serves next user locally
```

### What CloudFront Does

| Capability | Description |
|-----------|-------------|
| **Content caching** | HTML, CSS, JS, images, video cached at edge |
| **Dynamic acceleration** | Route dynamic requests over AWS backbone (faster than public internet) |
| **DDoS protection** | Shield Standard included free at every edge |
| **WAF integration** | Attach WAF Web ACL for Layer 7 inspection at edge |
| **HTTPS everywhere** | Free TLS certificates via ACM; HTTP→HTTPS redirect |
| **Geo restriction** | Block/allow countries at edge |
| **Edge compute** | Lambda@Edge and CloudFront Functions at edge |
| **Signed URLs/Cookies** | Restrict access to private content |

> CloudFront has **600+ edge locations** across 90+ countries — including
> regional edge caches (larger intermediary caches between edges and origin).

---

## 2. CloudFront Architecture ⭐

```
                        ┌─────────────────────────────┐
                        │     Regional Edge Cache      │
                        │  (larger, fewer locations)   │
                        └──────────────┬──────────────┘
                                       │ (cache miss at edge)
   User (Lahore)                       │
       │                               │
       ▼                               ▼
  ┌─────────────┐             ┌───────────────┐
  │  CloudFront │──cache miss→│  Origin       │
  │  Edge (MUM) │             │  (S3/ALB/EC2) │
  └─────────────┘             └───────────────┘
       │
       ▼
  Cached response
  (served in <20ms)

Cache hierarchy:
  User → Edge Location (L1 cache)
       → Regional Edge Cache (L2 cache, if edge misses)
       → Origin (only if both caches miss)
```

---

## 3. Origins ⭐

An **origin** is where CloudFront fetches content when it has a cache miss.
Multiple origins can exist in one distribution.

### S3 Bucket Origin

```
Use case: static website, media files, large downloads

Origin Access Control (OAC) — recommended (replaces legacy OAI):
  S3 bucket: PRIVATE (Block Public Access = ON)
  CloudFront gets objects via OAC → signs requests with SigV4
  S3 bucket policy: allow only CloudFront service principal

  {
    "Effect": "Allow",
    "Principal": { "Service": "cloudfront.amazonaws.com" },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": {
      "StringEquals": {
        "AWS:SourceArn": "arn:aws:cloudfront::123:distribution/EDFDVBD6EXAMPLE"
      }
    }
  }
  → Users CANNOT bypass CloudFront and access S3 directly ✅
  → Signed URLs and geo restriction enforced properly ✅
```

### Custom Origin (ALB / EC2 / API Gateway / any HTTP server)

```
Any HTTP/HTTPS endpoint:
  ALB (recommended for dynamic apps)
  EC2 instance with public IP
  API Gateway endpoint
  On-premises HTTP server
  Any public URL

Custom headers from CloudFront → origin:
  Add secret header: X-CloudFront-Secret: abc123
  Origin validates header → rejects requests without it
  → Prevents users from bypassing CloudFront and hitting ALB/EC2 directly
```

### Origin Groups (Failover)

```
Primary origin: us-east-1 ALB
Failback origin: eu-west-1 ALB

If primary returns 5xx errors → CloudFront automatically retries on failback
Use case: multi-region active-passive failover for origin
```

---

## 4. Distributions

A **distribution** is the CloudFront configuration unit — it defines
all your origins, behaviors, caching settings, and security settings.

```
Distribution types (now unified — just one type):
  Previously: Web distribution + RTMP (streaming)
  Now: single distribution type handles all content

Distribution gives you a domain:
  d1234abcdef.cloudfront.net
  Map your custom domain: cdn.ibtisam-iq.com → CNAME → d1234abcdef.cloudfront.net
  Or Alias record in Route 53 → d1234abcdef.cloudfront.net
```

---

## 5. Cache Behaviors ⭐

Cache behaviors are **URL-path-based rules** that control how CloudFront
handles different types of requests to different origins:

```
Distribution: ibtisam-iq.com (mapped to CloudFront)

Cache Behaviors (evaluated in order, first match wins):
  Path Pattern: /api/*          → Origin: ALB (dynamic, no cache)
  Path Pattern: /images/*       → Origin: S3 (cache 1 year)
  Path Pattern: /static/*       → Origin: S3 (cache 7 days)
  Path Pattern: * (Default)     → Origin: ALB (cache 1 day)

Each behavior defines independently:
  → Which origin to use
  → Cache policy (TTL, cache key)
  → Origin request policy (headers forwarded to origin)
  → Viewer protocol policy (HTTP only / HTTPS only / redirect)
  → Allowed HTTP methods
  → Lambda@Edge / CloudFront Functions associations
  → Whether to compress (gzip/brotli)
  → Signed URLs/Cookies requirement
```

> You MUST have at least as many cache behaviors as origins
> for every origin to be used. An unused origin is never reached.

---

## 6. Cache Key and TTL ⭐

### Cache Key

The cache key determines what makes a cached object unique.
By default, CloudFront caches based on **URL path only**.

```
Default cache key: URL path
  /images/logo.png → one cached object

Custom cache key (Cache Policy): include additional dimensions
  /products?color=red → cached separately from /products?color=blue
  Authorization header → cached per user (careful — can explode cache)
  Accept-Language header → cached per language

Best practice:
  Include in cache key ONLY what actually changes the response
  Including cookies/headers unnecessarily → cache fragmentation → low hit rate
```

### TTL Mechanics

Three TTL values in a Cache Policy:

```
MinTTL     = minimum cache time (CloudFront never caches less than this)
DefaultTTL = used when origin sends no Cache-Control header
MaxTTL     = maximum cache time (CloudFront never caches more than this)

How they interact with origin Cache-Control headers: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-cloudfront-behaviors-cache-policies/view)

Scenario 1: Origin sends Cache-Control: max-age=600
  MinTTL=0, DefaultTTL=86400, MaxTTL=31536000
  → Cached for 600s (origin wins, within min/max bounds)

Scenario 2: Origin sends Cache-Control: max-age=600, MinTTL=3600
  MinTTL=3600, DefaultTTL=86400, MaxTTL=31536000
  → Cached for 3600s (MinTTL overrides shorter origin TTL) [oneuptime](https://oneuptime.com/blog/post/2026-02-12-cloudfront-behaviors-cache-policies/view)

Scenario 3: Origin sends no Cache-Control header
  MinTTL=0, DefaultTTL=86400, MaxTTL=31536000
  → Cached for 86400s (DefaultTTL kicks in) [angelo.mandato](https://angelo.mandato.com/2026/02/20/simplest-explanation-of-the-6-cloudfront-caching-expiration-time-to-live-ttl-scenarios-with-7-useful-tips/)

Scenario 4: Origin sends Cache-Control: no-cache
  MinTTL=0: CloudFront respects no-cache → validates with origin each time
  MinTTL>0: CloudFront IGNORES no-cache — still caches for MinTTL [docs.aws.amazon](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html)
```

### AWS Managed Cache Policies

| Policy | MinTTL | DefaultTTL | MaxTTL | Use Case |
|--------|--------|-----------|--------|---------|
| `CachingOptimized` | 1s | 86400s (1d) | 31536000s (1yr) | S3 static assets |
| `CachingDisabled` | 0 | 0 | 0 | Dynamic APIs — never cache |
| `CachingOptimizedForUncompressedObjects` | 1s | 86400s | 31536000s | Objects that can't be compressed |
| `Elemental-MediaPackage` | 0 | 0 | 31536000s | HLS streaming |

---

## 7. Cache Invalidation ⭐

Invalidation forces CloudFront to expire cached objects before their TTL:

```
Invalidate specific file:
  /images/logo.png

Invalidate path pattern (wildcard):
  /images/*       ← all files under /images/
  /*              ← entire cache (expensive — avoid if possible)

CLI:
  aws cloudfront create-invalidation \
    --distribution-id EDFDVBD6EXAMPLE \
    --paths "/images/*" "/css/main.css"

Pricing:
  First 1,000 invalidation paths/month: FREE
  After that: $0.005 per path

Best practice — avoid invalidation:
  Version your asset URLs instead:
  /css/main.v1.css → /css/main.v2.css (deploy → new URL → cache miss forced)
  → No invalidation cost, old version still cached for users who have it
  → New version immediately served to new visitors
```

---

## 8. Signed URLs vs Signed Cookies ⭐

Both restrict access to **private CloudFront content** using cryptographic signatures.

### Signed URL

```
Grants access to a single specific object with a time-limited URL:

https://d1234abcdef.cloudfront.net/premium/video.mp4
  ?Policy=base64encodedpolicy
  &Signature=base64signature
  &Key-Pair-Id=K2JCJMDQS1EIOO

Signed URL with SHA-256 (new — more secure): [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/04/amazon-cloudfront-sha-256-signed-urls/)
  &Hash-Algorithm=SHA256  ← add this parameter for SHA-256 signing

Use when:
  Sharing a single file with a user (invoice PDF, video, download)
  User receives URL directly (app generates it server-side)
  RTMP streaming of a specific file

Limitation:
  Each file needs its own signed URL
  URL changes per expiry → breaks browser cache [stackoverflow](https://stackoverflow.com/questions/51522135/cloudfront-signed-urls-break-client-caching)
```

### Signed Cookie

```
Grants access to multiple objects using three cookies:
  CloudFront-Policy    = base64-encoded access policy
  CloudFront-Signature = cryptographic signature
  CloudFront-Key-Pair-Id = key pair identifier [oneuptime](https://oneuptime.com/blog/post/2026-02-12-cloudfront-signed-urls-and-cookies/view)

Use when:
  User has subscription access to premium section (/premium/*)
  Don't want to change existing URLs
  Multiple files under same path pattern need protection
  Browser navigates naturally between protected pages

Workflow:
  1. User logs in → backend verifies subscription
  2. Backend sets 3 CloudFront cookies in response
  3. Browser sends cookies with every /premium/* request
  4. CloudFront validates cookies → serves content
  5. Cookies expire → access revoked automatically
```

### Signed URL vs Signed Cookie

| | Signed URL | Signed Cookie |
|--|-----------|--------------|
| Scope | Single file | Multiple files (path pattern) |
| URL changes? | Yes (per signature) | No (URL stays clean) |
| Use case | One-time download, share link | Subscription content, protected section |
| Browser cache | ❌ Breaks caching (URL changes) | ✅ Works with caching |
| Implementation | Add query params to URL | Set 3 cookies at login |

### Canned vs Custom Policy

| Policy Type | Supports IP restriction | Supports date range (not-before) |
|------------|------------------------|----------------------------------|
| **Canned** | ❌ No | ❌ No (expiry only) |
| **Custom** | ✅ Yes | ✅ Yes |

---

## 9. Origin Access Control (OAC) vs Legacy OAI

| | OAC (Recommended) | OAI (Legacy) |
|--|------------------|-------------|
| Signing | SigV4 (strong) | Custom |
| SSE-KMS S3 support | ✅ Yes | ❌ No |
| S3 in all regions | ✅ Yes | ❌ Some regions |
| New features | ✅ Gets updates | ❌ No new features |

> Always use **OAC** for new CloudFront + S3 setups. OAI is no longer
> recommended by AWS and will eventually be deprecated.

---

## 10. HTTPS and TLS

```
CloudFront provides HTTPS automatically:
  Default domain:   https://d1234abcdef.cloudfront.net  ← free TLS
  Custom domain:    https://cdn.ibtisam-iq.com
    → Request free ACM certificate in us-east-1 (required for CloudFront)
    → Attach certificate to distribution

Viewer Protocol Policy (per behavior):
  HTTP and HTTPS allowed    → both work
  Redirect HTTP to HTTPS    → HTTP redirected to HTTPS (301)
  HTTPS only                → HTTP requests rejected (403)

Origin Protocol Policy:
  HTTP only      → CloudFront → origin over HTTP
  HTTPS only     → CloudFront → origin over HTTPS (end-to-end encryption)
  Match viewer   → CloudFront uses same protocol as viewer used

End-to-end HTTPS:
  User → HTTPS → CloudFront → HTTPS → Origin ALB → HTTPS → App
  Each hop encrypted independently
```

---

## 11. Price Classes ⭐

Control cost by limiting which edge locations serve your distribution:

| Price Class | Regions Included | Cost |
|------------|-----------------|------|
| **Price Class All** | All edge locations worldwide | Highest |
| **Price Class 200** | Most regions (excludes most expensive) | Medium |
| **Price Class 100** | North America + Europe only | Lowest |

```
Practical choice:
  Global app (users everywhere):  Price Class All
  EU/US focused:                  Price Class 100 (cheapest)
  Global but cost-sensitive:      Price Class 200

Note: Users outside included regions still get served — but from the
nearest included edge location (further away → higher latency)
```

---

## 12. Geo Restriction

```
Allowlist: only permit listed countries (block everyone else)
  "Allowed countries": PK, US, GB, DE, FR

Blocklist: block specific countries (allow everyone else)
  "Blocked countries": KP, IR, SY

Blocked user → CloudFront returns 403 (or custom error page)

Limitation:
  Country determined by IP geolocation → VPN users bypass this
  For more precise control → use WAF GeoMatch + Bot Control
  (WAF on CloudFront provides richer geo + VPN/Tor detection) [cloudchipr](https://cloudchipr.com/blog/aws-waf)
```

---

## 13. Custom Error Pages

```
When origin returns error → serve friendly custom page from CloudFront:

Error code: 404 → Custom page: /errors/404.html (cached for 300s)
Error code: 500 → Custom page: /errors/500.html (cached for 10s)
Error code: 503 → Custom page: /errors/maintenance.html

Benefits:
  Branded error pages (not raw AWS error)
  Cache error responses → reduce origin load during outage
  Serve maintenance page from edge even if origin is fully down
```

---

## 14. Origin Shield ⭐

An optional **additional caching layer** between edge locations and origin:

```
Without Origin Shield:
  Edge Mumbai   → cache miss → fetches from origin
  Edge Singapore → cache miss → fetches from origin (duplicate request)
  Edge Tokyo     → cache miss → fetches from origin (duplicate request)
  → Origin receives 3 requests for same object

With Origin Shield (us-east-1):
  Edge Mumbai    → cache miss → Origin Shield → cache hit → returns
  Edge Singapore → cache miss → Origin Shield → cache hit → returns
  Edge Tokyo     → cache miss → Origin Shield → cache miss → fetches origin once
  → Origin receives 1 request ← dramatically reduces origin load

Best for:
  High-traffic origins that are expensive to hit (API Gateway, ALB)
  Origins with high compute cost per request
  Reducing bandwidth from origin to edge
```

---

## 15. CloudFront Functions vs Lambda@Edge ⭐

Run code at CloudFront edge — covered in Lambda notes, summarized here:

| | CloudFront Functions | Lambda@Edge |
|--|---------------------|------------|
| Runtime | JS only | Node.js, Python |
| Max execution | < 1ms | 5s (viewer) / 30s (origin) |
| Max memory | 2 MB | 128MB–10GB |
| Network access | ❌ No | ✅ Yes |
| Scale | Millions req/s | Thousands req/s |
| Cost | ~1/6th of Lambda@Edge | Higher |
| Triggers | Viewer req/resp only | All 4 CloudFront events |
| Use case | URL rewrite, header manipulation, redirect, simple auth | Auth with DB lookup, A/B test, response generation |

```
Four trigger points:
  1. Viewer Request  → before CloudFront cache check
                       (runs on every request — expensive if complex)
  2. Origin Request  → cache miss, before going to origin
                       (runs only on cache misses — cheaper)
  3. Origin Response → after origin responds, before caching
  4. Viewer Response → after cache, before sending to user

CloudFront Functions: only 1 and 4
Lambda@Edge: all four
```

---

## 16. Real-World Architectures ⭐

### Static Website (S3 + CloudFront)

```
User → CloudFront (edge) → S3 (private, OAC)
  + ACM certificate → HTTPS on custom domain
  + WAF → SQL injection / bot protection
  + Route 53 Alias → cdn.ibtisam-iq.com

Benefits: global low latency, $0 origin cost (S3 cheap), HTTPS free
```

### Full-Stack App (SPA + API)

```
cdn.ibtisam-iq.com /* (Default behavior) → S3 (React SPA)
cdn.ibtisam-iq.com /api/* (Behavior)     → ALB → EC2/ECS
cdn.ibtisam-iq.com /images/* (Behavior)  → S3 (media bucket, cache 1yr)

Single domain for entire app — no CORS issues
Frontend cached at edge, API forwarded to origin
```

### Video Streaming (Private Content)

```
User authenticates → backend issues Signed Cookie → User browses /videos/*
CloudFront validates cookie on each request → serves from S3 via OAC
  + Origin Shield → reduces S3 origin load
  + Price Class All → global low latency for video
```

---

## 17. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| CloudFront is only for static content | CloudFront proxies **dynamic content** too — with dynamic acceleration over AWS backbone |
| OAI still recommended | OAI is **legacy** — always use **OAC** for new setups |
| ACM certificate can be in any region for CloudFront | ACM certificate for CloudFront **must be in us-east-1** — regardless of distribution's origin region |
| Cache invalidation is free | First 1,000 paths/month free; then **$0.005/path** — version URLs instead |
| MinTTL=0 means CloudFront respects no-cache from origin | If **MinTTL > 0**, CloudFront ignores Cache-Control: no-cache |
| Signed URL and Signed Cookie use same key as IAM | CloudFront uses its own **CloudFront key pairs** — not IAM access keys |
| CloudFront can directly serve from private S3 without configuration | Requires **OAC** and S3 bucket policy allowing CloudFront service principal |
| Price Class 100 only serves North American users | Price Class 100 serves users worldwide — but from **North America/Europe edges only** (more latency elsewhere) |
| One distribution = one origin | One distribution supports **multiple origins** with behaviors routing different paths |
| SHA-1 is the only option for signed URLs | SHA-256 now supported with `Hash-Algorithm=SHA256` parameter (April 2026) |

---

## 18. Interview Questions Checklist

- [ ] What is a CDN? How does CloudFront reduce latency?
- [ ] What is the difference between edge locations and regional edge caches?
- [ ] What is OAC? Why must you use it over OAI for S3 origins?
- [ ] What is an Origin Group? How does it enable failover?
- [ ] What are cache behaviors? How are they matched? (path pattern, first-match-wins)
- [ ] Three TTL values — what happens when origin sends no Cache-Control?
- [ ] What does MinTTL > 0 do when origin sends Cache-Control: no-cache?
- [ ] Signed URL vs Signed Cookie — when to use which?
- [ ] Canned policy vs Custom policy for signed URLs
- [ ] What are the four CloudFront trigger points? Which functions work at each?
- [ ] CloudFront Functions vs Lambda@Edge — key differences
- [ ] What is Origin Shield? When should you use it?
- [ ] Three price classes and what they include
- [ ] Where must ACM certificates be created for CloudFront?
- [ ] How do you prevent users from bypassing CloudFront to hit ALB directly?
- [ ] Cache invalidation cost? Better alternative?
- [ ] What does OAC do differently than OAI for SSE-KMS S3?
- [ ] How do you serve a custom 404 page from CloudFront?
