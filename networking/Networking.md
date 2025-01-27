# Networking Basics

## OSI & TCP/IP Models
Understanding the OSI and TCP/IP models is fundamental to networking. They provide a conceptual framework for how data flows across networks.

---

## IP Addressing

### Key Commands
- `sudo netstat -tulnp`: Displays all listening ports and their associated services.
- The port number is where the service is actively listening for incoming connections on the specified IP address.

### Address Types
1. **Loopback Interface**
   - **127.0.0.1**: Service accessible only from the local machine; IPv4
   - **::1** (IPv6 equivalent): Accessible locally via IPv6.

2. **All Available Interfaces**
   - **0.0.0.0**: Service listening on all IPv4 interfaces.
   - **::** (IPv6): Service listening on all IPv6 interfaces.

3. **Examples**
   - **127.0.0.1:8597**: Service on port 8597, only accessible locally.
   - **127.0.0.1:631**: Port 631 (CUPS printing system), local access only.
   - **127.0.0.54:53**: Local DNS service port 53 (the standard DNS port)on a specific loopback address (127.0.0.54).
   - **::1:631**: IPv6 loopback, port 631. Accessible only from the local machine but over IPv6.
   - **:::22 & :::80**: SSH (22) and HTTP (80) accessible from all IPv6 interfaces (:: for IPv6).

---

### IP Address Classifications
1. **Private IP Addresses**
   - Used within private networks like a home or office (not routable on the internet).
   - In a home network, your router assigns private IPs like 192.168.1.10 to your computer, 192.168.1.11 to your printer, etc. These addresses are only valid within your home network
   - Example ranges:
     - `10.0.0.0 - 10.255.255.255`
     - `172.16.0.0 - 172.31.255.255`
     - `192.168.0.0 - 192.168.255.255`
   - Commands: `ip a` or `ifconfig`

2. **Public IP Addresses**
   - Routable on the internet; assigned by ISPs.
   - Your home router has a public IP address assigned by your ISP, such as 203.0.113.5. This IP address is used to communicate with websites and other services on the internet. When you access a website, the request is sent from this public IP address.
   - Example: `203.0.113.5`
   - Commands: 
     - `curl ifconfig.me`
     - `curl -s https://api.ipify.org`

3. **Local IP Addresses**
   - Loopback or private IPs used within a single machine or network.
   - Examples: `127.0.0.1`, `localhost`
   - Commands: `ping 127.0.0.1` or `ping localhost`

---

### How They Work Together
- Devices in a local network use **private IP addresses** to communicate internally.
- When accessing the internet, **public IP addresses** are used via **Network Address Translation (NAT)** by the router.
- The router uses Network Address Translation (NAT) to map private IPs to its public IP address, enabling devices on your local network to communicate with the outside world.


---

## Servers, Protocols, and Ports

### How Services Work
- Servers/services communicate using specific protocols (e.g., HTTP, FTP) and listen on associated ports.
- When the server starts, it opens a network port to communicate with other clients or systems. 
- **Application Layer** protocols typically run on this layer, and define the ports.

---

### Protocols by TCP/IP Model Layer
1. **Network Interface Layer**
   - Examples: Ethernet, ARP
2. **Internet Layer**
   - Examples: IP, ICMP
3. **Transport Layer**
   - Examples: TCP, UDP
4. **Application Layer**
   - Examples: 
     - Web: HTTP, HTTPS, HTTP/2, HTTP/3
     - File Transfer: FTP, SFTP, FTPS
     - Email: SMTP, IMAP, POP3
     - Management: DNS, DHCP, NTP, SNMP
     - Remote Access: SSH, Telnet, RDP, VNC
     - Databases: MySQL, PostgreSQL, SQLite
     - Directories: LDAP
     - File Sharing: SMB/CIFS

---

### Protocols by Functionality
1. **Web & HTTP**
   - HTTP, HTTPS, HTTP/2, HTTP/3
2. **File Transfer**
   - FTP, FTPS, SFTP
