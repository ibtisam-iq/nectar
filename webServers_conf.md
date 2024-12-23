# Tomcat

## Local Setup

```bash
sudo su; cd /opt
sudo wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz
sudo tar -xvf apache-tomcat-9.0.98.tar.gz

### Add the following line before the closing `</tomcat-users>` tag to configure Tomcat Users
cd /opt/apache-tomcat-9.0.98/conf; sudo vi tomcat-users.xml
```
   ```xml
   <user username="ibtisam" password="12345@s" roles="admin-gui,manager-gui,manager-script"/>
   ```
```bash
# Edit the `context.xml` file for the Manager web application:
  
   sudo vi /opt/apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
# Comment out the `RemoteAddrValve` configuration:
```
   ```xml
   <!--
   <Valve className="org.apache.catalina.valves.RemoteAddrValve"
   allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
   -->
   ```

```bash
# Edit the `context.xml` file for the Host Manager web application:
   sudo vi /opt/apache-tomcat-9.0.98/webapps/host-manager/META-INF/context.xml
# Comment out the `RemoteAddrValve` configuration:
```
   ```xml
   <!--
   <Valve className="org.apache.catalina.valves.RemoteAddrValve"
   allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
   -->
   ```

```bash
sudo ln -s /opt/apache-tomcat-9.0.98/bin/startup.sh /usr/bin/startTomcat
sudo ln -s /opt/apache-tomcat-9.0.98/bin/shutdown.sh /usr/bin/stopTomcat
sudo stopTomcat
sudo startTomcat
sudo netstat -tlnp | grep 8080
```
