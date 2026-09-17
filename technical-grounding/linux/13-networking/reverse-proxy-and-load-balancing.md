# Reverse Proxy and Load Balancing

A reverse proxy accepts client connections and forwards each request to a backend server, which lets one address serve many backends, terminate TLS and hide failures. nginx and HAProxy are the usual Linux choices, and reading their logs explains most `502` and `504` errors.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Reverse vs forward proxy | A reverse proxy fronts servers for clients; a forward proxy fronts clients for the internet | architecture |
| nginx pieces | `upstream` block lists backends; `proxy_pass http://<upstream>` sends requests there | `sudo nginx -T` |
| Algorithms | Round robin (default), `least_conn`, `ip_hash`/`hash` (stickiness), weights | upstream config |
| Client address | Backends see the proxy's IP; the original goes in `X-Forwarded-For` | backend log |
| Passive checks | nginx open source marks a backend failed after `max_fails` errors for `fail_timeout` | nginx error log |
| Active checks | HAProxy `option httpchk` probes each server; `fall`/`rise` set the thresholds | `show stat` |
| 502 Bad Gateway | The proxy could not get a valid response: backend down, refused or crashed | error log `connect() failed` |
| 504 Gateway Timeout | The backend accepted but did not answer within `proxy_read_timeout` | error log `upstream timed out` |
| Retries | nginx tries the next upstream on connection errors (`proxy_next_upstream`) | `$upstream_addr` in the log |
| Validate first | `nginx -t`; `haproxy -c -f <file>` (silent on success, `-V` prints `Configuration file is valid`) | exit status |
| SELinux | On RHEL, nginx needs `httpd_can_network_connect` to reach backends on non-HTTP ports | `getsebool httpd_can_network_connect` |
| L4 vs L7 | Layer 4 forwards TCP (HAProxy `mode tcp`, nginx `stream`); layer 7 reads HTTP (paths, headers) | `mode` in config |
<!-- --8<-- [end:facts] -->

---

## nginx as a Load Balancer

`gw` proxies `shop.lab.internal` to the API on `web` (`172.16.1.3:8080`) and on `client` (`172.16.0.2:8080`). Each backend returns its own name, the address that connected, and `X-Forwarded-For`:

```bash
sudo cat /etc/nginx/conf.d/shop-proxy.conf
```

Output:

```text
upstream shop_api {
    server 172.16.1.3:8080 max_fails=2 fail_timeout=10s;
    server 172.16.0.2:8080 max_fails=2 fail_timeout=10s;
}

server {
    listen 80;
    server_name shop.lab.internal;

    access_log /var/log/nginx/shop-proxy.log upstreamlog;

    location / {
        proxy_pass http://shop_api;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
    }
}
```

The `upstreamlog` format, defined in `00-logformat.conf`, records `$upstream_addr`, `$upstream_status` and `$upstream_response_time`. From `client`:

```bash
for i in 1 2 3 4; do curl -s --resolve shop.lab.internal:80:172.16.0.3 http://shop.lab.internal/; done
sudo tail -4 /var/log/nginx/shop-proxy.log
```

Output:

```text
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=172.16.0.2
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=172.16.0.2
shop-api on client (172.16.0.2:8080) client=172.16.0.3 xff=172.16.0.2
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=172.16.0.2
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.1.3:8080 upstream_status=200 time=0.001
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.1.3:8080 upstream_status=200 time=0.000
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.0.2:8080 upstream_status=200 time=0.001
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.1.3:8080 upstream_status=200 time=0.000
```