3. **Email**
   - SMTP, IMAP, POP3
4. **Network Management & Synchronization**
   - DNS, DHCP, NTP, SNMP
5. **Remote Access**
   - SSH, SFTP, Telnet, RDP, VNC
6. **Database Communication**
   - MySQL, PostgreSQL, SQLite
7. **Directory Services**
   - LDAP
8. **File Sharing**
   - SMB/CIFS

# System and Network Commands

## General Commands
- **List active services**:  
  `systemctl list-units --type=service --state=running`

- **Open ports and services (active internet connections, servers only)**:  
  `sudo netstat -tulnp`

- **List open files and listening ports**:  
  `sudo lsof -i -P -n | grep LISTEN`

- **Check open ports and listening services**:  
  `sudo ss -tulnp | grep -i ssh`

- **List running processes for a specific service**:  
  `ps aux | grep <service>`

---

## Commands to Check Listening Ports

| Service     | Command/Configuration File                                        |
|-------------|-------------------------------------------------------------------|
| **Apache2** | `cat /etc/apache2/ports.conf`                                     |
| **Nginx**   | `grep -i "listen" /etc/nginx/nginx.conf /etc/nginx/sites-available/default` |
| **Jenkins** | Check the `config.xml` file in the Jenkins home directory or use the port specified in the startup command. |
| **Tomcat**  | `grep "Connector port" /path/to/tomcat/conf/server.xml`           |
| **Node.js** | Port is typically defined in the application code (e.g., `app.listen(3000)`). |
| **MySQL**   | `cat /etc/mysql/my.cnf | grep port`                               |

---

## Default Ports for Common Services

| Web Server | Configuration File/Command                                        | Default Ports |
|------------|-------------------------------------------------------------------|---------------|
| **Apache2** | `/etc/apache2/ports.conf`                                        | 80, 443       |
| **Nginx**   | `/etc/nginx/nginx.conf` or `/etc/nginx/sites-available/default`   | 80, 443       |
| **Jenkins** | `--httpPort` option in startup command or `config.xml`           | 8080          |
| **Tomcat**  | `/conf/server.xml`                                               | 8080, 8443    |
| **Node.js** | Defined in the application code                                  | User-defined (e.g., 3000) |
| **Docker**  | Use `-p` option in `docker run` command                          | User-defined  |
| **MySQL**   | `/etc/mysql/my.cnf`                                              | 3306          |
| **PostgreSQL** | `/etc/postgresql/common/postgresql.conf`                        | 5432 |
| **Redis**   | `redis.conf`                                                    | 6379          |
| **MongoDB** | `mongod.conf`                                                    | 27017         |
| **SMB/CIFS** | `/etc/samba/smb.conf`                                             | 139 , 445      |
| **FTP**     | `/etc/pure-ftpd.conf`                                              | 21            |
| **SSH**     | `/etc/ssh/sshd_config`                                             | 22            |
| **HTTP**    | `/etc/httpd/conf/httpd.conf`                                       | 80 |
| **HTTPS**   | `/etc/httpd/conf/httpd.conf`                                       | 443 |
| **IMAP**    | `/etc/imapd.conf`                                                  | 143           |
| **POP3**    | `/etc/pop3d.conf`                                                   | 110           |
| **SMTP**    | `/etc/sendmail.cf`                                                  | 25            |
| **DNS**     | `/etc/bind/named.conf`                                             | 53            |
| **RDP**     | `/etc/xrdp/xrdp.conf`                                               | 3389          |
| **Telnet**  | `/etc/telnetd.conf`                                                | 23 |
| **SNMP**    | `/etc/snmp/snmpd.conf`                                              | 161 |


## VPC
This 
## Terminology
Load balancer, reverse proxy, DNS

# Common Server and Service Ports

---

