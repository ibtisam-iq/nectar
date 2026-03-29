# nginx.conf — The Master Configuration File

## What Is It?

`/etc/nginx/nginx.conf` is the **main configuration file** for Nginx.
It is the first file Nginx reads when it starts. Everything about how
Nginx behaves globally is defined here.

## Where Is It?

```
/etc/nginx/nginx.conf        ← works on both Ubuntu and CentOS
```

## What Does It Look Like?

Here is a simplified version of what you will find inside:

```nginx
user www-data;                        # Which system user runs Nginx
worker_processes auto;                # How many CPU cores to use

error_log /var/log/nginx/error.log;  # Where to write error logs
pid /run/nginx.pid;                   # File that stores Nginx's process ID

events {
    worker_connections 1024;          # Max simultaneous connections per worker
}

http {
    include /etc/nginx/mime.types;    # File type definitions (html, css, jpg, etc.)
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;  # Where to log all requests

    sendfile on;
    keepalive_timeout 65;

    # This line is what connects nginx.conf to your actual site configs
    include /etc/nginx/sites-enabled/*;    # Ubuntu/Debian
    # include /etc/nginx/conf.d/*.conf;    # CentOS/RHEL
}
```

## Breaking Down Each Section

### `user`
Defines which Linux system user runs the Nginx worker processes.
On Ubuntu this is `www-data`. On CentOS it is `nginx`.
This matters for **file permissions** — the web root folder must be
readable by this user.

### `worker_processes auto`
Tells Nginx how many worker processes to create. `auto` means
use one process per CPU core. More workers = handles more traffic.

### `events { worker_connections 1024; }`
Each worker process can handle up to 1024 simultaneous connections.
Total capacity = `worker_processes × worker_connections`.

### `http { ... }`
Everything inside here defines how Nginx handles HTTP traffic.
This is where your website configuration lives.

### `include /etc/nginx/sites-enabled/*;`
This is the most important line. Instead of putting all site configurations
inside `nginx.conf` directly, Nginx reads separate files from `sites-enabled/`.
This keeps things organized — each website gets its own file.

## When Do You Edit `nginx.conf`?

You edit `nginx.conf` when you want to change **global** behavior:
- Increase the number of worker processes
- Change log file paths
- Tune performance settings
- Configure global SSL settings

For individual website configuration, you use `sites-enabled/` instead.


