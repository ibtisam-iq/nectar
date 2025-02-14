ubuntu@ip-172-31-89-29:~$ sudo apt update                                                                      

ubuntu@ip-172-31-89-29:~$ sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring

ubuntu@ip-172-31-89-29:~$ curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11809  100 11809    0     0  31627      0 --:--:-- --:--:-- --:--:-- 31744

ubuntu@ip-172-31-89-29:~$ gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
pub   rsa4096 2024-05-29 [SC]
      8540A6F18833A80E9C1653A42FD21310B49F6B46
uid                      nginx signing key <signing-key-2@nginx.com>

pub   rsa2048 2011-08-19 [SC] [expires: 2027-05-24]
      573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
uid                      nginx signing key <signing-key@nginx.com>

pub   rsa4096 2024-05-29 [SC]
      9E9BE90EACBCDE69FE9B204CBCDCD8A38D88A2B3
uid                      nginx signing key <signing-key-3@nginx.com>

ubuntu@ip-172-31-89-29:~$ echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu noble nginx

ubuntu@ip-172-31-89-29:~$ sudo apt update

ubuntu@ip-172-31-89-29:~$ sudo apt install nginx -y

ubuntu@ip-172-31-89-29:~$ systemctl nginx status

Unknown command verb 'nginx', did you mean 'link'?
ubuntu@ip-172-31-89-29:~$ systemctl status nginx
○ nginx.service - nginx - high performance web server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: inactive (dead)
       Docs: https://nginx.org/en/docs/

ubuntu@ip-172-31-89-29:~$ vi /etc/nginx/sites-available/ibtisam-iq.com
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/sites-available/ibtisam-iq.com
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/sites-available/ibtisam-iq.com
ubuntu@ip-172-31-89-29:~$ ls -l /etc/nginx/sites-available/
ls: cannot access '/etc/nginx/sites-available/': No such file or directory
ubuntu@ip-172-31-89-29:~$ sudo ls -l /etc/nginx/sites-available/
ls: cannot access '/etc/nginx/sites-available/': No such file or directory
ubuntu@ip-172-31-89-29:~$ sudo touch /etc/nginx/sites-available/ibtisam-iq.com
touch: cannot touch '/etc/nginx/sites-available/ibtisam-iq.com': No such file or directory

ubuntu@ip-172-31-89-29:~$ sudo ls /etc/nginx
conf.d	fastcgi_params	mime.types  modules  nginx.conf  scgi_params  uwsgi_params
ubuntu@ip-172-31-89-29:~$ sudo cd /etc/nginx
sudo: cd: command not found
sudo: "cd" is a shell built-in command, it cannot be run directly.
sudo: the -s option may be used to run a privileged shell.
sudo: the -D option may be used to run a command in a specific directory.
ubuntu@ip-172-31-89-29:~$ sudo cd -s /etc/nginx
sudo: cd: command not found
sudo: "cd" is a shell built-in command, it cannot be run directly.
sudo: the -s option may be used to run a privileged shell.
sudo: the -D option may be used to run a command in a specific directory.
ubuntu@ip-172-31-89-29:~$ sudo cd -D /etc/nginx
sudo: cd: command not found
sudo: "cd" is a shell built-in command, it cannot be run directly.
sudo: the -s option may be used to run a privileged shell.
sudo: the -D option may be used to run a command in a specific directory.
ubuntu@ip-172-31-89-29:~$ su -
Password: 
ubuntu@ip-172-31-89-29:~$ sudo ls /etc/nginx/conf.d/
default.conf

ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf

ubuntu@ip-172-31-89-29:~$ sudo nginx -t
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx: configuration file /etc/nginx/nginx.conf test failed

ubuntu@ip-172-31-89-29:~$ sudo nginx -t
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx: configuration file /etc/nginx/nginx.conf test failed

ubuntu@ip-172-31-89-29:~$ sudo apt install -y certbot python3-certbot-nginx

ubuntu@ip-172-31-89-29:~$ sudo certbot --nginx -d ibtisam-iq.com -d www.ibtisam-iq.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Error while running nginx -c /etc/nginx/nginx.conf -t.
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx: configuration file /etc/nginx/nginx.conf test failed
The nginx plugin is not working; there may be problems with your existing configuration.
The error was: MisconfigurationError('Error while running nginx -c /etc/nginx/nginx.conf -t.\n\nnginx: [emerg] cannot load certificate "/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem, r) error:10000080:BIO routines::no such file)\nnginx: configuration file /etc/nginx/nginx.conf test failed\n')

ubuntu@ip-172-31-89-29:~$ sudo systemctl stop nginx