## Web Servers
| Serial No. | Server/Service | Protocol | Port | Connection URL Format         |
|------------|----------------|----------|------|--------------------------------|
| 1          | Apache2        | HTTP     | 80   | http://localhost:80           |
| 2          | Nginx          | HTTP     | 80   | http://localhost:80           |
| 3          | Lighttpd       | HTTP     | 80   | http://localhost:80           |
| 4          | Cherokee       | HTTP     | 80   | http://localhost:80           |
| 5          | Caddy          | HTTP     | 80   | http://localhost:80           |
| 6          | Tomcat         | HTTP     | 8080 | http://localhost:8080         |
| 7          | OpenResty      | HTTP     | 80   | http://localhost:80           |

---

## Databases
| Serial No. | Server/Service | Protocol    | Port  | Connection URL Format          |
|------------|----------------|-------------|-------|---------------------------------|
| 8          | MySQL          | MySQL       | 3306  | mysql://localhost:3306         |
| 9          | PostgreSQL     | PostgreSQL  | 5432  | postgresql://localhost:5432    |
| 10         | MongoDB        | MongoDB     | 27017 | mongodb://localhost:27017      |
| 11         | Redis          | Redis       | 6379  | redis://localhost:6379         |
| 12         | MariaDB        | MySQL       | 3306  | mariadb://localhost:3306       |
| 13         | SQLite         | SQLite      | -     | File-based                     |
| 14         | CockroachDB    | PostgreSQL  | 26257 | postgresql://localhost:26257   |
| 15         | Amazon RDS     | Varies      | Varies| Depends on RDS engine          |

---

## File & Storage Servers
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 16         | Samba          | SMB/CIFS   | 445   | smb://localhost                |
| 17         | NFS            | NFS        | 2049  | nfs://localhost                |
| 18         | FTP            | FTP        | 21    | ftp://localhost:21             |
| 19         | SFTP           | SFTP       | 22    | sftp://localhost:22            |
| 20         | Nextcloud            | HTTP        | 80  | http://localhost/nextcloud                |
| 21         | ownCloud            | HTTP        | 80    | http://localhost/owncloud             |
| 22         | Ceph           | RADOS       | 6789    | rados://localhost:6789            |
---

## Security & Identity Services
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 23         | OpenLDAP       | LDAP       | 389   | ldap://localhost:389           |
| 24         | FreeIPA        | HTTP       | 80    | http://localhost               |
| 25         | Keycloak       | HTTP       | 8080  | http://localhost:8080/auth     |
| 26         | CAS            | HTTP       | 8080  | http://localhost:8080/cas      |
| 27         | Shibboleth     | HTTPS      | 443   | https://localhost/shibboleth   |
| 28         | Vault          | HTTP       | 8200  | http://localhost:8200          |
| 29         | Suricata       | HTTP     | 3000  | http://localhost:3000         |
| 30         | Snort          | HTTP     | 80    | http://localhost/snort        |
| 31         | Fail2Ban       | HTTP     | 8080  | http://localhost:8080         |
| 32         | ClamAV         | HTTP     | 3310  | http://localhost:3310         |
| 33         | OSSEC          | HTTP     | 1514  | http://localhost:1514         |
| 34         | AIDE           | -        | -     | Log monitoring - no direct URL |
---

## Messaging & Collaboration
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 35         | Mosquitto      | MQTT       | 1883  | mqtt://localhost:1883          |
| 36         | Mattermost     | HTTP       | 8065  | http://localhost:8065          |
| 37         | Rocket.Chat    | HTTP       | 3000  | http://localhost:3000          |
| 38         | Jabberd        | XMPP       | 5222  | xmpp://localhost:5222          |
| 39         | ejabberd       | XMPP       | 5222  | xmpp://localhost:5222          |
| 40         | Zimbra         | HTTP       | 7071  | http://localhost:7071          |

---

## CI/CD, Development, & Build Tools
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 41         | Jenkins        | HTTP       | 8080  | http://localhost:8080          |
| 42         | GitLab CI/CD   | HTTP       | 80    | http://localhost/gitlab-ci     |
| 43         | Travis CI      | HTTP       | 80    | http://localhost/travis-ci     |
| 44         | CircleCI       | HTTP       | 80    | http://localhost/circleci      |
| 45         | Bamboo         | HTTP       | 8085  | http://localhost:8085          |

