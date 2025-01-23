# SonarQube Setup on Ubuntu 22.04

This guide provides detailed steps to install and configure SonarQube on Ubuntu 22.04, including the installation of PostgreSQL.


## Install Prerequisite

```bash
sudo apt update
sudo apt upgrade -y

# SonarQube requires Java 11 or 17
sudo apt install openjdk-17-jdk -y
java -version
```

## Install PostgreSQL

- SonarQube uses PostgreSQL as its database.
- Please follow the instructions below [here](https://github.com/ibtisamops/nectar/blob/main/postgresql/setup.md).

## Configure PostgreSQL

```bash
sudo -i -u postgres
createuser sonar
createdb sonar -O sonar
psql
ALTER USER sonar WITH ENCRYPTED PASSWORD 'your_password';
\q
exit
```

## Install SonarQube

1. Download SonarQube:

```bash
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.5.1.90531.zip
```

2. Extract and move SonarQube:

```bash
unzip sonarqube-10.5.1.90531.zip
sudo mv sonarqube-10.5.1.90531 /opt/sonarqube
```

3. Create a SonarQube user and change ownership:

```bash
sudo adduser --system --no-create-home --group --disabled-login sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube
```

4. Configure SonarQube:

Edit the SonarQube configuration file:

```bash
sudo vi /opt/sonarqube/conf/sonar.properties
```

Uncomment and set the following properties:

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=your_password
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
```

## Create a Systemd Service File

1. Create the service file for SonarQube:

```bash
sudo vi /etc/systemd/system/sonarqube.service
```

Add the following content:

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

2. Reload the systemd daemon and start SonarQube:

```bash
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube
```

## Configure System Limits

1. Check and increase file descriptors limit:

```bash
ulimit -n
sudo vi /etc/security/limits.conf
```

Add:

```conf
sonarqube - nofile 65536
sonarqube - nproc 4096
```

2. Set virtual memory limits:

```bash
sudo sysctl -w vm.max_map_count=262144

# To make the change persistent
sudo vi /etc/sysctl.conf
```

Add:

```conf
vm.max_map_count=262144
```

Apply changes:

```bash
sudo sysctl -p