ubuntu@ip-172-31-89-29:~$ sudo certbot certonly --standalone -d ibtisam-iq.com -d www.ibtisam-iq.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Enter email address (used for urgent renewal and security notices)
 (Enter 'c' to cancel): test@gmail.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.4-April-3-2024.pdf. You must agree in
order to register with the ACME server. Do you agree?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing, once your first certificate is successfully issued, to
share your email address with the Electronic Frontier Foundation, a founding
partner of the Let's Encrypt project and the non-profit organization that
develops Certbot? We'd like to send you email about our work encrypting the web,
EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y
Account registered.
Requesting a certificate for ibtisam-iq.com and www.ibtisam-iq.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/ibtisam-iq.com/privkey.pem
This certificate expires on 2025-05-15.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ubuntu@ip-172-31-89-29:~$ sudo ls /etc/letsencrypt/live/ibtisam-iq.com
README	cert.pem  chain.pem  fullchain.pem  privkey.pem

ubuntu@ip-172-31-89-29:~$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

ubuntu@ip-172-31-89-29:~$ sudo systemctl start nginx


ubuntu@ip-172-31-89-29:~$ echo "# Redirect all HTTP traffic to HTTPS
server {
    listen 80;
    server_name ibtisam-iq.com www.ibtisam-iq.com;
    # You don’t need to explicitly define location / in the HTTP-to-HTTPS redirect block
    # because the entire request, regardless of path, will be redirected to https://$host$request_uri
    return 301 https://$host$request_uri;

  # Handle Let's Encrypt ACME Challenge (for SSL certificate issuance)

  # location /.well-known/acme-challenge/ {
  #     root /var/www/html;
  #     try_files $uri =404;
  # }

  # Instead, use the --standalone option to tell Certbot to handle the challenge using its own built-in web server.
}

server {
    listen 443 ssl;
    server_name ibtisam-iq.com www.ibtisam-iq.com;
    # WebsiteBuilder Site

    ssl_certificate /etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ibtisam-iq.com/privkey.pem;

    location / {
        proxy_pass http://172.31.91.166:8080; # Update with your application’s port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
"
# Redirect all HTTP traffic to HTTPS
server {
    listen 80;
    server_name ibtisam-iq.com www.ibtisam-iq.com;
    # You don’t need to explicitly define location / in the HTTP-to-HTTPS redirect block
    # because the entire request, regardless of path, will be redirected to https://
    return 301 https://;

  # Handle Let's Encrypt ACME Challenge (for SSL certificate issuance)

  # location /.well-known/acme-challenge/ {
  #     root /var/www/html;
  #     try_files  =404;
  # }

  # Instead, use the --standalone option to tell Certbot to handle the challenge using its own built-in web server.
}

server {
    listen 443 ssl;
    server_name ibtisam-iq.com www.ibtisam-iq.com;
    # WebsiteBuilder Site

    ssl_certificate /etc/letsencrypt/live/ibtisam-iq.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ibtisam-iq.com/privkey.pem;

    location / {
        proxy_pass http://172.31.91.166:8080; # Update with your application’s port
        proxy_set_header Host ;
        proxy_set_header X-Real-IP ;
        proxy_set_header X-Forwarded-For ;
        proxy_set_header X-Forwarded-Proto ;
    }
}

ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ systemctl reload nginx
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
Authentication is required to reload 'nginx.service'.
Authenticating as: Ubuntu (ubuntu)
Password: 
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf
ubuntu@ip-172-31-89-29:~$ sudo systemctl reload nginx
ubuntu@ip-172-31-89-29:~$ 
Broadcast message from root@ip-172-31-89-29 (Fri 2025-02-14 13:23:09 UTC):

The system will power off now!

Connection to ec2-52-91-255-235.compute-1.amazonaws.com closed by remote host.
Connection to ec2-52-91-255-235.compute-1.amazonaws.com closed.
ibtisam@mint-dell:~$ 


















ibtisam@mint-dell:/media/ibtisam/L-Mint/git/SilverOps/DevOps/DevOps-Tools/docker$ nslookup -type=NS ibtisam-iq.com
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
ibtisam-iq.com	nameserver = ns22.domaincontrol.com.
ibtisam-iq.com	nameserver = ns21.domaincontrol.com.

Authoritative answers can be found from:

ibtisam@mint-dell:/media/ibtisam/L-Mint/git/SilverOps/DevOps/DevOps-Tools/docker$ hostname -I | awk '{print $1}'
192.168.1.9

ibtisam@mint-dell:/media/ibtisam/L-Mint/git/SilverOps/DevOps/DevOps-Tools/docker$ nslookup ibtisam-iq.com
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	ibtisam-iq.com
Address: 52.91.255.235




