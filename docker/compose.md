https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04 
https://docs.docker.com/compose/ 		https://github.com/docker/compose

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; sudo chmod +x /usr/local/bin/docker-compose 
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose; docker-compose --version
# if ln -s isn’t created;	/usr/local/bin/docker-compose --version
https://docs.docker.com/reference/compose-file/legacy-versions/ 
up -d; ps -a; down;

