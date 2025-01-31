# MongoDB Setup and Usage Guide

This document provides comprehensive instructions for setting up and using MongoDB, both locally and with Docker. It includes commands for installation, starting the MongoDB service, accessing the MongoDB shell, and managing databases and collections. Additionally, it covers how to set up MongoDB using Docker and Docker Compose.

## Table of Contents

1. [Introduction](#introduction)
2. [Local Setup](#local-setup)
    - [Installing MongoDB](#installing-mongodb)
    - [MongoDB Shell Installation](#mongodb-shell-installation)
3. [MongoDB with Docker](#mongodb-with-docker)
4. [MongoDB with Docker Compose](#mongodb-with-docker-compose)
5. [Basic MongoDB Commands](#basic-mongodb-commands)

---

## Introduction

MongoDB is a popular NoSQL database known for its flexibility and scalability. This guide will help you set up MongoDB on your local machine, as well as using Docker and Docker Compose for containerized environments. It also includes basic commands to interact with MongoDB databases and collections.

---

## Local Setup

### Installing MongoDB

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
```

## MongoDB with Docker

```bash
docker network create my-network

docker run -d \
--name mongodb \
--network my-network \
-e MONGO_INITDB_ROOT_USERNAME=admin \     # Sets the environment variable for MongoDB's `root` username.
-e MONGO_INITDB_ROOT_PASSWORD=password \  # Sets the environment variable forMongoDB's root password
-v mongo-data:/data/db \                  # Creates a named volume 'mongo-data' inside host machine, mounts it to the container's directory /data/db
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
      - mongo-data:/data/db                 # Mount a Named volume to persist database data
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

## MongoDB Shell Installation

Follow the MongoDB Shell installation guide:

- This step installs `mongosh`, the MongoDB shell, which is used to interact with the database
- Visit: https://www.mongodb.com/docs/mongodb-shell/install/

## Basic MongoDB Commands

```bash
# Start the MongoDB service, if not
sudo systemctl start mongod

# Access the MongoDB shell to manage databases and collections
mongosh

# Show a list of all databases available in the MongoDB instance
show dbs;

# Switch to (or create) a specific database by its name
use db_name;

# Exit the MongoDB Shell
exit
Ctrl+D 

# Display all collections (similar to tables in relational databases) in the selected database
show collections;

# Query the `Products` collection in the current database and format the results for readability
db.Products.find().pretty();
```
