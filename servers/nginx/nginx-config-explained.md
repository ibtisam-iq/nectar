# Nginx Configuration — Complete Guide

> **Who is this for?** You have written Nginx config files before, they worked, but you never fully understood *why*. This guide explains every directive using your own real project files as examples. After reading this, you will be able to write any Nginx config from scratch — for bare metal, Docker, or any other setup.

---

## 🧠 The Big Picture — What Is Nginx Actually Doing?

Imagine your application is a **restaurant kitchen**. The kitchen is great at cooking (running your app), but it cannot talk directly to every customer walking in off the street.

Nginx is the **waiter** standing at the front door.

- Every customer (browser, API client) talks to the waiter (Nginx)
- The waiter decides: *"Is this a static file order? I'll handle it myself."* or *"Is this an API order? Let me pass it to the kitchen (Express/Node/Jenkins)."*
- The kitchen never needs to face the street directly

This is the **reverse proxy** pattern. Nginx sits in front of everything.

---

## 🗂️ The Two Files — Understanding the File System

When you install Nginx on Ubuntu, it creates this structure:

```
/etc/nginx/
├── nginx.conf                        ← MASTER config (global brain)
├── conf.d/
│   └── default.conf                  ← YOUR site config (goes here for Docker/CentOS)
└── sites-available/
    └── ibtisam-iq.com                ← YOUR site config (goes here for Ubuntu bare metal)
sites-enabled/
    └── default                       ← Symlink — active sites live here
```

### `nginx.conf` — The Master Brain

You almost **never edit this file**. It controls global things like:
- How many worker processes to spawn
- Where to write logs
- Which other config files to load

The most important line inside it is:

```nginx
include /etc/nginx/conf.d/*.conf;
```

This means: *"Load every `.conf` file from the `conf.d/` folder."* That is how your `default.conf` gets picked up automatically.

On Ubuntu, there is also:

```nginx
include /etc/nginx/sites-enabled/*;
```

### Why You Always `rm /etc/nginx/sites-enabled/default`

Ubuntu ships with a default site already enabled in `sites-enabled/`. That default site **also listens on port 80** — same as yours. Two sites on the same port = conflict. Nginx picks one and ignores the other.

So in your bare-metal project, you always do:

```bash
# Copy YOUR config in
sudo cp default.conf /etc/nginx/conf.d/

# Remove the built-in one that conflicts
sudo rm /etc/nginx/sites-enabled/default

# Test and restart
sudo nginx -t
sudo systemctl restart nginx
```

In **Docker**, there is no pre-existing default site conflict — it is a clean container. So you just `COPY` your config in and you are done.

---

## 🧩 Every Directive Explained — Line by Line

We will use your real files throughout. Here is your Docker `nginx.conf` (from your node app project) as the base:

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://server:5000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### `server { }` — The Virtual Host Box

```nginx
server {
    ...
}
```

**What it is:** One `server {}` block = one website or one application.

Think of it as a **separate room** for each site. Nginx can run many rooms at the same time on the same machine — one room for your React app, one for Jenkins, one for your API. When a request arrives, Nginx checks which room it belongs to and routes it there.

You can have multiple `server {}` blocks in the same file, or in separate `.conf` files — Nginx loads all of them.

---

### `listen 80;` — Which Door to Stand At

```nginx
listen 80;
```

**What it is:** The port number Nginx watches for incoming connections.

- Port **80** = HTTP (regular web traffic)
- Port **443** = HTTPS (encrypted traffic)
- Port **8080** = alternative HTTP (often used in development)

When someone types `http://yoursite.com` in a browser, the browser automatically connects to port 80. That request arrives at Nginx because Nginx is listening there.

```nginx
# HTTPS example (for reference)
listen 443 ssl;
```

You can also write:
```nginx
listen 80 default_server;
```
The `default_server` flag means: *"If no other `server {}` block matches the incoming request, use this one as the fallback."* You saw this in your Jenkins config.