The backends saw the proxy (`gw`'s address on each network) as the client, and the real client only in `xff`. The order is not strictly alternating: each of the two nginx worker processes keeps its own round-robin position, and a `zone` directive in the `upstream` block shares it.

!!! warning "Trust X-Forwarded-For only from your proxy"
    Clients can send their own `X-Forwarded-For`. Applications should take the client address from it only when the request came from a known proxy (`set_real_ip_from` and `real_ip_header` in nginx).

---

## When Backends Fail

With nginx stopped on `client`, then also on `web`:

```bash
for i in 1 2 3 4; do curl -s -o /dev/null -w '%{http_code}\n' --resolve shop.lab.internal:80:172.16.0.3 http://shop.lab.internal/; done
curl -si --resolve shop.lab.internal:80:172.16.0.3 http://shop.lab.internal/ | head -1
sudo tail -3 /var/log/nginx/shop-proxy.log
sudo tail -4 /var/log/nginx/error.log
```

Output:

```text
200
200
200
200
HTTP/1.1 502 Bad Gateway
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.1.3:8080 upstream_status=200 time=0.000
172.16.0.2 "GET / HTTP/1.1" 200 upstream=172.16.0.2:8080, 172.16.1.3:8080 upstream_status=502, 200 time=0.000, 0.000
172.16.0.2 "GET / HTTP/1.1" 502 upstream=172.16.1.3:8080, shop_api upstream_status=502, 502 time=0.000, 0.000
2026/09/17 12:22:48 [error] 4900#4900: *18 connect() failed (111: Connection refused) while connecting to upstream, client: 172.16.0.2, server: shop.lab.internal, request: "GET / HTTP/1.1", upstream: "http://172.16.0.2:8080/", host: "shop.lab.internal"
2026/09/17 12:22:48 [warn] 4900#4900: *18 upstream server temporarily disabled while connecting to upstream, client: 172.16.0.2, server: shop.lab.internal, request: "GET / HTTP/1.1", upstream: "http://172.16.0.2:8080/", host: "shop.lab.internal"
2026/09/17 12:22:55 [error] 4900#4900: *21 connect() failed (111: Connection refused) while connecting to upstream, client: 172.16.0.2, server: shop.lab.internal, request: "GET / HTTP/1.1", upstream: "http://172.16.1.3:8080/", host: "shop.lab.internal"
2026/09/17 12:22:55 [error] 4900#4900: *21 no live upstreams while connecting to upstream, client: 172.16.0.2, server: shop.lab.internal, request: "GET / HTTP/1.1", upstream: "http://shop_api/", host: "shop.lab.internal"
```

With one backend down, users still got `200`: the request that hit the dead backend was retried on `web` (`upstream_status=502, 200`), and the dead one was marked `temporarily disabled`. With both down, nginx answered `502 Bad Gateway`, and `no live upstreams` means every server was already marked failed.

!!! tip "Start every 502 in the proxy's error log"
    The error log names the backend and the reason: `Connection refused` (nothing listens), `upstream timed out` (slow or blocked backend, often a `504`), `Permission denied` on RHEL (SELinux boolean), or `no live upstreams`.

---

## HAProxy with Active Health Checks

HAProxy on `gw` port 8081 checks `GET /health` every two seconds and removes a server after two failures:

```bash
sudo cat /etc/haproxy/haproxy.cfg | sed -n '/^backend/,$p'
sudo haproxy -c -f /etc/haproxy/haproxy.cfg; echo "rc=$?"
echo "show stat" | sudo socat stdio /var/lib/haproxy/stats | cut -d, -f1,2,18,37 | column -t -s,
sudo journalctl -u haproxy --no-pager -o cat | grep -i 'is DOWN' | tail -1
```

Output:

```text
backend shop_api
    balance     roundrobin
    option      httpchk GET /health
    http-check  expect status 200
    server      web    172.16.1.3:8080 check inter 2s fall 2 rise 2
    server      client 172.16.0.2:8080 check inter 2s fall 2 rise 2
rc=0
# pxname  svname    status  check_status
shop      FRONTEND  OPEN    
shop_api  web       UP      L7OK
shop_api  client    DOWN    L4CON
shop_api  BACKEND   UP      
[WARNING]  (5204) : Server shop_api/client is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
```

`L4CON` means the TCP connection failed, `L7OK` a passing HTTP check. After `client` started nginx again, HAProxy marked it up and requests alternated strictly, because HAProxy runs one process:

```bash
for i in 1 2 3 4; do curl -s http://172.16.0.3:8081/; done
echo "set server shop_api/client state drain" | sudo socat stdio /var/lib/haproxy/stats
```

Output:

```text
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=172.16.0.2
shop-api on client (172.16.0.2:8080) client=172.16.0.3 xff=172.16.0.2
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=172.16.0.2
shop-api on client (172.16.0.2:8080) client=172.16.0.3 xff=172.16.0.2

```

`drain` stops new sessions to a server while existing ones finish, which is how a backend leaves the pool before maintenance; `state ready` returns it.

---

## Common Errors

### `connect() failed (111: Connection refused) while connecting to upstream`

**Cause:** nothing listens on the backend address and port.

**Fix:** check the backend service and its bind address; `nc -vz <backend> <port>` from the proxy.

### `no live upstreams while connecting to upstream`

**Cause:** every server in the `upstream` block is marked failed.

**Fix:** fix the backends; nginx retries them after `fail_timeout`.

### `Server shop_api/client is DOWN, reason: Layer4 connection problem`

**Cause:** HAProxy's health check cannot connect to the server.

**Fix:** as above; for `Layer7 wrong status`, check the health endpoint's response code.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a 502 and a 504 from a reverse proxy?"
    **Say first:** `502` means the proxy got no valid response (refused, reset, crashed backend); `504` means the backend did not answer in time.

    **Proof:** the nginx error log shows `connect() failed` for a 502 and `upstream timed out` for a 504.

    **Follow-up:** Which timeout setting controls the 504?

??? question "L1: Why does the backend log show the proxy's IP instead of the client's?"
    **Say first:** the proxy opens its own connection to the backend; the client address travels in `X-Forwarded-For`.

    **Proof:** the backend response shows `client=172.16.1.2 xff=172.16.0.2`.

    **Follow-up:** Why must the application not trust that header from everyone?
<!-- --8<-- [end:l1] -->

??? question "L2: Put two backends behind nginx and prove both receive traffic."
    **Say first:** an `upstream` block with both servers, `proxy_pass` to it, and a log format with `$upstream_addr`.

    **Proof:** `sudo nginx -t && sudo systemctl reload nginx`; repeated `curl`; `tail /var/log/nginx/shop-proxy.log`.

    **Follow-up:** How do you make a user stick to one backend?

??? question "L2: Take one HAProxy backend out of rotation without dropping its current users."
    **Say first:** set it to `drain` through the runtime API.

    **Proof:** `echo "set server shop_api/client state drain" | sudo socat stdio /var/lib/haproxy/stats`.

    **Follow-up:** How is this done in nginx open source? (Mark it `down` and reload.)

??? question "L3: Users get intermittent 502 errors from nginx on RHEL, but curl to the backend from the proxy works. What do you check?"
    **Say first:** the error log for the exact reason and backend, backend capacity, keepalive mismatches and SELinux.

    **Proof:** `sudo tail /var/log/nginx/error.log`; `$upstream_status` in the access log; `ausearch -m avc -c nginx`; `getsebool httpd_can_network_connect`.

    **Follow-up:** Why can `curl` from a shell succeed while nginx is denied?

??? question "L3: After a deployment, one of three backends returns errors but the load balancer keeps sending traffic to it. Why, and how do you fix it?"
    **Say first:** the health check does not test what fails (it checks the port or a static path), so the server still counts as healthy.

    **Proof:** `show stat` shows `L7OK` while requests fail; compare the health path with the failing path.

    **Follow-up:** What should a good health endpoint check, and what should it avoid?

---

## Related

- [nginx](../../../servers/nginx/nginx.md): nginx installation and configuration notes
- [Connectivity Testing](connectivity-testing.md): `curl --resolve` and timings
- [Ports and Sockets](ports-and-sockets.md): backend bind addresses

Captured on Rocky Linux 10.2 (nginx 1.26.3, HAProxy 3.0.5) and Ubuntu 24.04.4 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
