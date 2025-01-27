https://nginx.org/en/linux_packages.html

Ubuntu
Install the prerequisites:

sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring

Import an official nginx signing key so apt could verify the packages authenticity. Fetch the key:

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
Verify that the downloaded file contains the proper key:

gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
The output should contain the full fingerprint 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 as follows:

pub   rsa2048 2011-08-19 [SC] [expires: 2027-05-24]
      573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
uid                      nginx signing key <signing-key@nginx.com>
Note that the output can contain other keys used to sign the packages.

To set up the apt repository for stable nginx packages, run the following command:

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

To install nginx, run the following commands:

sudo apt update
sudo apt install nginx -y

1. Install Nginx:
sudo apt install nginx -y
sudo mkdir -p /var/www/html/.well-known/acme-challenge/
echo "test" | sudo tee /var/www/html/.well-known/acme-challenge/test-file
2. Create Nginx configuration for SonarQube:
sudo vi /etc/nginx/sites-available/adityatesting.in
Add:
server {
listen 80;
server_name adityatesting.in www.adityatesting.in;
# Handle the Let's Encrypt ACME Challenge
location /.well-known/acme-challenge/ {
root /var/www/html;
try_files $uri =404;
}
# Proxy pass all other requests to SonarQube
location / {
proxy_pass http://127.0.0.1:9000; # Your SonarQube application
proxy_set_header Host $host;proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_redirect off;
}
}
Enable the new configuration:
sudo ln -s /etc/nginx/sites-available/adityatesting.in /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
Step 8: Configure HTTPS
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d adityatesting.in
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d adityatesting.in -d www.adityatesting.in