---

### `server_name` — Which Domain Am I Responsible For?

```nginx
# Your Docker config
server_name localhost;

# Your Jenkins config
server_name _;

# Real domain example
server_name jenkins.ibtisam-iq.com;
```

**What it is:** When a browser makes a request, it sends a `Host` header — basically telling Nginx *"I am trying to reach this domain."* `server_name` is how Nginx matches that header to the right `server {}` block.

| Value | Meaning |
|---|---|
| `localhost` | Only match requests going to `localhost` |
| `jenkins.ibtisam-iq.com` | Only match that exact domain |
| `ibtisam-iq.com www.ibtisam-iq.com` | Match either of these two domains |
| `_` | **Catch-all** — match ANY hostname, no matter what |

**Why `_` in Docker?**
Inside a Docker network, containers talk to each other using service names (like `nginx`, `server`, `db`). There is no real domain name. Using `_` means *"I do not care what name was used — just handle the request."* It is the right choice for containers.

**Why `localhost` for bare metal dev?**
When you are testing locally, the browser sends `Host: localhost`. So `server_name localhost` matches it.

---

### `root` — Where Are My Files?

```nginx
# Docker
root /usr/share/nginx/html;

# Bare metal
root /home/ibtisam/node-monolith-app/client/dist;
```

**What it is:** The folder on disk where Nginx looks for static files (HTML, CSS, JS, images).

When a browser asks for `/bundle.js`, Nginx literally opens:
```
root + /bundle.js
= /usr/share/nginx/html/bundle.js
```

**Why different paths?**

- **Docker:** The official Nginx Docker image serves files from `/usr/share/nginx/html`. In your Dockerfile, you do `COPY client/dist/ /usr/share/nginx/html/` to put your built React app there.
- **Bare metal:** Your `npm run build` output went to `/home/ibtisam/node-monolith-app/client/dist`. So you point `root` directly at that real path on the server.

This is the **main difference** between your bare-metal and Docker configs. The logic is identical — only the path changes.

---

### `index` — What to Serve When No File Is Requested

```nginx
index index.html;
```

**What it is:** When someone visits just `/` (no filename), which file should Nginx serve?

- Browser requests `http://localhost/`
- Nginx looks for: `root` + `index.html` = `/usr/share/nginx/html/index.html`
- Serves that file

You can list multiple fallbacks:
```nginx
index index.html index.htm;
```
Nginx tries them left to right and serves the first one it finds.

---

## 📍 `location` Blocks — The Heart of Routing

This is the most important concept. `location` blocks are **URL pattern matchers**. Nginx reads the path of every incoming request and finds the best matching `location` block to handle it.

```nginx
location /some-path {
    # instructions for requests matching /some-path
}
```

### How Nginx Picks the Right `location`

Nginx has a priority system. The **most specific match wins**:

| Syntax | Type | Priority |
|---|---|---|
| `location = /exact` | Exact match | Highest |
| `location ^~ /prefix` | Prefix, stop searching | High |
| `location ~ \.php$` | Regex, case-sensitive | Medium |
| `location ~* \.jpg$` | Regex, case-insensitive | Medium |
| `location /prefix` | Prefix match | Low |
| `location /` | Catch-all | Lowest |

In your config, you have:
- `location /api/` — prefix match for API routes
- `location /` — catch-all for everything else

A request to `/api/users` matches **both**, but `/api/` is more specific — so it wins.

---

### `location /` — Serve Your React App

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

This catches **all requests** that do not match a more specific location.

#### `try_files` — The Three-Step Fallback

`try_files` tries each option left to right, and serves the first one that exists:

