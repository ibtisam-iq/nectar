# Jenkins Setup and Configuration Guide

This guide provides comprehensive instructions for setting up and configuring Jenkins, including installation, configuration, and usage of various features.

## Table of Contents

1. [Setting up Jenkins](#setting-up-jenkins)
    - [Official Site](#official-site)
    - [Linux](#linux)
        - [Ubuntu](#ubuntu)
        - [RHEL](#rhel)
    - [Docker](#docker)
    - [WAR File](#war-file)
    - [Start Jenkins](#start-jenkins)
2. [Walkthrough Manage Jenkins UI](#walkthrough-manage-jenkins-ui)
    - [System](#system)
    - [Tools](#tools)
    - [Plugins](#plugins)
    - [Nodes](#nodes)
    - [Security](#security)
    - [Credentials](#credentials)
3. [Job Types](#job-types)
    - [Freestyle Project](#freestyle-project)
    - [Pipeline](#pipeline)
    - [Multibranch Pipeline](#multibranch-pipeline)
    - [Maven Project](#maven-project)
    - [Multi-Configuration Project](#multi-configuration-project)
4. [Jenkins CLI](#jenkins-cli)
5. [Important Key Concepts](#important-key-concepts)
    - [Parameters and Variables](#parameters-and-variables)
    - [Shared Libraries](#shared-libraries)
    - [User Access Management](#user-access-management)
    - [Webhook](#webhook)
    - [Upstream vs Downstream Jobs](#upstream-vs-downstream-jobs)
    - [Deployment via Tomcat](#deployment-via-tomcat)
    - [Backup](#backup)
    - [Email Configuration](#email-configuration)
    - [Troubleshooting](#troubleshooting)

---

## Setting up Jenkins

### Official Site

[Visit official site](https://www.jenkins.io/download/)

### Linux

#### Ubuntu

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt install openjdk-17-jre-headless
java -version
sudo apt-get install jenkins
```

If Jenkins fails to start because a port is in use, run `systemctl edit jenkins` and add the following:
```bash
[Service]
Environment="JENKINS_PORT=8081"
```
Here, "8081" was chosen but you can put another port available.

##### Firewall 
```bash
sudo ufw status; sudo ufw enable; sudo ufw allow 8080/tcp; sudo ufw status; sudo ufw reload
```
#### RHEL

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
sudo yum upgrade
sudo yum install java-17-openjdk
sudo yum install jenkins
```
##### Firewall
```bash
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp; sudo firewall-cmd --reload
```
### Docker

```bash
docker run jenkins/jenkins:lts-jdk17 -d -p 8080:8080
```

If you are running Jenkins in Docker using the official `jenkins/jenkins` image, you can use `sudo docker exec ${CONTAINER_ID or CONTAINER_NAME} cat /var/jenkins_home/secrets/initialAdminPassword` to print the password in the console without having to exec into the container.

### WAR File

Download the latest Jenkins WAR file.

Run the command:

```bash
java -jar jenkins.war
```

You can change the port by specifying the `--httpPort` option when you run the `java -jar jenkins.war` command. For example, to make Jenkins accessible through port 9090, then run Jenkins using the command:

```bash
java -jar jenkins.war --httpPort=9090
```

### Start Jenkins

```bash
sudo systemctl enable/start/status/stop/disable jenkins
```
---

## Walkthrough Manage Jenkins UI

The Manage Jenkins tab is for managing Jenkins itself. This includes managing plugins, managing the Jenkins instance, and managing the Jenkins configuration.

![](./images/Manage%20Jenkins.png)

### 1. System 

The System tab is for setting up global configurations that Jenkins and plugins (servers) require to operate at a higher level. These configurations typically deal with the overall functioning of Jenkins or its plugins.

### 2. Tools

The Tools tab focuses specifically on configuring the tools Jenkins uses, such as compilers, interpreters, build systems, or external utilities. These are specific to the runtime of the builds and can vary between jobs.

Examples:

- Configuring and managing multiple versions of the JDK, Maven, Gradle, or Node.js.
- Defining how Jenkins should install or locate these tools (e.g., manually provided, automatically installed).

When Jenkins installs tools automatically, it does not place them in system-wide directories (e.g., /usr/bin). Instead, it installs them in directories managed specifically by Jenkins. These directories are part of Jenkins' internal file structure and are isolated to avoid conflicts with system-installed tools.

#### Where Exactly It Is Installed

1. **Cache Directory**: Jenkins maintains a special directory, often called the tools cache, where it stores downloaded and installed tools. Default Locations: `~/.jenkins/tools` or `/var/lib/jenkins/tools`.

2. **Workspace Directory**: Tools may also be installed in job-specific workspace directories if configured that way. For example, for a job running in `/var/lib/jenkins/workspace/my-job`, the tool might be installed inside that workspace or referenced there temporarily.

3. **Tool-Specific Subdirectories**: Within the cache or workspace directory, Jenkins creates subdirectories for each tool and version, ensuring isolation. For example: `~/.jenkins/tools/hudson.tasks.Maven_MavenInstallation/Maven-3.8.5/` Here: `hudson.tasks.Maven_MavenInstallation`: Identifier for the tool type (Maven in this case). Maven-3.8.5: The version of Maven being installed.

## 3. Plugins

Plugins are essentially extensions to Jenkins that add new functionality. They can be installed from the Jenkins Plugin Manager. Here are the important plugins:

- Pipeline: Stage View
- SonarQube Scanner
- Eclipse Temurin installer
- Matrix Authorization Strategy Plugin Version 3.2.3
- Generic Webhook Trigger
- Multibranch Scan Webhook Trigger
- Deploy to container

## 4. Nodes
- Nodes are Jenkins servers or agents that can run jobs as slave.
- Click [here](./slave_setup.md) & open in new tab for details.

## 5. Security
- Jenkins has a built-in security system that allows you to configure access control for users and groups.
- Click [here](./security.md) & open in new tab for details.

## 6. Credentials

---

## Job Types
In Jenkins, different types of jobs allow you to define and automate various stages of the software
development lifecycle. Here are some common types:
### 1. Freestyle Project
- A general-purpose job type where you can define a series of build steps, such as running shell commands, executing scripts, and performing other tasks.
- Suitable for simple tasks and projects that don't require complex workflows.
- For details, click [here](./New%20Item.md).

### 2. Pipeline

- Jenkinsfile is a Groovy script that defines the pipeline.
- Jenkinsfile is stored in the repository, and Jenkins will automatically detect it and use it to build the project. 
- Jenkinsfile is a declarative syntax, meaning it defines what the pipeline should do, rather than how it should do it.
- If a tool, let say, `maven`, is not configured in groovy syntax, it must be installed on the Jenkins server locally.
- If configured with the Jenkinsfile, `pipeline script from SCM`, pipeline as code, you can use `replay` to view & build the pipeline.
- For details, click [here](./New%20Item.md).

### 3. Multibranch Pipeline

### 4. Maven Project

### 5. Multi-Configuration Project

---

## Jenkins CLI

- Download the specific Jar for CLI from [here](http://localhost:8080/jnlpJars/jenkins-cli.jar)
- Run the Jar file.
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/jnlpJars/jenkins-cli.jar
``` 
- Setting Up Environment Variables
```bash
export JEN_URL=http://localhost:8080/
export JEN_USER=admin
export JEN_PASSWORD=ibtisam
```
- List all the jobs
```bash
java -jar jenkins-cli.jar -s $JEN_URL -auth $JEN_USER:$JEN_PASSWORD list-jobs
```
- click [here](http://localhost:8080/manage/cli/) to see all available Jenkins CLI commands.

---

## Important Key Concepts

### Parameters and Variables
- Parameters are inputs provided by users at build time, while variables are values used within the build or pipeline.
- Variables can be defined in the Jenkinsfile or in the Jenkins UI.
- Parameters are defined in the job configuration, or in the Jenkinsfile or pipeline. script.
- Click [here](./params_and_var.md) for more details.

### Shared Libraries
- Shared libraries in Jenkins are reusable code components that centralize common logic, making pipelines modular, maintainable, and consistent.
- Push groovy files to GitHub and configure under `System > Global Trusted Pipeline Libraries`.
- Click [here](./shared_lib.md) for more details.

### User Access Management
- Jenkins provides various roles and permissions to manage user access.
    - Add the plugin `Matrix Authorization Strategy Plugin`, it comes by-default now.
    - Add users to the Jenkins user list under `Manage Jenkins > Users`
    - Go to `Manage Jenkins > Security > Authorization > Matrix-based security` to configure the roles and permissions.

![](./images/Matrix-based%20Security.png)

### Webhook
- Webhooks are used to notify Jenkins of changes to a repository, triggering a build.
- Click [here](./webhook_setup.md) for more details.

### Upstream vs Downstream Jobs
- Upstream jobs are the ones that trigger the downstream jobs.
- Downstream jobs are the ones that are triggered by the upstream jobs.

#### Here is how to configure a upstream job to trigger a downstream job in `Freestyle Project`:
- Go to `Configure` of the upstream job as following:

![](./images/Post-build%20Actions.png)

#### Here is an example of how to trigger a downstream job from an upstream job in a `Pipeline` job.

```groovy
stages {
        stage('Hello') {
            steps {
                echo "Hello, my sweetheart"
            }
        }
    }
    post {
        success {
            build 'Job B' // mention downstream job name
        }
        failure {
            build 'Job C' // mention downstream job name
        }
    }    
```

### Deployment via Tomcat
- Jenkins can be used to deploy the Java based application to a Tomcat server.
- Click [here](https://github.com/ibtisamops/nectar/blob/main/servers/tomcat.md) to set up Tomcat server.
- Install Jenkins via JAR file and change the port by specifying the `--httpPort` option. 
- Install `Deploy to container Plugin` plugin in Jenkins.
    - This plugin allows you to deploy a **war** to a container after a successful build.
- Unlike `Maven` or `Sonarqube`, there is no option to configure the `Tomcat` server in Jenkins UI.
- In `Freestyle Job`, configure it under `Post-build Actions` during the job configuration.
- For `Pipeline`, there is no `Post-build Actions` option during the job configuration. Hence, configure it as following:

![](./images/Tomcat%20SetUp1.png)
![](./images/Tomcat%20SetUp2.png)


```groovy
        // Put all the stages as usual, like git checkout, compile, test, and package etc.
        stage('Deploy') {
            steps {
                // deploy to tomcat server
                deploy adapters: [tomcat9(credentialsId: 'tomcat-server', path: '', url: 'http://localhost:8080/')], contextPath: 'hello-world', onFailure: false, war: 'target/*.war'
            }
        }
```

### Backup
1. Copy the Jenkins server's `/var/lib/jenkins` directory to a remote server or push it to a GitHub repository.
2. Install `Java` and `Jenkins` on the remote server.
3. Complete Jenkins's initial setup on the remote server.
4. Clone the repository or copy the `/var/lib/jenkins` directory to the remote server.
5. Change the ownership of the directory to `jenkins`:
```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins
```
6. Stop Jenkins:
```bash
sudo systemctl stop jenkins
```
7. Replace the existing `/var/lib/jenkins` directory with the copied one.
8. Restart Jenkins:
```bash
sudo systemctl start jenkins
```

### Email Configuration
- Please follow the detailed documentation [here](./mail_conf.md).

### Troubleshooting
- Please follow the detailed documentation [here](./troubleshooting.md).
