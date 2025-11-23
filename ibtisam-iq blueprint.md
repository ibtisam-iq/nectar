

# 1. MAIN GOAL

Build a **personal engineering ecosystem**, not a basic portfolio.

Objectives:

1. Strong personal brand
2. Proof of real engineering depth
3. Scalable structure for future growth
4. Separation of “learning”, “proof”, and “services”

---

# 2. DOMAINS STRUCTURE

You own:

* `ibtisam-iq.com` → MAIN PORTFOLIO SITE
* `ibtisamx.com` → BUSINESS / SERVICES SITE

Subdomains:

```
docs.ibtisam-iq.com        → Documentation site
projects.ibtisam-iq.com    → Projects hub
(certificates later if needed)
(learning handled via Resources, not subdomain)
```

---

# 3. FINAL TOP NAVIGATION BAR

Your main website (`ibtisam-iq.com`) will always have:

```
Home
Docs
Portfolio
Resources
Services
Contact
Download CV
```

No extra clutter.

---

# 4. PAGE/BUTTON ROLE MAPPING

### ✅ Home

Purpose:

* Your journey
* Your background
* Your mindset
* Your transition story (non-tech → DevOps)

Content:

* Story-driven
* Clean
* No technical overload

---

### ✅ Docs

Route:

```
docs.ibtisam-iq.com
```

Connected Repo:

```
docs-site (public repo)
```

Purpose:

* Teach the world
* Your unique explanations
* Refined knowledge (not raw Nectar)

Nectar feeds this, but is not shown here.

---

### ✅ Portfolio

Contains sections (internal or separate routes):

```
projects.ibtisam-iq.com   → Projects Hub Site (not GitHub)
certificates page         → Your earned certificates
skill set page            → Proof of learning
achievements page         → Awards / medals
```

Also includes:

* Button linking Nectar repo as **Practical Proof**

---

### ✅ Resources  (replaces "Learning")

This is where your **knowledge-sharing repos live**.

Contains:

```
Certification Prep    → certificates-prep repo
Roadmaps              → roadmaps repo
Guides (future)
```

This is not “portfolio”.
This is **value for community**.

---

### ✅ Services

Route:

```
Redirect to ibtisamx.com
```

This is future:

* Consulting
* Cloud services
* Security services

No services form on portfolio.

---

### ✅ Contact

Simple.

Buttons only:

```
LinkedIn
Email
Calendar Booking (cal.com)
```

No WhatsApp.
No random social clutter.

---

### ✅ Download CV

A button visible on:

* Top right of navbar
  OR
* Hero section

Downloads your **one-page PDF resume**.

---

# 5. GITHUB REPOSITORIES ROLE

You have 5 repositories:

### 1. Nectar Repo

Purpose:

* Raw learning system
* Internal notes
* Proof of consistency

Where it appears:

```
Portfolio → Skill Set → Practical Proof (link only)
```

---

### 2. Docs Repo

Name:

```
docs-site
```

Feeds:

```
docs.ibtisam-iq.com
```

Contains:

* Refined, clean content

---

### 3. SilverOps Repo

Purpose:

* Internal project index
* Acts as backend logic for your thinking

Not visible publicly.

Feeds:

```
projects-site (actual website repo)
```

---

### 4. Certificates / Prep Repo

Purpose:

* Real-world exam prep system
* Deep troubleshooting notes

Belongs under:

```
Resources → Certification Prep
```

---

### 5. Roadmaps Repo

Purpose:

* Transition frameworks
* Learning paths

Belongs under:

```
Resources → Roadmaps
```

---

# 6. PROJECTS SYSTEM DESIGN

You do NOT expose GitHub directly.

Proper flow:

```
projects.ibtisam-iq.com  (real website)
     ↓
Project cards
     ↓
Click → GitHub repo link
```

---

# 7. WEBSITE BUILD PHASES

### Phase 1 (Now)

Simple stack:

```
HTML
CSS
Basic JavaScript
```

Features:

* Static pages
* Manual project listing
* Clean UI

---

### Phase 2 (Later)

```
React / Next.js
JSON based project lists
Filters by tech
Search bar
```

---

### Phase 3 (Future Product-Level)

```
Backend
Database
Search engine
User accounts
Public hub functionality
```

---

# 8. STRUCTURE SUMMARY (FULL PICTURE)

```
ibtisam-iq.com
 ├─ Home
 ├─ Docs  → docs.ibtisam-iq.com
 ├─ Portfolio
 │    ├─ Projects → projects.ibtisam-iq.com
 │    ├─ Certificates
 │    ├─ Skill Set → link to Nectar
 │    └─ Achievements
 ├─ Resources
 │    ├─ Certification Prep → GitHub repo
 │    └─ Roadmaps → GitHub repo
 ├─ Services → redirect to ibtisamx.com
 ├─ Contact
 │    ├─ LinkedIn
 │    ├─ Email
 │    └─ Calendar
 └─ Download CV
```

---


# FOOTER DESIGN (Bottom of Website)

Purpose of footer:

* Present your digital presence
* Group links cleanly
* Avoid clutter
* Look professional

Footer will be **section-based**, not a mess of random icons.

---

## FOOTER STRUCTURE

Your footer will be divided into **4 clean blocks:**

```
About
Social
Developer
Productivity
(Services-related links later)
```

---

## 1. ABOUT SECTION

This is minimal.

Contains:

* Your name
* Your role
* One-line mission

Example structure:

```
About
– Muhammad Ibtisam Iqbal
– DevOps / Cloud / Infrastructure Engineer
– Building systems, not just tools
```

---

## 2. SOCIAL SECTION

All your **general social presence** goes here:

```
Social
– LinkedIn
– Facebook (career-focused only)
– X / Twitter
```

No WhatsApp
No Instagram (you don’t use it)
No clutter

---

## 3. DEVELOPER SECTION

All technical profiles here:

```
Developer
– GitHub
– Medium
– Dev.to
– Credly
– ORCID (if active)
– Docker Hub profile
```

Purpose:
Show you're a serious builder, not just a content poster.

---

## 4. PRODUCTIVITY SECTION

All tools that represent your **system thinking**:

```
Productivity
– Raindrop.io
– Any future productivity tools
```

This proves you think in **systems**, not chaos.

---

## 5. SERVICES / FUTURE SECTION

This will stay minimal **for now**:

```
Services
– Upwork (when ready)
– ibtisamx.com (future services site)
```

You will NOT clutter this today.
We’ll unlock it when real services start.

---

## FOOTER CLUTTER RULES (IMPORTANT)

• No endless icons
• No random links
• Only structured groups
• Only tools that represent your thinking

---

## FINAL FOOTER STRUCTURE (READY TO COPY)

```
Footer Layout:

About
- Name
- Role
- Mission line

Social
- LinkedIn
- Facebook
- X (Twitter)

Developer
- GitHub
- Medium
- Dev.to
- Credly
- Docker Hub

Productivity
- Raindrop.io
- Other productivity tools

Services (future ready)
- Upwork
- ibtisamx.com
```

---

## Now your website blueprint is COMPLETE ✅

You now have:

✅ Top navigation system
✅ Subdomains plan
✅ Repo mapping
✅ Docs system
✅ Projects system
✅ Resources mapping
✅ Resume handling
✅ Footer architecture

---