---

## Monitoring & Logging
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 46         | Grafana        | HTTP       | 3000  | http://localhost:3000          |
| 47         | Nagios         | HTTP       | 80    | http://localhost/nagios        |
| 48         | Prometheus     | HTTP       | 9090  | http://localhost:9090          |
| 49         | Zabbix         | HTTP       | 80    | http://localhost/zabbix        |
| 50         | Elasticsearch  | HTTP       | 9200  | http://localhost:9200          |
| 51         | Logstash       | HTTP       | 5044  | http://localhost:5044          |
| 52         | Kibana         | HTTP       | 5601  | http://localhost:5601          |
| 53         | Graylog        | HTTP       | 9000  | http://localhost:9000          |
| 54         | Fluentd        | HTTP       | 9880  | http://localhost:9880          |
| 55         | Splunk         | HTTP       | 8000  | http://localhost:8000          |

---

## Media Servers
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 56         | Plex           | HTTP       | 32400 | http://localhost:32400         |
| 57         | Jellyfin       | HTTP       | 8096  | http://localhost:8096          |
| 58         | Emby           | HTTP       | 8096  | http://localhost:8096          |
| 59         | Kodi           | HTTP       | 8080  | http://localhost:8080          |

---

## Networking & VPN
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 60         | OpenVPN        | UDP        | 1194  | openvpn://localhost:1194       |
| 61         | WireGuard      | UDP        | 51820 | wireguard://localhost:51820    |
| 62         | IPsec          | IPsec      | Varies| Requires configuration         |
| 63         | pfSense        | HTTP       | 443   | https://localhost              |
| 64         | OPNsense       | HTTP       | 443   | https://localhost              |
| 65         | Untangle       | HTTP       | 443   | https://localhost              |
| 66         | StrongSwan     | IPsec      | Varies| Requires configuration         |
| 67         | SoftEther      | VPN        | 443   | https://localhost              |
| 68         | RADIUS         | RADIUS     | 1812  | radius://localhost:1812        |

---

## Others
| Serial No. | Server/Service | Protocol   | Port  | Connection URL Format          |
|------------|----------------|------------|-------|---------------------------------|
| 69         | Docker         | HTTP       | 2375  | http://localhost:2375          |
| 70         | Kubernetes     | HTTPS      | 6443  | https://localhost:6443         |
| 71         | Terraform      | HTTP       | 8080  | http://localhost:8080          |
| 72         | Ansible        | SSH        | 22    | ssh://localhost                |
| 73         | Puppet         | HTTPS      | 8140  | https://localhost:8140         |
| 74         | Chef           | HTTPS      | 443   | https://localhost              |
| 75         | SaltStack      | HTTP       | 4505  | http://localhost:4505          |
### Monitoring & Logging
| Serial No. | Server/Service   | Protocol | Port  | Connection URL Format         |
|------------|------------------|----------|-------|--------------------------------|
| 76         | Grafana          | HTTP     | 3000  | http://localhost:3000         |
| 77         | Nagios           | HTTP     | 80    | http://localhost/nagios       |
| 78         | Prometheus       | HTTP     | 9090  | http://localhost:9090         |
| 79         | Zabbix           | HTTP     | 80    | http://localhost/zabbix       |
| 80         | Elasticsearch    | HTTP     | 9200  | http://localhost:9200         |
| 81         | Logstash         | HTTP     | 5044  | http://localhost:5044         |
| 82         | Kibana           | HTTP     | 5601  | http://localhost:5601         |
| 83         | Graylog          | HTTP     | 9000  | http://localhost:9000         |
| 84         | Fluentd          | HTTP     | 9880  | http://localhost:9880         |
| 85         | Splunk           | HTTP     | 8000  | http://localhost:8000         |

