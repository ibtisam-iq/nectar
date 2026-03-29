# Default Web Root

## What is a "Web Root"?

The **web root** is the folder on your server where Nginx looks for
your HTML files to serve. When someone visits your IP or domain,
Nginx reads `index.html` from this folder and sends it to the browser.

Think of it like this: Nginx is a librarian. The web root is the library.
When someone asks for a book (a webpage), the librarian goes to the
library (web root) and fetches it.

## The Problem: Ubuntu and CentOS Use Different Web Roots

This is one of the most common mistakes — even for experienced engineers.
The location of the web root depends on which Linux distribution you are using.

| Operating System | Package Manager | Web Root Path |
|---|---|---|
| **Ubuntu / Debian** | `apt` | `/var/www/html/` |
| **CentOS / RHEL / Amazon Linux** | `yum` / `dnf` | `/usr/share/nginx/html/` |

## Why Are They Different?

This is a result of how each Linux distribution decided to organize system files:

- **Debian/Ubuntu** follows the **FHS (Filesystem Hierarchy Standard)** convention
  of putting user-served web content under `/var/www/`
- **Red Hat/CentOS** packages Nginx with content under `/usr/share/nginx/html/`
  as part of the Nginx package's own shared data

Neither is wrong. They are just different conventions that each distro adopted.

## How to Always Find the Correct Web Root

You never have to guess. Run this command on any server:

```bash
grep -r "root" /etc/nginx/sites-enabled/default    # Ubuntu/Debian
grep -r "root" /etc/nginx/nginx.conf               # CentOS/RHEL
```

The output will look like:

```
root /var/www/html;
```

Whatever path appears after `root` — that is your web root.

## Practical Example

### On Ubuntu EC2:
```bash
# CORRECT — this works
echo "Love you Ibtisam from London" | sudo tee /var/www/html/index.html

# WRONG — nginx will NOT serve this file
echo "Love you Ibtisam from London" | sudo tee /usr/share/nginx/html/index.html
```

### On CentOS EC2:
```bash
# CORRECT — this works
echo "Love you Ibtisam from Mumbai" | sudo tee /usr/share/nginx/html/index.html
```

## Why `sudo tee` Instead of `sudo echo > file`?

This is another classic gotcha. The `>` redirection is handled by the **shell**,
not by the command itself. So even if you write `sudo echo "..."`, the shell
tries to open the file for writing — and it does this as your regular user
(e.g., `ubuntu`), not as root. Permission is denied.

`sudo tee` works because `tee` is the program that opens and writes the file,
and you are running `tee` with sudo — so it has root permission.

```bash
# This FAILS — shell opens the file as ubuntu user
sudo echo "hello" > /var/www/html/index.html

# This WORKS — tee opens the file as root
echo "hello" | sudo tee /var/www/html/index.html
```
