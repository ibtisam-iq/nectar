# MySQL

## Local Setup
```bash
# Update the system's package list and install MySQL server
sudo apt update; sudo apt install mysql-server

# Access the MySQL shell as the root user
sudo mysql -u root

# Set the password for the root user and use the native MySQL authentication method
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'IbtisamOps';

# Refresh MySQL privileges to ensure the changes take effect
FLUSH PRIVILEGES;

# Exit the MySQL shell
exit

# Log in to MySQL as root using the new password
mysql -u root -p

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

# Create a new MySQL user with a specific username and password
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
# PostgreSQL
## Local SetUp
```bash
# Install PostgreSQL and its additional contributed packages
sudo apt-get install postgresql postgresql-contrib

# Start the PostgreSQL service
sudo systemctl start postgresql

# Enable the PostgreSQL service to start automatically on boot
sudo systemctl enable postgresql

# Switch to the default PostgreSQL user 'postgres' to perform administrative tasks
sudo -i -u postgres
# Access the PostgreSQL shell using the psql command to perform database operations
psql
```
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

# MariaDB

# MongoDB

## Local SetUp

```bash
# Download and add the GPG key for MongoDB 7.0
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor 

# Add the MongoDB repository to your system's package sources list
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update the system's package list and install MongoDB
sudo apt update; sudo apt install -y mongodb-org

# Enable MongoDB service to start automatically on system boot
sudo systemctl enable mongod

# Start the MongoDB service
sudo systemctl start mongod

# Follow the MongoDB Shell installation guide (ensure you visit the linked documentation)
# This step installs `mongosh`, the MongoDB shell, which is used to interact with the database
# Visit: https://www.mongodb.com/docs/mongodb-shell/install/

# Access the MongoDB shell to manage databases and collections
mongosh

# Show a list of all databases available in the MongoDB instance
show dbs;

# Switch to (or create) a specific database by its name
use db_name;

# Display all collections (similar to tables in relational databases) in the selected database
show collections;

# Query the `Products` collection in the current database and format the results for readability
db.Products.find().pretty();
```
## MongoDB with Docker

```bash
docker network create my-network

docker run -d \
--name mongodb \
--network my-network \
-e MONGO_INITDB_ROOT_USERNAME=admin \     # Sets the environment variable for MongoDB's `root` username.
-e MONGO_INITDB_ROOT_PASSWORD=password \  # Sets the environment variable forMongoDB's root password
-v mongo-data:/data/db \
mongo:latest

docker run -d \
--name mongo-express \
--network my-network \  # Connects the container to the my-network network (shared with the MongoDB container)
-e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \      # Sets MongoDB admin username (same as in MongoDB)
-e ME_CONFIG_MONGODB_ADMINPASSWORD=password \   # Sets MongoDB admin password (same as in MongoDB)
-e ME_CONFIG_MONGODB_SERVER=mongodb \   # Tells Mongo Express to connect to the MongoDB container by name (mongodb) 
-e ME_CONFIG_BASICAUTH_USERNAME=admin \     # Sets the basic auth username for the Mongo Express interface
-e ME_CONFIG_BASICAUTH_PASSWORD=pass123 \   # Sets the basic auth password for the Mongo Express interface
-p 8081:8081 \
mongo-express:latest
```

## MongoDB with Docker Compose

```bash
version: '3.8' # Define the Docker Compose file format version

services:
  mongodb:
    image: mongo:latest                     # Use the latest MongoDB image
    container_name: mongodb                 # Name of the MongoDB container
    environment:                            # Environment variables for MongoDB setup
      - MONGO_INITDB_ROOT_USERNAME=admin    # Set the root username for MongoDB
      - MONGO_INITDB_ROOT_PASSWORD=password # Set the root password for MongoDB
    volumes:
      - mongo-data:/data/db                 # Mount a volume to persist database data
    networks:
      - my-network                          # Attach MongoDB to the custom network
    restart: unless-stopped                 # Always restart the container unless it is explicitly stopped

  mongo-express:
    image: mongo-express:latest             # Use the latest Mongo Express image
    container_name: mongo-express           # Name of the Mongo Express container
    environment:                            # Environment variables for Mongo Express setup
      - ME_CONFIG_MONGODB_ADMINUSERNAME=admin       # Set the MongoDB admin username
      - ME_CONFIG_MONGODB_ADMINPASSWORD=password    # Set the MongoDB admin password
      - ME_CONFIG_MONGODB_SERVER=mongodb            # Tell Mongo Express to connect to the MongoDB container
      - ME_CONFIG_BASICAUTH_USERNAME=admin          # Set the web interface username
      - ME_CONFIG_BASICAUTH_PASSWORD=pass123        # Set the web interface password
    ports:
      - "8081:8081"                     # Map port 8081 on the host to port 8081 in the container
    networks:
      - my-network                      # Attach Mongo Express to the same custom network as MongoDB
    restart: unless-stopped             # Always restart the container unless it is explicitly stopped
    depends_on:                         # Ensure MongoDB starts before Mongo Express
      - mongodb

networks:
  my-network:                           # Define the custom network for inter-container communication

volumes:
  mongo-data:                           # Define the named volume for persisting MongoDB data
```