# /etc/nginx/sites-enabled/default — Your Website's Configuration

## The Big Picture: Three Related Directories

On Ubuntu/Debian, Nginx organizes site configs across three locations:

```
/etc/nginx/
├── nginx.conf                    ← Master config (reads the others)
├── sites-available/              ← All site configs are STORED here
│   └── default                   ← The default site config file
└── sites-enabled/                ← Only ACTIVE site configs live here
    └── default -> ../sites-available/default   ← Symlink (shortcut)
```

## What is `sites-available`?

This is a folder where you **store** your website configuration files.
Files here are NOT active — Nginx ignores them unless they are also
in `sites-enabled`. Think of it as your drafts folder.

## What is `sites-enabled`?

This is a folder of **active** site configurations. Nginx reads every
file in this folder when it starts. But here is the key: files in
`sites-enabled` are not real files — they are **symlinks** (shortcuts)
pointing to files in `sites-available`.

## Why This Design?

This system lets you:
- **Enable** a site: create a symlink in `sites-enabled`
- **Disable** a site: delete the symlink (the original file stays safe in `sites-available`)

```bash
# Enable a site
sudo ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/

# Disable a site (original file is NOT deleted)
sudo rm /etc/nginx/sites-enabled/mysite
```

## What Is Inside `/etc/nginx/sites-enabled/default`?

This is the configuration for the **default website** — the one Nginx serves
when no other site matches the request. Here is what it looks like:

```nginx
server {
    listen 80;                        # Listen on port 80 (HTTP)
    listen [::]:80;                   # Also listen on IPv6

    server_name _;                    # Match ANY domain or IP (wildcard)

    root /var/www/html;               # ← This is your web root!
    index index.html index.htm;       # Files to look for first

    location / {
        try_files $uri $uri/ =404;    # Try to find the file, return 404 if not found
    }
}
```

## Breaking Down Each Line

| Directive | What It Means |
|---|---|
| `listen 80` | Accept HTTP traffic on port 80 |
| `server_name _` | `_` means "match everything" — catch-all for any IP or domain |
| `root /var/www/html` | The folder where your HTML files live (your web root) |
| `index index.html` | When someone visits `/`, serve `index.html` automatically |
| `try_files $uri $uri/ =404` | Try to find the requested file; if not found, return a 404 error |

## Ubuntu vs CentOS: Sites-Enabled Does Not Exist on CentOS

This is another key difference:

| Feature | Ubuntu/Debian | CentOS/RHEL |
|---|---|---|
| Site config location | `/etc/nginx/sites-available/` + `/etc/nginx/sites-enabled/` | `/etc/nginx/conf.d/` |
| Default config file | `/etc/nginx/sites-enabled/default` | `/etc/nginx/conf.d/default.conf` |
| Include line in nginx.conf | `include /etc/nginx/sites-enabled/*` | `include /etc/nginx/conf.d/*.conf` |

On CentOS, there is no `sites-available/sites-enabled` pattern. All
active site configs go directly into `/etc/nginx/conf.d/`.

## When Do You Edit This File?

Edit `sites-enabled/default` when you want to:

- Change the web root to a different folder
- Add a domain name to `server_name`
- Configure HTTPS/SSL
- Set up a reverse proxy to a backend app
- Redirect HTTP to HTTPS

## Full Flow Summary

```
Browser request → port 80 → Nginx
    → reads nginx.conf
    → nginx.conf says "include sites-enabled/*"
    → reads sites-enabled/default
    → finds: root /var/www/html, index index.html
    → reads /var/www/html/index.html
    → sends it back to browser
```
