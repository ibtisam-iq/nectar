# AWS WAF (Web Application Firewall)

## 1. What is AWS WAF?

AWS WAF is a **Layer 7 (application layer) firewall** that inspects HTTP/HTTPS
requests and allows, blocks, or counts them based on rules you define.
It protects web applications from common exploits, bots, and malicious traffic
before requests reach your application servers.

```
Without WAF:
  Attacker sends SQL injection → hits your application → database compromised

With WAF:
  Attacker sends SQL injection → WAF inspects HTTP body → matches rule → BLOCK ❌
  Legitimate user → WAF inspects → no match → ALLOW ✅ → reaches application
```

### What WAF Operates At

| Layer | Protocol | What WAF Inspects |
|-------|----------|------------------|
| Layer 3/4 | TCP/IP | ❌ Not WAF's job (that's Network ACL / Security Groups) |
| **Layer 7** | **HTTP/HTTPS** | ✅ URL, headers, body, query strings, cookies, IP |

---

## 2. Where WAF Integrates (Protected Resources)

WAF is attached to a **protected resource** — traffic to that resource is
inspected by WAF rules before being forwarded:

| Resource | WAF Scope | Use Case |
|---------|----------|---------|
| **CloudFront** | Global (all edge locations) | Protect CDN, inspect at edge |
| **Application Load Balancer (ALB)** | Regional | Protect web apps behind ALB |
| **API Gateway (REST + HTTP)** | Regional | Protect APIs |
| **AppSync** | Regional | Protect GraphQL APIs |
| **Cognito User Pool** | Regional | Protect auth endpoints |
| **App Runner** | Regional | Protect containerized apps |
| **Verified Access** | Regional | Zero trust application access |

```
Architecture options:
  Option A: WAF on CloudFront (global)
    User → CloudFront (WAF here) → ALB → Application
    ✅ Inspects at edge (closest to attacker) — cheapest, fastest blocking

  Option B: WAF on ALB (regional)
    User → ALB (WAF here) → Application
    ✅ Inspects regional traffic
    ❌ Bypassed if attacker hits ALB directly (skip CloudFront)

  Option C: WAF on both CloudFront AND ALB
    Most secure — blocks at edge + backstop if ALB is reached directly [reddit](https://www.reddit.com/r/aws/comments/1kc0fnb/rate_limit_rules_in_waf_with_cloudfront/)
```

---

## 3. Core Components ⭐

### Web ACL (Access Control List)

The **top-level container** — you create one Web ACL and attach it to a resource.
A Web ACL contains ordered rules and rule groups.

```
Web ACL properties:
  Scope: CLOUDFRONT (global) or REGIONAL (ALB, API GW, etc.)
  Default action: ALLOW or BLOCK (what happens if no rule matches)
  Rules: ordered list of rules and rule groups (priority 0–99,999,999)
  Capacity: max 1,500 WCUs (Web ACL Capacity Units)
```

> **Scope matters:** A Web ACL created for CloudFront (global) cannot be attached
> to an ALB (regional) and vice versa. You create separate Web ACLs per scope.

### Rule

A single inspection unit — evaluates a condition and takes an action:

```
Rule:
  Name:      BlockSQLInjection
  Priority:  10              ← lower number = evaluated first
  Statement: SQL injection match on request body
  Action:    Block

Rule:
  Name:      AllowOfficeIP
  Priority:  5               ← evaluated before BlockSQLInjection (lower priority number)
  Statement: IP set match (203.0.113.0/24)
  Action:    Allow
```

### Rule Group

A **reusable collection of rules** — packaged together with a fixed capacity cost.
Three types of rule groups exist (covered in Section 5).

### WCU (Web ACL Capacity Unit)

```
Every rule consumes WCUs based on complexity:
  Simple IP match:          1 WCU
  Regex pattern match:      25 WCUs per pattern (max 10 patterns = 250 WCUs)
  SQL injection detection:  20 WCUs
  Bot Control (common):     25 WCUs
  Bot Control (targeted):   50 WCUs

Web ACL limit: 1,500 WCUs total
(Can request increase, costs extra per 500 additional WCUs)
```

