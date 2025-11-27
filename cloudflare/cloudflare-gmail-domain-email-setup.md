# Using Cloudflare + Gmail to Send and Receive Email from `contact@your-domain.com`

> Goal:  
> - Receive emails sent to `contact@your-domain.com` inside Gmail  
> - Reply from Gmail, but the recipient only sees `contact@your-domain.com`  
> - Your real Gmail address never gets exposed

We’ll do this in **three big steps**:

1. Attach your domain to Cloudflare  
2. Configure Cloudflare Email Routing  
3. Configure Gmail to send as `contact@your-domain.com`

Along the way, we’ll also cover **what NOT to do** and some common pitfalls.

---

## 0. Prerequisites

You should already have:

- A domain name (e.g. `your-domain.com`) registered at a provider like GoDaddy, Namecheap, etc.
- A free Cloudflare account
- A Gmail account (e.g. `your-gmail@gmail.com`) where you want to read and send mail

In examples below, we’ll use:

```text
Domain:        your-domain.com
Cloudflare:    your Cloudflare account
Gmail:         your-gmail@gmail.com
Public email:  contact@your-domain.com
````

Replace these with your own values when you follow the steps.

---

## STEP 1 – Attach Your Domain to Cloudflare

### 1.1 Onboard the domain in Cloudflare

1. Log in to **Cloudflare Dashboard**.

2. On the main “Account home” page, click
   **`Onboard a domain`** (Cloudflare’s wording – not “Add site”).

3. In the field **“Enter an existing domain”**, type your domain:

   ```text
   your-domain.com
   ```

4. On the next screen:

   * Choose **Quick scan DNS records (Recommended)**

     * Good because Cloudflare auto-detects existing DNS records
     * You don’t have to copy DNS entries manually
   * Leave advanced options (manual entry / zone file upload) **unchecked** unless you know exactly what you’re doing.

5. Cloudflare may ask how to handle **AI crawlers**:

   * You can safely choose **Block on all pages** if you want to protect your content.

6. Make sure the **robots.txt** / “Instruct AI bot traffic” toggle is **ON**.

7. Click **Continue**.

At this point Cloudflare has scanned your DNS, but your domain is **not active on Cloudflare yet**.

---

### 1.2 Update nameservers at your domain registrar

Cloudflare now shows a page like:

> **Last step: Update your nameservers to activate Cloudflare**

It provides two nameservers, for example:

```text
alice.ns.cloudflare.com
bob.ns.cloudflare.com
```

> These are just examples – use the actual ones Cloudflare shows you.

Now you must change your domain’s nameservers at the registrar (GoDaddy, etc.).

**In GoDaddy (similar in other registrars):**

1. Log in to GoDaddy.

2. Go to **My Products → Domains** and open your domain `your-domain.com`.

3. Go to **DNS** or **Domain Settings**.

4. Find the **Nameservers** section (this is important – do *not* confuse it with the DNS Records list).

5. Change the nameserver type to **Custom** (if needed).

6. Replace existing nameservers with the two Cloudflare nameservers, e.g.:

   ```text
   alice.ns.cloudflare.com
   bob.ns.cloudflare.com
   ```

7. Save the changes.

> ⛔ **Common mistake:**
> Editing NS records inside the **DNS Records list** instead of the **Nameservers** section.
> In many registrars, those NS records are locked (“Can’t edit / Can’t delete”). That’s normal. You must change nameservers using the dedicated *Nameservers* control, not by editing DNS records.

---

### 1.3 Wait for Cloudflare to activate the zone

Back in Cloudflare, click:

```text
Check nameservers
```

Now wait until the domain status becomes **Active**.

This can take from a few minutes up to an hour (rarely longer).

**Once status is Active, STEP 1 is complete.**

---

## STEP 2 – Configure Cloudflare Email Routing

Now we want:

```text
Any mail sent to contact@your-domain.com
→ automatically forwarded to your-gmail@gmail.com
```

### 2.1 Open Email Routing for your domain

1. In Cloudflare, click your domain `your-domain.com`.
2. In the left sidebar, click **Email**.
3. Click **Email Routing**.

You’ll see tabs like:

```text
Overview | Routing rules | Destination addresses | Email Workers | Settings
```

---

### 2.2 Enable Email Routing and MX records

In the **Overview** tab:

1. Click **Enable Email Routing**.
2. Cloudflare will propose adding **MX records** and related records.
3. Click **Add records and enable**.

Now wait until the **Routing status** on the Overview tab shows:

```text
Routing status: Enabled ✅
```

> ⛔ Don’t continue until this is enabled, otherwise emails may not be routed correctly.

---

### 2.3 Add the destination address (Gmail) – do this **first**

Now go to the **Destination addresses** tab.

1. Click **Add destination address**.

2. Enter the Gmail address where you want to receive mail, e.g.:

   ```text
   your-gmail@gmail.com
   ```

3. Click **Add** / **Save**.

Cloudflare now sends a **verification email** to that Gmail inbox.

4. Open Gmail, find the verification email, and click the **Verify** link.
5. Back in Cloudflare, make sure the destination address shows as **Verified**.

> 💡 Sequence matters:
> You must add and verify the destination address *before* creating the routing rule.
> Later, when you create the rule for `contact@your-domain.com`, Cloudflare will ask which destination you want – if you haven’t added any destination yet, you’ll get stuck.

---

### 2.4 Create the routing rule for `contact@your-domain.com`

Now go to the **Routing rules** tab.

1. Scroll to **Custom addresses**.

2. Click **Create address**.

3. Fill in:

   * **Custom address:**

     ```text
     contact
     ```

     (This becomes `contact@your-domain.com`.)

   * **Action:**

     ```text
     Send to an email
     ```

   * **Destination:**
     Choose your verified Gmail `your-gmail@gmail.com`.

4. Click **Save**.

You should now see a rule similar to:

```text
Custom address:  contact@your-domain.com
Action:          Send to an email
Destination:     your-gmail@gmail.com
Status:          Active
```

---

### 2.5 Catch-all behaviour (optional but important to understand)

On the same **Routing rules** page you may see a **Catch-All** entry.

* **Catch-All** – applies to emails sent to any address at your domain that you have **not** explicitly created (e.g. `abc@your-domain.com`, `random@your-domain.com`, etc.)
* **Action: Drop** – means those emails are discarded.
* **Status: Disabled** – means the catch-all rule is currently **off**.

For most setups, the safest choice is:

```text
Catch-All → Drop → Disabled
```

That way:

* Only explicitly defined addresses (like `contact@your-domain.com`) work.
* Everything else is dropped.
* You don’t get flooded with spam to random addresses.

---

### 2.6 Test the forwarding

From any email account (not the same Gmail), send a message to:

```text
contact@your-domain.com
```

You should receive it in your Gmail inbox (`your-gmail@gmail.com`).

If it doesn’t arrive:

* Check Cloudflare **Overview → Routing status** is Enabled.
* Check the rule status is **Active**.
* Check **Spam / Promotions / Updates** folders in Gmail.
* Give it a couple of minutes; new DNS-based setups can have a short delay.

**Once this works, STEP 2 is complete.**

---

## STEP 3 – Configure Gmail to Send as `contact@your-domain.com`

So far we can **receive** mail to `contact@your-domain.com` in Gmail.
Now we want to **send and reply** *from* that address so recipients see only:

```text
From: Your Name <contact@your-domain.com>
```

### 3.1 Open Gmail “Send mail as” settings

1. Open Gmail (`your-gmail@gmail.com`).
2. Click ⚙️ and then **See all settings**.
3. Go to the **Accounts and Import** tab.
4. Find the section **Send mail as**.

---

### 3.2 Add the new “From” address

1. Click **Add another email address**.

2. In the popup, enter:

   ```text
   Name:  Your Name
   Email: contact@your-domain.com
   ```

3. There is a checkbox:

   ```text
   Treat as an alias
   ```

   **Recommendation:**

   * Uncheck this box for a clean, professional identity separation.

   If it remains checked, Gmail sometimes treats this identity as just another label on your Gmail, which can cause confusing behaviour.

4. Click **Next Step**.

---

### 3.3 Choose the sending method (SMTP)

Gmail now asks how to send mail for this address.

You’ll see two conceptual approaches:

#### ✅ Recommended: “Send through Gmail”

This is the simplest and most reliable.
Gmail handles SMTP using your existing Gmail infrastructure, but shows `contact@your-domain.com` as the “From” address.

If you see this option, use it.

#### ❌ Do **not** use Cloudflare’s MX host as SMTP

Sometimes Gmail guesses something like:

```text
SMTP Server: route3.mx.cloudflare.net
```

This is **wrong** for sending.

* Cloudflare Email Routing’s MX servers are **receive-only**.
* They do not provide user accounts or passwords.
* Trying to use them as SMTP will fail.

If you want to configure SMTP manually instead of using “Send through Gmail”, the correct configuration is:

```text
SMTP server: smtp.gmail.com
Port:        587
Security:    TLS
Username:    your-gmail@gmail.com
Password:    Gmail App Password (not your regular password)
```

> 🔐 **Gmail App Password**
>
> * Go to `https://myaccount.google.com`
> * Search for **App passwords**
> * Enable 2-step verification if required
> * Generate an app password for “Mail”
> * Use that 16-digit password in the SMTP dialog

