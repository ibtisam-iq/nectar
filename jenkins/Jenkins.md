# Jenkins Setup and Configuration Guide

#### Continuous Integration, Delivery, and Deployment

- **Continuous Integration**: Automation to build and test applications whenever new commits are pushed into the branch.
- **Continuous Delivery**: Continuous Integration + Deploy application to production by "clicking on a button" (Release to customers is often, but on demand).
- **Continuous Deployment**: Continuous Delivery but without human intervention (Release to customers is ongoing).

![](./images/Delivery%20vs%20Deployment.png)
#### Pipeline Types

- **Scripted Pipeline**: Original, code validation happens while running the pipeline. Can’t restart. Executed all stages sequentially.
- **Declarative Pipeline**: Latest, first validates the code, and then runs the pipeline. Restarting from a specific stage is supported. A particular stage can be skipped based on the `when` directive.

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

## Walkthrough Manage Jenkins UI

The Manage Jenkins tab is for managing Jenkins itself. This includes managing plugins, managing the Jenkins instance, and managing the Jenkins configuration.

![](./images/Manage%20Jenkins.png)

### 1. System 

The System tab is for setting up global configurations that Jenkins and plugins (servers) require to operate at a higher level. These configurations typically deal with the overall functioning of Jenkins or its plugins.

#### Shared libraries

Push groovy files to GitHub and configure under System > Global Trusted Pipeline Libraries.

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

Click ![here](./jenkinsCheatSheet.md) for details.
## 5. Security

## 6. Credentials

## 7. Users

## Job Types
In Jenkins, different types of jobs allow you to define and automate various stages of the software
development lifecycle. Here are some common types:
### 1. Freestyle Project
- A general-purpose job type where you can define a series of build steps, such as running shell commands, executing scripts, and performing other tasks.
- Suitable for simple tasks and projects that don't require complex workflows.

![Specify the Git Branch](./images/Branch%20Specifier.png)

![Build Steps](./images/Build%20Steps%20for%20Java%20App.png)


### 2. Pipeline

- Jenkinsfile is a Groovy script that defines the pipeline.
- Jenkinsfile is stored in the repository, and Jenkins will automatically detect it and use it to build the project. 
- Jenkinsfile is a declarative syntax, meaning it defines what the pipeline should do, rather than how it should do it.
- If a tool, let say, `maven`, is not configured in groovy syntax, it must be installed on the Jenkins server locally.
- If configured with the Jenkinsfile, `pipeline script from SCM`, pipeline as code, you can use `replay` to view & build the pipeline.

![Specify Jenkinsfile Pipeline as Code](./images/Script%20Path.png) 

### 3. Multibranch Pipeline

### 4. Maven Project

### 5. Multi-Configuration Project