---

## 4. Rule Actions

| Action | Effect | Continues Evaluation? |
|--------|--------|----------------------|
| **Allow** | Forward request to protected resource | No — done |
| **Block** | Return HTTP 403 (or custom response) | No — done |
| **Count** | Count the request, add labels, continue | **Yes** — evaluation continues |
| **CAPTCHA** | Return CAPTCHA challenge to client | No (until solved) |
| **Challenge** | Return silent browser challenge (JS) | No (until solved) |

```
Count action use case:
  New rule you're testing → set to Count first
  Monitor in CloudWatch: how many requests would have been blocked?
  If no false positives → switch to Block

CAPTCHA vs Challenge:
  Challenge: silent, JavaScript-based browser verification (invisible to user)
  CAPTCHA:   visible image puzzle the user must solve
  Use Challenge first → if bots pass it → escalate to CAPTCHA
```

---

## 5. Rule Types ⭐

### Type 1: AWS Managed Rules

Pre-built rule groups maintained by the AWS Threat Intelligence team.
Updated automatically when new threats emerge — zero maintenance from you.

| Managed Rule Group | Protects Against |
|-------------------|-----------------|
| `AWSManagedRulesCommonRuleSet` | OWASP Top 10 (XSS, SQLi, path traversal, etc.) |
| `AWSManagedRulesAdminProtectionRuleSet` | Admin page access (`/admin`, `/wp-admin`) |
| `AWSManagedRulesKnownBadInputsRuleSet` | Exploits (Log4JRCE, Spring4Shell, etc.) |
| `AWSManagedRulesSQLiRuleSet` | SQL injection attacks |
| `AWSManagedRulesLinuxRuleSet` | Linux-specific exploits |
| `AWSManagedRulesWindowsRuleSet` | Windows-specific exploits |
| `AWSManagedRulesWordPressRuleSet` | WordPress vulnerabilities |
| `AWSManagedRulesAmazonIpReputationList` | Known malicious IPs (AWS threat intel) |
| `AWSManagedRulesAnonymousIpList` | Tor exits, VPN, proxies, hosting providers |
| `AWSManagedRulesBotControlRuleSet` | Bots (see Section 6) |
| `AWSManagedRulesFraudControlAccountTakeoverPrevention` | Credential stuffing |

```
Add managed rule group to Web ACL:
  → select rule group → set priority → choose override actions if needed
  → AWS maintains all rules inside — you do not write individual rules

Override action (per rule inside the group):
  Use group defaults  → respect all built-in Allow/Block/Count actions
  Count all          → override all actions to Count (safe testing mode)
  Override specific  → override individual rules from Block → Count or vice versa
```

### Type 2: Customer Managed Rules (Your Own)

Rules you write yourself for your specific application logic:

```
Statement types you can use:

IP Set Match:
  Block specific IP ranges
  "Statement": { "IPSetReferenceStatement": { "ARN": "arn:aws:wafv2:...:ipset/block-list" } }

Geo Match:
  Block all traffic from specific countries
  "Statement": { "GeoMatchStatement": { "CountryCodes": ["RU", "CN", "KP"] } }

String Match:
  Block requests containing specific string in URI, header, body, query string
  "Statement": {
    "ByteMatchStatement": {
      "SearchString": "../../../etc/passwd",
      "FieldToMatch": { "UriPath": {} },
      "TextTransformations": [{ "Priority": 0, "Type": "URL_DECODE" }],
      "PositionalConstraint": "CONTAINS"
    }
  }

Regex Match:
  Block URIs matching regex pattern
  FieldToMatch: URI, headers, body, query string, cookies, HTTP method

Rate-Based Rule:
  Block IPs exceeding N requests per 5 minutes (see Section 7)

SQL Injection Match:
  Built-in SQLi detection on specific field

XSS Match:
  Built-in cross-site scripting detection on specific field

Logical Rules (AND / OR / NOT):
  Combine multiple statements:
  "AND": [geo match CN, rate > 1000] → Block
  "NOT": [IP in allowlist] AND [SQLi match] → Block
```