```
Request: /bundle.js

Step 1: $uri        → look for /usr/share/nginx/html/bundle.js on disk
                      → FOUND → serve it ✅

Request: /images/logo.png

Step 1: $uri        → look for /usr/share/nginx/html/images/logo.png
                      → FOUND → serve it ✅

Request: /dashboard/users

Step 1: $uri        → look for /usr/share/nginx/html/dashboard/users  → NOT FOUND
Step 2: $uri/       → look for /usr/share/nginx/html/dashboard/users/ → NOT FOUND
Step 3: /index.html → serve /usr/share/nginx/html/index.html          → FOUND ✅
```

**Why is Step 3 needed?**

Your React app uses React Router. Routes like `/dashboard/users` exist inside JavaScript — they are **not real files on disk**. If someone pastes that URL directly in the browser, Nginx would return a 404 because there is no such file.

Step 3 saves it: Nginx serves `index.html` instead, React loads, React Router reads the URL, and renders the right page. The user never sees an error.

---

### `location /api/` — Forward to Your Backend

```nginx
# Docker version
location /api/ {
    proxy_pass http://server:5000;
    ...
}

# Bare metal version
location /api/ {
    proxy_pass http://localhost:5000;
    ...
}
```

**What it is:** Any request whose URL starts with `/api/` gets **forwarded to your Express backend** instead of looking for a file on disk.

```
Browser → GET /api/users → Nginx → forwards to Express:5000/api/users → gets response → returns to browser
```

The browser only ever talks to Nginx on port 80. It never knows port 5000 exists.

**Why different `proxy_pass` URLs?**

| Environment | Value | Reason |
|---|---|---|
| Docker | `http://server:5000` | `server` is the Docker Compose service name. Docker's internal DNS resolves it to the container's IP automatically. |
| Bare metal | `http://localhost:5000` | Express is running as a process on the same machine. `localhost` points to the same server. |

---

## 📬 `proxy_set_header` — Passing the Real Info Through

```nginx
proxy_set_header Host              $host;
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

**The problem:** When Nginx forwards a request to Express, it creates a **brand new HTTP request**. Without these lines, Express would receive wrong information:
- `Host` would show Nginx's internal hostname, not the browser's original domain
- The client IP would show Nginx's container IP, not the real user's IP

**The solution:** These headers carry the original values forward so Express sees the real request.

| Header | Variable | What It Contains |
|---|---|---|
| `Host` | `$host` | The domain the browser originally requested (`localhost`, `jenkins.ibtisam-iq.com`, etc.) |
| `X-Real-IP` | `$remote_addr` | The actual IP address of the user/client |
| `X-Forwarded-For` | `$proxy_add_x_forwarded_for` | Full chain of IPs if multiple proxies are involved |
| `X-Forwarded-Proto` | `$scheme` | Was it `http` or `https`? |

In Express/Node.js, you read these with `req.headers['x-real-ip']` or by enabling `trust proxy`.

---

### `proxy_http_version 1.1;` — Keep Connections Alive

```nginx
proxy_http_version 1.1;
```

By default, Nginx uses HTTP/1.0 when forwarding requests. HTTP/1.0 **closes the TCP connection after every single request**. That means for every API call, a new connection must be created — slow.

HTTP/1.1 supports **keep-alive** — the connection stays open and is reused for multiple requests. Always include this line when proxying.

---

## 🔁 Advanced Directives — From Your Jenkins Config

Your Jenkins config at [silver-stack/iximiuz/rootfs/jenkins/configs/nginx.conf](https://github.com/ibtisam-iq/silver-stack/blob/main/iximiuz/rootfs/jenkins/configs/nginx.conf) introduces more powerful concepts.

---

### `upstream` — Named Backend Pool

```nginx
upstream jenkins {
    server 127.0.0.1:__JENKINS_PORT__ fail_timeout=0;
    keepalive 32;
}
```

**What it is:** Instead of writing `proxy_pass http://127.0.0.1:8080;` directly, you give your backend a **name** and reference it.

```nginx
# Without upstream (basic)
proxy_pass http://127.0.0.1:8080;

# With upstream (better)
upstream jenkins {
    server 127.0.0.1:8080;
}
proxy_pass http://jenkins;   # use the name
```

