https://nginx.org/en/linux_packages.html

Ubuntu
```bash
# Install the prerequisites:
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# Import an official nginx signing key so apt could verify the packages authenticity. Fetch the key:

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Verify that the downloaded file contains the proper key:

gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

# To set up the apt repository for stable nginx packages, run the following command:

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

# To install nginx, run the following commands:

sudo apt update
sudo apt install nginx -y

```

1. Install Nginx:
2. Create Nginx configuration
sudo vi /etc/nginx/sites-available/ibtisam-iq.com
sudo vi /etc/nginx/conf.d/ibtisam-iq.com.conf

Enable the new configuration:
sudo ln -s /etc/nginx/sites-available/ibtisam-iq.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

Configure HTTPS
sudo apt install -y certbot python3-certbot-nginx
# sudo certbot --nginx -d ibtisam-iq.com -d www.ibtisam-iq.com
sudo certbot certonly --standalone -d ibtisam-iq.com -d www.ibtisam-iq.com
sudo ls /etc/letsencrypt/live/ibtisam-iq.com
sudo certbot renew --dry-run
sudo nginx -t
sudo systemctl reload nginx

