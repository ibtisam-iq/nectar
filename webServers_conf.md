# Tomcat

## Local Setup

```bash
# Switch to the root user and navigate to the /opt directory
sudo su; cd /opt

# Download the specified version of Apache Tomcat
sudo wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz

# Extract the downloaded Apache Tomcat archive
sudo tar -xvf apache-tomcat-9.0.98.tar.gz

# Navigate to the Tomcat configuration directory to modify the user credentials
cd /opt/apache-tomcat-9.0.98/conf

# Open the tomcat-users.xml file for editing to configure Tomcat users
sudo vi tomcat-users.xml
```
Add the following line before the closing </tomcat-users> tag in the tomcat-users.xml file
```xml
<user username="ibtisam" password="12345@s" roles="admin-gui,manager-gui,manager-script"/>
```
Modify the Manager web application's context.xml to disable IP restrictions

```bash
sudo vi /opt/apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
```
Comment out the RemoteAddrValve configuration by enclosing it in `<!-- -->`:
- To "comment out" means adding the comment tags `<!-- -->` around a piece of code to disable it, preventing it from being executed or processed.

```xml
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```
Modify the Host Manager web application's context.xml to disable IP restrictions

```bash
sudo vi /opt/apache-tomcat-9.0.98/webapps/host-manager/META-INF/context.xml
```
Comment out the RemoteAddrValve configuration here as well:

```xml
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```

```bash
# Create symbolic links for the Tomcat startup and shutdown scripts for easier access
sudo ln -s /opt/apache-tomcat-9.0.98/bin/startup.sh /usr/bin/startTomcat
sudo ln -s /opt/apache-tomcat-9.0.98/bin/shutdown.sh /usr/bin/stopTomcat

# Start Tomcat using the custom command
sudo startTomcat

# Stop Tomcat using the custom command
sudo stopTomcat

# Check if Tomcat is running on port 8080
sudo netstat -tlnp | grep 8080
```
**Key Notes:**

1. Tomcat Users:
   - The `<user>` tag in tomcat-users.xml defines credentials for accessing the Tomcat Manager and Admin interfaces.

2. IP Restrictions:
   - By default, Tomcat restricts access to the Manager and Host Manager applications to localhost. Commenting out the RemoteAddrValve allows access from other IPs.

3. Symbolic Links:
   - The ln -s commands create shortcuts (startTomcat and stopTomcat) for easier execution of Tomcat's startup and shutdown scripts.

4. Port Check:
   - The netstat command verifies if Tomcat is running and listening on the default HTTP port (8080).