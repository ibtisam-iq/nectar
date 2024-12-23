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

CREATE USER 'ibtisam'@'%' IDENTIFIED BY 'ib.ti.sam';
GRANT ALL PRIVILEGES ON *.* TO 'ibtisam'@'%';
FLUSH PRIVILEGES;
```
## MySQL with Docker
```bash
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag
```
- `MYSQL_ROOT_PASSWORD` is a mandatory variable and specifies the password that will be set for the MySQL `root` superuser account.
- `tag` is the version of MySQL to use. For example, `mysql:latest

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

### Using a custom MySQL configuration file

The default configuration for MySQL can be found in `/etc/mysql/my.cnf`, which may `!includedir` additional directories such as **`/etc/mysql/conf.d`** or `/etc/mysql/mysql.conf.d`.