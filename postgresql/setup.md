# PostgreSQL Setup and Usage Guide

This document provides comprehensive instructions for setting up and using PostgreSQL, both locally and with Docker. It includes commands for installation, starting the PostgreSQL service, accessing the PostgreSQL shell, and managing databases and users. Additionally, it covers how to set up PostgreSQL using Docker and Docker Compose.

## Table of Contents

1. [Introduction](#introduction)
2. [Local Setup](#local-setup)
    - [Installing PostgreSQL](#installing-postgresql)
    - [Configuring PostgreSQL](#configuring-postgresql)
3. [PostgreSQL with Docker](#postgresql-with-docker)
4. [PostgreSQL with Docker Compose](#postgresql-with-docker-compose)
5. [Environment Variables](#environment-variables)

---

## Introduction

PostgreSQL is a powerful, open-source relational database management system. This guide will help you set up PostgreSQL on your local machine, as well as using Docker and Docker Compose for containerized environments. It also includes basic commands to interact with PostgreSQL databases and users.

---

## Local Setup

### Installing PostgreSQL

- [Official link](https://www.postgresql.org/download/)

```bash
# Import the repository signing key
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update the package lists
sudo apt update

# Install the latest version of PostgreSQL and its additional contributed packages

# If you want a specific version, use 'postgresql-16' or similar instead of 'postgresql'
sudo apt -y install postgresql postgresql-contrib

# Start the PostgreSQL service
sudo systemctl start postgresql

# Enable the PostgreSQL service to start automatically on boot
sudo systemctl enable postgresql

# Switch to the default PostgreSQL user 'postgres' to perform administrative tasks
sudo -i -u postgres

# Access the PostgreSQL shell using the psql command to perform database operations
psql
```

### Configuring PostgreSQL

```sql
-- Create a new user named 'root' with the password 'root'
CREATE USER root WITH PASSWORD 'root';

-- Create a new database named 'my_database'
CREATE DATABASE my_database;

-- Grant all privileges on 'my_database' to the 'root' user
GRANT ALL PRIVILEGES ON DATABASE my_database TO root;

-- Switch to the newly created database for further configuration
\c my_database 

-- Grant all privileges on the public schema to the 'root' user
GRANT ALL PRIVILEGES ON SCHEMA public TO root;

-- Allow the 'root' user to create objects in 'my_database'
GRANT CREATE ON DATABASE my_database TO root;
```

```bash
# Exit the PostgreSQL shell after completing database configuration
\q
# Exit the PostgreSQL administrative user session
exit
```

## PostgreSQL with Docker

- [Official link](https://hub.docker.com/_/postgres)

```bash
docker run -d \
	--name some-postgres \
  -e POSTGRES_USER=postgres \                 # optional # Default = postgres
	-e POSTGRES_PASSWORD=mysecretpassword \     # mandatory
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v /custom/mount:/var/lib/postgresql/data \
	postgres
```

## PostgreSQL with Docker Compose

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

## Environment Variables

- **POSTGRES_PASSWORD**

This environment variable is required for you to use the PostgreSQL image. It must not be empty or undefined. This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the `POSTGRES_USER` environment variable.

- **POSTGRES_USER**

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.