**Why bother?** Because `upstream` unlocks extra features:

| Feature | What it does |
|---|---|
| Multiple servers | Add 3 servers → Nginx load-balances between them automatically |
| `fail_timeout=0` | Keep trying even if the server is temporarily down |
| `keepalive 32` | Keep 32 idle connections open and reuse them (much faster) |

For a single server it is cleaner and easier to extend later.

---

### `map` — Smart Variable Mapping

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      "";
}
```

**What it is:** `map` creates a new variable based on the value of another variable. It is like a lookup table.

**Why is this needed for Jenkins?**
Jenkins uses **WebSockets** for real-time updates (build logs streaming live in the browser). WebSockets require a special HTTP upgrade handshake:

```
Browser → "Upgrade: websocket" header
Nginx  → must forward this header to Jenkins
```

This `map` block says:
- If `$http_upgrade` has any value (like `websocket`) → set `$connection_upgrade` to `upgrade`
- If `$http_upgrade` is empty (normal HTTP request) → set `$connection_upgrade` to empty string

Then in the `location` block:
```nginx
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection $connection_upgrade;
```

This correctly handles both normal HTTP and WebSocket connections through the same proxy.

---

### `ignore_invalid_headers off;`

```nginx
ignore_invalid_headers off;
```

By default, Nginx **drops any header it does not recognize**. Jenkins sends some custom headers that Nginx would silently discard. This line tells Nginx: *"Pass all headers through, even unusual ones."*

---

### `proxy_buffering off;` and `proxy_request_buffering off;`

```nginx
proxy_buffering         off;
proxy_request_buffering off;
```

**The problem with buffering:**
Normally, when Jenkins sends a response (like a live build log), Nginx buffers the entire thing in memory before forwarding it to the browser. This means the browser sees **nothing** until the whole response is ready — bad for live logs.

**`proxy_buffering off`:** Send Jenkins's response to the browser **as it arrives**, byte by byte. The browser sees live streaming output immediately.

**`proxy_request_buffering off`:** Do not buffer the incoming request either. Important for large file uploads (like uploading a build artifact to Jenkins).

---

### `proxy_redirect off;`

```nginx
proxy_redirect off;
```

Sometimes the backend sends a `Location: http://127.0.0.1:8080/newpath` redirect header. Without this line, Nginx would rewrite that URL — but it might get it wrong. `proxy_redirect off` tells Nginx: *"Do not touch redirect headers. Pass them exactly as Jenkins sends them."*

---

### Timeout Directives

```nginx
proxy_connect_timeout  150s;
proxy_send_timeout     100s;
proxy_read_timeout     100s;
```

| Directive | What it controls |
|---|---|
| `proxy_connect_timeout` | How long to wait when first connecting to the backend (Jenkins) |
| `proxy_send_timeout` | How long to wait between packets being sent to Jenkins |
| `proxy_read_timeout` | How long to wait for Jenkins to send back a response |

Jenkins can be slow to start and slow to respond during long builds. These generous timeouts (100–150 seconds) prevent Nginx from giving up too early and showing a 504 Gateway Timeout error.

---

### Regex `location` Blocks

```nginx
# Match static files by extension
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    proxy_pass http://jenkins;
    expires 1d;
    add_header Cache-Control "public, immutable" always;
}
```

`~*` means **case-insensitive regex match**. This catches any URL ending in `.js`, `.css`, `.png`, etc.

- `expires 1d` — tell the browser to cache this file for 1 day
- `add_header Cache-Control "public, immutable"` — confirm to the browser: this file will never change, cache it aggressively

Result: static assets load from the browser cache on repeat visits instead of hitting Jenkins every time.

```nginx
# Match Jenkins's versioned static paths
location ~ "^/static/[0-9a-f]{8}/(.*)$" {
    rewrite "^/static/[0-9a-f]{8}/(.*)" /$1 last;
}
```

