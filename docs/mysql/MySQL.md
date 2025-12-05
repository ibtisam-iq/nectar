# MySQL Setup and Usage Guide

This document provides comprehensive instructions for setting up and using MySQL, both locally and with Docker. It includes commands for installation, starting the MySQL service, accessing the MySQL shell, and managing databases and users. Additionally, it covers how to set up MySQL using Docker and Docker Compose.

## Table of Contents

1. [Introduction](#introduction)
2. [Local Setup](#local-setup)
    - [Installing MySQL](#installing-mysql)
    - [Configuring MySQL](#configuring-mysql)
    - [Managing Databases and Users](#managing-databases-and-users)
3. [MySQL with Docker](#mysql-with-docker)
4. [MySQL with Docker Compose](#mysql-with-docker-compose)
5. [Direct Interaction with Database](#direct-interaction-with-database)
6. [ORMs and Automatic Schema Creation](#orms-and-automatic-schema-creation)
7. [MySQL Configuration File](#mysql-configuration-file)
8. [How to Access MySQL](#how-to-access-mysql)

---

## Introduction

MySQL is a widely-used open-source relational database management system. This guide will help you set up MySQL on your local machine, as well as using Docker and Docker Compose for containerized environments. It also includes basic commands to interact with MySQL databases and users.

---

## Local Setup

### Installing MySQL

```bash
# Update the system's package list and install MySQL server
sudo apt update; sudo apt install mysql-server

# Access the MySQL shell as the root user
sudo mysql -u root
```

### Configuring MySQL

```bash
# Set the password for the root user and use the native MySQL authentication method
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'IbtisamX';

# Refresh MySQL privileges to ensure the changes take effect
FLUSH PRIVILEGES;

# Exit the MySQL shell
exit

# Log in to MySQL as root using the new password
mysql -u root -p
```

### Managing Databases and Users

```bash
# Create a new database for the application
CREATE DATABASE bankappdb;

# Verify the database has been created
show databases;

# Switch to the newly created database
USE bankappdb;

# Display all tables in the current database (will be empty initially)
show tables;

# Query the `account` table (if it exists in the schema)
select * from account;

# Query the `transaction` table (if it exists in the schema)
select * from transaction;

# Check the available users and hosts
SELECT user, host FROM mysql.user;

# Create a new MySQL user with a specific username and password # Use '%' for any host.
CREATE USER 'ibtisam'@'%' IDENTIFIED BY 'ib.ti.sam';

# Grant the new user full privileges on all databases and tables
GRANT ALL PRIVILEGES ON *.* TO 'ibtisam'@'%';

# Refresh privileges to apply the changes
FLUSH PRIVILEGES;

# Exit the MySQL shell
exit

# Allow remote connections by editing the MySQL configuration file
vi /etc/mysql/mysql.conf.d/mysqld.cnf

# In the configuration file, find the `bind-address` directive and change it to:
# bind-address = 0.0.0.0

# Restart the MySQL service to apply the configuration changes
sudo systemctl restart mysql

# Verify that MySQL is listening for connections on port 3306
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
---