### Type 3: Marketplace Managed Rules

Third-party security vendors (Imperva, F5, Fortinet, TrendMicro) sell
rule groups in AWS Marketplace. Subscribed via marketplace, then added
to your Web ACL like AWS managed rules.

---

## 6. Bot Control ⭐

AWS WAF Bot Control is a managed rule group specifically for bot traffic:

### Two Protection Levels

**Common (Basic Bot Detection)**

```
WCU cost: 25 WCUs
Detects: well-known bots by signature (user agent, IP, behavior patterns)
  → Googlebot, Bingbot (verified → Allow)
  → Scrapers, crawlers (unverified → Block)
Pricing: additional fee per million requests inspected
```

**Targeted (Advanced Bot Detection + ML)**

```
WCU cost: 50 WCUs
Adds: machine learning analysis of traffic patterns
      browser fingerprinting (detects automated browsers)
      coordinated activity detection (distributed bot farms)
Rules with TGT_ prefix = targeted rules
Rules with TGT_ML_ prefix = ML-powered rules (take up to 24h to baseline) [docs.aws.amazon](https://docs.aws.amazon.com/waf/latest/developerguide/waf-bot-control-rg-using.html)
Pricing: higher additional fee per million requests
```

### What Bot Control Labels

```
WAF adds labels to requests for custom rule chaining:
  awswaf:managed:aws:bot-control:bot:category:ai
  awswaf:managed:aws:bot-control:bot:verified
  awswaf:managed:aws:bot-control:signal:automated_browser
  awswaf:managed:aws:bot-control:signal:known_bot_data_center
  awswaf:managed:aws:bot-control:signal:non_browser_user_agent

Use labels in downstream rules:
  "If label = signal:automated_browser → CAPTCHA"
  "If label = bot:verified → Allow (Googlebot)"
  "If label = signal:known_bot_data_center → Block"
```

### Bot Categories WAF Detects

- Search engine crawlers (Googlebot, Bingbot) → verified → Allow by default
- Monitoring tools (Pingdom, UptimeRobot)
- SEO crawlers and scrapers
- AI training crawlers (`CategoryAI` — blocks AI data scrapers)
- Automated browsers (Puppeteer, Selenium, Playwright)
- Credential stuffing bots
- DDoS bots and scanners

---

## 7. Rate-Based Rules ⭐

Rate limiting blocks clients that exceed a request threshold within a 5-minute window:

```
Rate-based rule:
  Threshold: 1,000 requests
  Window: 5 minutes (fixed — cannot change)
  Aggregate key: IP address (default)
  Action: Block (or Count, CAPTCHA, Challenge)

Behavior:
  AWS WAF counts requests per IP in rolling 5-minute window
  When IP exceeds 1,000 in any 5-minute window → Action triggered
  Block lifted when rate drops below threshold
 [docs.aws.amazon](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based-request-limiting.html)
```

### Aggregate Keys (What to Rate-Limit By)

| Key | Use Case |
|-----|---------|
| **IP address** (default) | Block single IPs hammering your API |
| **Forwarded IP** | When using CloudFront/proxy — rate-limit real client IP from X-Forwarded-For header |
| **HTTP header value** | Rate-limit by API key, session token, User-Agent |
| **Query string component** | Rate-limit by specific query parameter |
| **HTTP method** | Rate-limit POST separately from GET |
| **Custom key combination** | Combine IP + header + URI path |

```
Scope-down statement (optional): [docs.aws.amazon](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html)
  Only count/rate-limit requests that match a condition
  Example: rate-limit only POST /login (not all endpoints)
  "ScopeDownStatement": {
    "ByteMatchStatement": {
      "SearchString": "/login",
      "FieldToMatch": { "UriPath": {} },
      "PositionalConstraint": "EXACTLY"
    }
  }
  → Only login attempts counted toward rate limit
  → Other endpoints unaffected
```

---

## 8. IP Sets and Geo Matching

### IP Sets

