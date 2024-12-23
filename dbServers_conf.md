# MySQL

## Local Setup
```bash
sudo apt update; sudo apt install mysql-server
sudo mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'IbtisamOps';
FLUSH PRIVILEGES;
exit

mysql -u root -p
CREATE DATABASE bankappdb;
show databases;
USE bankappdb;

show tables;
select * from account;
select * from transaction;

# Create a new user

CREATE USER 'ibtisam'@'%' IDENTIFIED BY 'ib.ti.sam';
GRANT ALL PRIVILEGES ON *.* TO 'ibtisam'@'%';
FLUSH PRIVILEGES;
exit

# Grant remote access

vi /etc/mysql/mysql.conf.d/mysqld.cnf
bind-address = 0.0.0.0
sudo systemctl restart mysql
sudo netstat -tuln | grep 3306
```
## MySQL with Docker
```bash
docker run -d \
    --name some-mysql \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \   # username = root                     # mandatory
    -e MYSQL_USER=custom_user \             # Optional: Custom username           # optional
    -e MYSQL_PASSWORD=custom_password \     # Optional: Password for custom user  # mandatory, if custom_user is set
    -e MYSQL_DATABASE=bankappdb \           # MySQL database name                 # optional
    mysql:tag
```
- In MySQL, the root user is the default superuser account. 
- This environment variable (`MYSQL_ROOT_PASSWORD`) is used to set the password for that `root` account. 
- If you don't specify `MYSQL_USER` and `MYSQL_PASSWORD`, only the `root` user will be available.
- The specified `MYSQL_USER` will have full access to the `MYSQL_DATABASE` if it's created.
- Unlike PostgreSQL, where `POSTGRES_USER` defaults to `postgres`, MySQL does not have a default non-root user. You must explicitly set `MYSQL_USER` if you want an additional user apart from `root`.

```bash
docker exec -it some-mysql mysql -uroot -pmy-secret-pw
```

- The `mysql -uroot -pmy-secret-pw` part of the command specifies that the MySQL client should connect to the MySQL server using the root user and the password `my-secret-pw`.

```bash
docker exec -it some-mysql bash
```
- This command also uses `docker exec` to open an interactive terminal session inside the `some-mysql` container, but instead of running the MySQL client, it starts a Bash shell. This allows the user to execute shell commands directly within the container.

## MySQL with Docker Compose

```bash
# Use root/my-secret-pw as user/password credentials
version: '3.1'

services:

  db:
    image: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: my-secret-pw
    # (this is just an example, not intended to be a production configuration)
```

### Direct Interaction with Database:
- If a project uses a library (e.g., mysql, mysql2 in JavaScript or JDBC in Java, SQLAlchemy in Python, etc.) to connect to the database, it may rely on pre-existing tables and schema.
- In such cases, you need to manually create the required tables, schema, or run a setup script to ensure the database structure matches the application's expectations.

### ORMs and Automatic Schema Creation:

- Some projects use Object-Relational Mapping (ORM) tools like Sequelize (JavaScript), Hibernate (Java), or Django ORM (Python). These tools can often automatically create tables and schema during initialization based on the application's data models. However, this behavior depends on how the project is configured.

### MySQL configuration file

The default configuration for MySQL can be found in `/etc/mysql/my.cnf`, which may `!includedir` additional directories such as **`/etc/mysql/conf.d`** or `/etc/mysql/mysql.conf.d`.

### How to access?

1. `mysql://localhost:3306/database_name`
- Ensure that the firewall allows incoming traffic on port 3306.

```bash
sudo ufw allow 3306
```

2.  `https://www.phpmyadminonline.com/`

# PostgreSQL
## Local SetUp
```bash
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -i -u postgres
```
```sql
-- Create a new user named 'root' with the password 'root'
CREATE USER root WITH PASSWORD 'root';

-- Create a new database named 'my_database'
CREATE DATABASE my_database;

-- Grant all privileges on 'my_database' to the 'root' user
GRANT ALL PRIVILEGES ON DATABASE my_database TO root;

-- Switch to the new database
\c my_database 

-- Grant all privileges on the public schema to the 'root' user
GRANT ALL PRIVILEGES ON SCHEMA public TO root;

-- Allow the 'root' user to create objects in 'my_database'
GRANT CREATE ON DATABASE my_database TO root;
```
# PostgresSQL with Docker

```bash
docker run -d \
	--name some-postgres \
  -e POSTGRES_USER=postgres \                 # optional # Default = postgres
	-e POSTGRES_PASSWORD=mysecretpassword \     # mandatory
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v /custom/mount:/var/lib/postgresql/data \
	postgres
```

- **POSTGRES_PASSWORD**

This environment variable is required for you to use the PostgreSQL image. It must not be empty or undefined. This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the `POSTGRES_USER` environment variable.

- **POSTGRES_USER**

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.

# PostgresSQL with Docker Compose

```bash
# Use postgres/example user/password credentials
version: '3.9'

services:

  db:
    image: postgres
    restart: always
    # set shared memory limit when using docker-compose
    shm_size: 128mb
    # or set shared memory limit when deploy via swarm stack
    #volumes:
    #  - type: tmpfs
    #    target: /dev/shm
    #    tmpfs:
    #      size: 134217728 # 128*2^20 bytes = 128Mb
    environment:
      POSTGRES_PASSWORD: example

  adminer:
    image: adminer
    restart: always
    ports:
      - 8080:8080
```