But again, if “Send through Gmail” is available, prefer that – it is simpler and harder to break.

---

### 3.4 Handle Gmail’s verification email (and delays)

After you choose the sending method, Gmail will send a verification email to:

```text
contact@your-domain.com
```

Because of Cloudflare routing, it will arrive in:

```text
your-gmail@gmail.com
```

**Important real-world note:**

This verification email is not always instant. Delays can be caused by:

* DNS propagation
* Cloudflare’s forwarding pipeline
* Gmail’s internal filtering

Correct behaviour here is:

```text
Wait 1–5 minutes
Refresh your inbox
Check Spam / Promotions as well
Do not start changing settings impulsively
```

When the email arrives:

1. Open it in Gmail.
2. Click the verification link OR copy the code and paste it into the Gmail popup.

After verification, your new “From” address is ready.

---

### 3.5 Make `contact@your-domain.com` the default sender

Back in Gmail settings → **Accounts and Import**:

1. In **Send mail as**, click:

   ```text
   Make default
   ```

   next to `contact@your-domain.com`.

2. Under **When replying to a message**, choose:

   ```text
   Always reply from default address
   ```

This ensures:

* Any replies you send will use `contact@your-domain.com`.
* New emails often default to that address too (see next point).

---

### 3.6 Understand Gmail UI delay and “From” dropdown

