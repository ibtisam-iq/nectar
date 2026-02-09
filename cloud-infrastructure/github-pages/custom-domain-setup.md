# 📘 **How to Configure GitHub Pages with a Custom Domain (Using Cloudflare + GoDaddy)**

*A complete beginner-friendly, depth guide for DevOps engineers*

---

# 🧭 **1. Why We Are Doing This**

GitHub Pages allows you to host:

* Project documentation
* Static websites
* MkDocs / Docusaurus sites
* API docs
* Portfolio pages

By default, GitHub hosts your site at:

```
https://<username>.github.io/<repository>
```

But this URL:

* Looks unprofessional
* Is hard to remember
* Does not match your personal brand

So we configure a **custom domain**, such as:

```
https://debugbox.ibtisam-iq.com
```

This gives you:

* Full branding
* Professional OSS style
* SEO benefits
* A consistent identity across all tools

You can repeat this process for **ANY number of projects**.

---

# 🌍 **2. Understanding the Domain Roles (GoDaddy vs. Cloudflare)**

This is the MOST important concept.

### ✔ GoDaddy = Registrar

You ONLY bought the domain here.
It does **not** control DNS anymore.

### ✔ Cloudflare = DNS Manager

You moved your nameservers to Cloudflare.
This means **all DNS changes must happen in Cloudflare**.

### ❌ Do NOT edit DNS in GoDaddy now.

It will do nothing because GoDaddy DNS is bypassed.

This confusion is very common — but now you understand it perfectly.

---

# 🌐 **3. What We Want to Achieve**

Our goal:

### Create a custom domain for our GitHub Pages site:

```
debugbox.ibtisam-iq.com
```

Which points to:

```
ibtisam-iq.github.io
```

So when someone opens:

```
debugbox.ibtisam-iq.com
```

GitHub Pages serves your MkDocs site.

---

# 🧩 **4. Requirements Before Starting**

* You purchased a domain (`ibtisam-iq.com`)
* You changed nameservers to Cloudflare (already done)
* You enabled GitHub Pages in your repo
* You deployed a MkDocs or static site
* You enabled SSL (HTTPS)

You already completed everything — now we document it.

---

# 🧱 **5. Step-by-Step Setup**

## **Step 1 — Add a DNS Record in Cloudflare**

Go to:

**Cloudflare → DNS → Records → Add Record**

Add this EXACT entry:

```
Type:   CNAME
Name:   debugbox
Target: ibtisam-iq.github.io
TTL:    Auto
Proxy:  OFF  (must be DNS only)
```

### ❗ VERY IMPORTANT:

The orange cloud must be **disabled**.

Use **Gray Cloud → DNS Only**, because GitHub Pages cannot work behind Cloudflare proxy.

---

## **Step 2 — Tell GitHub Pages about Your Domain**

Go to:

**GitHub Repo → Settings → Pages**

Under **Custom Domain** enter:

```
debugbox.ibtisam-iq.com
```

GitHub will:

* Verify DNS
* Create a `CNAME` file during deployment
* Link your repo to the domain
* Enable HTTPS

If verification fails, wait 2–10 minutes.

---

## **Step 3 — Update Your GitHub Actions Deployment**

Inside:

```
.github/workflows/docs-build.yml
```

Add:

```yaml
cname: debugbox.ibtisam-iq.com
```

This ensures GitHub Pages always creates the correct `CNAME` file.

---

## **Step 4 — Set the Correct Site URL in mkdocs.yml**

Edit:

```
mkdocs.yml
```

Add:

```yaml
site_url: https://debugbox.ibtisam-iq.com
```

This helps with:

* Sitemap
* Canonical URLs
* SEO correctness

---

## **Step 5 — Cloudflare SSL Settings**

Go to:

**Cloudflare → SSL/TLS**

Set:

### ✔ SSL Mode: `Full`

Not Flexible.

Then enable:

* Always Use HTTPS → ON
* Automatic HTTPS Rewrites → ON
* Opportunistic Encryption → ON
* TLS 1.3 → ON

This ensures your site always loads securely.

---

# 🎯 **6. Confirming Everything Works**

Use the following commands:

### Check DNS propagation:

```bash
dig debugbox.ibtisam-iq.com
```

You must see:

```
debugbox.ibtisam-iq.com CNAME ibtisam-iq.github.io
```

### Test in browser:

Open:

```
https://debugbox.ibtisam-iq.com
```

You should see:

* GitHub Pages
* Or your MkDocs site
* With valid HTTPS

If you see a **404 GitHub Pages not found**, it means:

* DNS is correct
* HTTPS is correct
* GitHub Pages is configured
* Your repo has no `index.html` yet OR build hasn’t deployed yet

This is normal if CI hasn’t deployed docs yet.

---

# 🔥 **7. Can You Do This for Multiple Projects? YES**

You are **not limited** to one project.

You can host unlimited GitHub Pages websites with unlimited subdomains:

```
debugbox.ibtisam-iq.com
nectar.ibtisam-iq.com
silverkube.ibtisam-iq.com
engineering.ibtisam-iq.com
aiops.ibtisam-iq.com
```

Cloudflare DNS entries:

```
CNAME debugbox     ibtisam-iq.github.io
CNAME nectar       ibtisam-iq.github.io
CNAME silverkube   ibtisam-iq.github.io
CNAME aiops        ibtisam-iq.github.io
CNAME playbook     ibtisam-iq.github.io
```

Each project:

* Has its own repo
* Has its own GitHub Pages
* Has its own custom domain
* Has its own docs
* Has its own branding

This is how top OSS engineers build their ecosystem.

---

# 🧠 **8. Why This Works (Simple Explanation)**

GitHub Pages serves **project websites** based on the `CNAME` file inside each repo.

Example:

Repo A:

```
CNAME → debugbox.ibtisam-iq.com
```

Repo B:

```
CNAME → nectar.ibtisam-iq.com
```

Repo C:

```
CNAME → silverkube.ibtisam-iq.com
```

Cloudflare DNS decides:

```
debugbox → ibtisam-iq.github.io
nectar → ibtisam-iq.github.io
silverkube → ibtisam-iq.github.io
```

GitHub Pages decides:

```
Which repo? Check CNAME file.
```

Thus: **unlimited sites are possible.**

---

# 🛠️ **9. Common Troubleshooting**

### 1. Seeing 404 on custom domain?

GitHub Pages hasn't deployed your site yet.

### 2. SSL not working?

Cloudflare still issuing certificate → wait 2–15 minutes.

### 3. GitHub Pages says “Domain not verified”?

DNS record not propagated yet.

### 4. Site loads without CSS?

Cloudflare proxy accidentally ON → turn OFF (gray cloud).

---

# 🧩 **10. Summary**

You now understand:

✔ How GitHub Pages works

✔ Why Cloudflare controls DNS

✔ How custom domains work

✔ How SSL works

✔ How to integrate Cloudflare + GitHub

✔ How to deploy Docs Pages

✔ How to host unlimited project docs

✔ How to do a professional OSS setup

Your DebugBox docs site is now correctly hosted at:

### **[https://debugbox.ibtisam-iq.com](https://debugbox.ibtisam-iq.com)**

This is **fully production-grade** and follows **CNCF-level standards**.

---