```
Reusable list of IP addresses/CIDR ranges
Create once → reference in multiple rules

IP set types:
  Allowlist: known safe IPs (office, partners) → Always Allow
  Blocklist: known bad IPs, threat intel feeds → Always Block

Create:
  aws wafv2 create-ip-set \
    --scope REGIONAL \
    --name office-allowlist \
    --ip-address-version IPV4 \
    --addresses "203.0.113.0/24" "198.51.100.5/32"

Update without rule change:
  Add/remove IPs from IP set → rule automatically uses updated list
```

### Geo Matching

```
Block or allow based on country of origin (determined by IP geolocation):

Use cases:
  GDPR: force EU users to EU endpoint only
  Compliance: block service in specific jurisdictions
  Cost reduction: block known bot-heavy regions

"Statement": {
  "GeoMatchStatement": {
    "CountryCodes": ["RU", "CN", "KP", "IR"]
  }
}

Limitation: VPN/Tor users bypass geo match (their exit IP = different country)
  → Combine with AWSManagedRulesAnonymousIpList to also block Tor/VPN
```

---

## 9. Labels and Rule Chaining

Labels enable **multi-stage inspection** — rules can add labels that later rules match:

```
Stage 1: Bot Control rule group runs
  → Labels request: "awswaf:managed:aws:bot-control:signal:automated_browser"

Stage 2: Your custom rule checks for that label
  If: label matches "automated_browser"
  Then: CAPTCHA

Stage 3: If CAPTCHA is solved → allow through
  If CAPTCHA failed → Block

This allows: coarse detection → fine-grained custom response
```

---

## 10. Logging and Monitoring ⭐

### WAF Logging

```
Enable logging → WAF sends full request logs to:
  Amazon S3                    → long-term storage, Athena queries
  CloudWatch Logs              → real-time monitoring, alarms
  Amazon Kinesis Data Firehose → streaming to S3/Splunk/Datadog

Log contents:
  Timestamp, action (ALLOW/BLOCK/COUNT), rule that matched,
  Client IP, URI, headers (configurable), country, HTTP method,
  Labels applied, terminating rule

Log filtering:
  Log only BLOCK actions (reduces cost)
  Log only specific rule matches
  Redact sensitive headers before logging
```

### CloudWatch Metrics (per rule)

```
AllowedRequests   → count of allowed requests
BlockedRequests   → count of blocked requests per rule
CountedRequests   → count of counted (passthrough) requests
CaptchaRequests   → count of CAPTCHA challenges
PassedRequests    → requests that passed CAPTCHA

Create alarms:
  BlockedRequests > 1000 in 5 min → SNS → PagerDuty
  (sudden spike in blocks = attack in progress)
```

### WAF Sampled Requests

```
WAF stores samples of last 3 hours of requests (max 100 per rule):
  Console: WAF → Web ACL → Sampled requests tab
  Shows: actual request that matched (headers, URI, body snippet)
  Use: debug why a rule is blocking legitimate traffic
```

---

## 11. AWS WAF vs AWS Shield ⭐

These are complementary, not competing:

| | AWS WAF | AWS Shield Standard | AWS Shield Advanced |
|--|---------|--------------------|--------------------|
| What it stops | Layer 7 exploits, bots, custom threats | Layer 3/4 volumetric DDoS | L3/4 + L7 DDoS with response team |
| How it works | Inspect HTTP content, apply rules | Absorb large SYN floods, UDP floods | WAF + 24/7 DDoS response team (DRT) |
| Cost | Pay per Web ACL + rules + requests | **Free** (all AWS customers) | $3,000/month + data transfer out fee |
| Rules | Your rules + managed rules | Automatic, no configuration | Automatic + DRT tuning |
| Layer | 7 | 3/4 | 3/4/7 |

```
Combined architecture for full protection:
  CloudFront (with WAF + Shield Advanced)
    → WAF handles: SQLi, XSS, bots, rate limiting, geo blocking
    → Shield handles: volumetric DDoS (millions of pps UDP/TCP floods)
    → Together: comprehensive application protection
```

---

## 12. WAF Pricing