Even after setting the default, you might see:

* The **From** dropdown not appearing immediately when composing.
* Gmail still sometimes selecting your original Gmail for the very first message.

This is usually just UI caching.

**What to do:**

* Wait a bit.
* Refresh Gmail.
* Try closing and reopening the browser.

When you click **Compose** again, you should see:

* A **From** dropdown arrow.
* `contact@your-domain.com` selected by default (or at least available to choose).

For any new message, you can always click the **From** dropdown and manually select the correct sender.

---

### 3.7 Add a professional signature (optional, but recommended)

In Gmail:

1. Go to **Settings → General → Signature**.

2. Create a simple, professional signature, for example:

   ```text
   Your Name
   Your Role | Your Focus Area

   contact@your-domain.com
   https://your-domain.com
   ```

3. Apply basic formatting (bold name, subtle colours) using Gmail’s toolbar.

> Note: you cannot attach a “profile picture” to `contact@your-domain.com` via Gmail, because it’s not a full Google account – it’s an alias/forwarded identity.

---

## Overall Flow Diagram (Conceptual)

You can add a diagram like this in your docs:

**Email Flow:**

```text
Sender → contact@your-domain.com
        ↓
   Cloudflare Email Routing
        ↓
   your-gmail@gmail.com (inbox)
        ↓
Reply from Gmail as contact@your-domain.com
        ↓
      Recipient
```

---

## Common Pitfalls & How to Avoid Them

**1. Editing DNS Records instead of Nameservers**

* Symptom: Cloudflare says domain pending / inactive.
* Fix: Change nameservers in the registrar’s *Nameservers* section, not the DNS record list.

---

**2. Trying to use Cloudflare MX host as SMTP**

* Symptom: Gmail fails to send, asks for password repeatedly.
* Root cause: `routeX.mx.cloudflare.net` is receive-only.
* Fix: Use **Send through Gmail** or `smtp.gmail.com` with an App Password.

---

**3. Panicking when verification email doesn’t arrive instantly**

* Symptom: You keep changing settings, making the situation worse.
* Fix: Wait 1–5 minutes, check spam, then troubleshoot.

---

**4. “Treat as alias” confusion**

* Leaving it checked can cause some odd behaviour in complex setups.
* For most professional identities, unchecking it gives cleaner separation between:

  * your personal Gmail
  * your public business address.

---

## Final Checklist

You’re done when:

* [ ] Domain status in Cloudflare is **Active**
* [ ] Cloudflare Email Routing **Routing status: Enabled**
* [ ] `contact@your-domain.com` rule is **Active**, destination = your Gmail
* [ ] Gmail shows `contact@your-domain.com` in **Send mail as**
* [ ] You can:

  * [ ] Receive mail sent to `contact@your-domain.com` in your Gmail
  * [ ] Reply and send new emails **from** `contact@your-domain.com`
  * [ ] Your personal Gmail address does **not** appear to normal recipients

At that point, you have a **fully functioning professional email identity** on your own domain, powered by Cloudflare + Gmail.