Jenkins serves static files at paths like `/static/a3f9c1b2/css/style.css`. This regex strips the hash part and redirects to `/css/style.css`. The `[0-9a-f]{8}` matches any 8-character hex string.

---

### Security Headers

```nginx
add_header X-Frame-Options        "SAMEORIGIN"                      always;
add_header X-Content-Type-Options "nosniff"                         always;
add_header X-XSS-Protection       "1; mode=block"                   always;
add_header Referrer-Policy        "strict-origin-when-cross-origin" always;
```

These are **browser security instructions** sent with every response:

| Header | What it prevents |
|---|---|
| `X-Frame-Options: SAMEORIGIN` | Stops other websites from embedding your site in an `<iframe>` (clickjacking attack) |
| `X-Content-Type-Options: nosniff` | Stops browser from guessing file types — if you say it is CSS, browser must treat it as CSS |
| `X-XSS-Protection: 1; mode=block` | Tells older browsers to block pages if cross-site scripting is detected |
| `Referrer-Policy` | Controls how much URL info is shared when clicking links to other sites |

---

### Health Check Endpoint

```nginx
location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
}
```

**What it is:** A dedicated URL that just returns `200 healthy`. No proxy, no file lookup.

- Kubernetes liveness probes, load balancers, and monitoring tools (Prometheus, UptimeRobot) hit `/health` to check if Nginx is alive
- `access_log off` prevents these automated pings from flooding your access logs

---

## 🏗️ The Full Mental Model — Bare Metal vs Docker

Here is everything side by side so you can see exactly what changes and why:

| Setting | Bare Metal | Docker |
|---|---|---|
| `root` | Real path on server: `/home/ibtisam/app/client/dist` | Container path: `/usr/share/nginx/html` |
| `proxy_pass` | `http://localhost:5000` | `http://server:5000` (service name) |
| `server_name` | `localhost` or real domain | `_` (catch-all) |
| How config is loaded | Copy to `/etc/nginx/conf.d/`, remove `sites-enabled/default` | `COPY nginx.conf /etc/nginx/conf.d/default.conf` in Dockerfile |
| Port exposure | Nginx already listens on port 80 of the server | `ports: - "80:80"` in docker-compose.yml |

Everything else — `location` blocks, `proxy_set_header`, `try_files` — is **identical**.

---

## 📝 Quick Reference — When to Use What

```
I want to serve a React/Vue/Angular app
└── location / { try_files $uri $uri/ /index.html; }

I want to forward /api/ requests to my Node/Express backend
└── location /api/ { proxy_pass http://backend:5000; }

I want to run Jenkins behind Nginx
└── upstream jenkins { server 127.0.0.1:8080; }
    location / { proxy_pass http://jenkins; }

I want WebSocket support (live logs, real-time features)
└── map $http_upgrade $connection_upgrade { ... }
    proxy_set_header Upgrade    $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

I want browser caching for static files
└── location ~* \.(js|css|png|jpg)$ { expires 1d; }

I want a health check endpoint
└── location /health { return 200 "healthy\n"; }

I want HTTPS (SSL)
└── listen 443 ssl;
    ssl_certificate     /etc/letsencrypt/live/domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/domain/privkey.pem;
```

---

## ✅ Checklist — Before You `nginx -t`

- [ ] `server_name` matches how this will be accessed (`localhost`, `_`, or real domain)
- [ ] `root` points to the actual folder where your built files live
- [ ] `proxy_pass` URL uses `localhost` for bare metal, service name for Docker
- [ ] All `proxy_set_header` lines are present in every `location` that proxies
- [ ] `try_files $uri $uri/ /index.html` in the `/` location for React apps
- [ ] `proxy_http_version 1.1;` in all proxy locations
- [ ] Run `sudo nginx -t` before restarting — it will tell you exactly which line has an error