```
Regional Web ACL:    $5.00/month per Web ACL
CloudFront Web ACL:  $5.00/month per Web ACL
Per rule:            $1.00/month per rule
Per rule group:      $1.00/month per rule group
Requests:            $0.60 per 1 million requests (first 10M)
                     $0.40 per 1 million requests (after 10M)

Managed rule groups (AWS Managed):
  Basic groups (CommonRuleSet, SQLi, etc.): included
  Bot Control Common:  additional charge per million requests
  Bot Control Targeted: higher per-million charge

Rule groups from marketplace: vendor-specific pricing
```

---

## 13. WAF Deployment Best Practices

```
1. Start all new rules in COUNT mode → monitor for 1-2 weeks → switch to BLOCK
   (Prevents blocking legitimate traffic due to false positives)

2. Layer defense:
   Priority 1: IP allowlist (trusted IPs — highest priority, always allow)
   Priority 2: IP blocklist (known bad IPs — block immediately)
   Priority 3: AWS managed rules (OWASP, SQLi, etc.)
   Priority 4: Rate-based rules (DDoS/brute force)
   Priority 5: Custom application rules
   Default:    ALLOW (or BLOCK for strict mode)

3. Use scope-down statements on Bot Control and advanced rules:
   → Only apply expensive rules to sensitive endpoints (/login, /checkout)
   → Reduces WCU consumption and request inspection costs [aws.github](https://aws.github.io/aws-security-services-best-practices/guides/waf/configuring-waf-rules/docs/)

4. Attach WAF to CloudFront (not just ALB):
   → Blocks at edge before traffic reaches your region
   → Reduces origin load from attack traffic [reddit](https://www.reddit.com/r/aws/comments/1kc0fnb/rate_limit_rules_in_waf_with_cloudfront/)

5. Enable WAF logging to S3 + set up CloudWatch alarm on BlockedRequests spike
   → Operational visibility + incident response

6. Regularly review sampled requests for false positives
   → Tune rules before attacks happen, not during
```

---

## 14. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| WAF protects against DDoS volumetric attacks | WAF handles Layer 7 only — use **Shield** for volumetric DDoS |
| WAF on ALB protects from all internet traffic | Attackers can bypass ALB-WAF by hitting ALB directly — **attach WAF to CloudFront too** |
| Regional Web ACL works with CloudFront | CloudFront requires **CLOUDFRONT scope** Web ACL (created in us-east-1) |
| New rules should immediately be set to Block | Start in **Count mode** — monitor for false positives before blocking |
| Rate-limit window is configurable | Rate-based rule window is always **5 minutes** (fixed) |
| Shield Advanced includes WAF | Shield Advanced **does not include WAF** — they are separate services (but work together) |
| Bot Control detects all bots | Bot Control Targeted + ML takes **up to 24h** to establish baselines |
| One Web ACL works for CloudFront and ALB | Separate Web ACLs needed — scope is set at creation and cannot be changed |
| Managed rules are free | Basic managed rules are included; **Bot Control and Fraud Control have per-request charges** |
| WAF inspects encrypted HTTPS content | WAF sits **after TLS termination** at the load balancer/CloudFront — it sees decrypted HTTP |

---

## 15. Interview Questions Checklist

- [ ] What layer does WAF operate at? What does it inspect?
- [ ] List all resources WAF can be attached to
- [ ] What is a Web ACL? What is WCU?
- [ ] Five rule actions — what does Count do that others don't?
- [ ] When would you use CAPTCHA vs Challenge action?
- [ ] Three types of rule groups — what's the difference?
- [ ] Name five AWS managed rule groups and what they protect against
- [ ] How does Bot Control Common differ from Bot Control Targeted?
- [ ] What are WAF labels? How are they used for rule chaining?
- [ ] Rate-based rule — window duration, aggregate key options
- [ ] What is a scope-down statement? Why use it on Bot Control?
- [ ] WAF vs Shield — which stops what at which layer?
- [ ] Why attach WAF to CloudFront instead of (or in addition to) ALB?
- [ ] Why start new rules in Count mode?
- [ ] How do you debug a WAF rule blocking legitimate traffic? (Sampled Requests)
- [ ] WAF pricing model — what are the four charges?
- [ ] Geo match limitation — how do you handle VPN/Tor bypass?
