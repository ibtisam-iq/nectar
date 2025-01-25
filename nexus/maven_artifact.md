## Configure Jenkins to Use Nexus

### Step 1: URL
- Unlike SonarQube, you need URL of the nexus repo, not the server itself.
- Unlike Sonarqube, you need to add the URL in the `source code`, not inside the Jenkins UI.
Integrate Maven with Nexus, update your `pom.xml` file to include the following:  
```xml
<project>
    <!-- Other project information -->
    <distributionManagement>
        <repository>
            <id>maven-releases</id>
            <url>NEXUS-URL/repository/maven-releases/</url>
        </repository>
        <snapshotRepository>
            <id>maven-snapshots</id>
            <url>NEXUS-URL/repository/maven-snapshots/</url>
        </snapshotRepository>
    </distributionManagement>
    <!-- Other project configuration -->
</project>
```  
Replace `NEXUS-URL` with the URL of your Nexus repository.

### Step 2: Credentials
- The credentials will be provided to the Jenkins via a configuration file `setting.xml`.
- Install a plugin `Config File Provider`. It provides us the ability to provide configuration files.

---

## Stage: Download JAR with Credentials

This Jenkins pipeline stage is designed to securely download a `.jar` file from a URL requiring authentication. It uses credentials stored in Jenkins' credentials store to handle the authentication.

### Pipeline Code
```groovy
stage('Download JAR with Credentials') {
  steps {
    script {
      withCredentials([usernamePassword(credentialsId: 'your-credentials-id',
                                        usernameVariable: 'user', 
                                        passwordVariable: 'pass')]) {
        def jarUrl = 'https://example.com/path/to/your.jar'
        sh "curl -u $user:$pass -O $jarUrl"
      }
    }
  }
}
```
### **Key Components**

1. **`withCredentials` Block**
   - Securely retrieves credentials stored in Jenkins.
   - **Parameters:**
     - `credentialsId`: The unique ID of the credentials stored in Jenkins.
     - `usernameVariable`: The environment variable (`user`) used to store the username.
     - `passwordVariable`: The environment variable (`pass`) used to store the password.

2. **`jarUrl`**
   - The URL of the `.jar` file to be downloaded.

3. **`sh` Step**
   - Executes a shell command to download the JAR file using `curl`.
   - **Options:**
     - `-u $user:$pass`: Passes the username and password for authentication.
     - `-O`: Saves the file with its original name.

---

## Stage: Deploy to Nexus

```groovy
stage('Code-Build') {
    steps {
        sh "mvn clean package"
    }
}

stage('Deploy To Nexus') {
    steps {
        withMaven(globalMavenSettingsConfig: 'e7838703-298a-44a7-b080-a9ac14fa0a5e') {
            sh "mvn deploy"
        }
    }
}
```

### `withMaven` Step in Jenkins

The `withMaven` step in Jenkins is used to integrate Maven builds with Jenkins pipelines. It provides an environment where Jenkins can manage Maven-related tasks, such as building, testing, and deploying Java applications, while automatically handling configurations like:

#### Key Parameter in `withMaven`

##### `globalMavenSettingsConfig`
- Refers to a pre-configured Maven settings file in Jenkins.
- The value (`e7838703-298a-44a7-b080-a9ac14fa0a5e`) is an identifier for a stored Maven settings configuration.
- It typically includes details like:
  - Repository URLs.
  - Authentication credentials for private repositories like Nexus or Artifactory.
  - Proxy settings or build profiles.

#### What It’s For

In this specific context:
- Ensures the `mvn deploy` command uses the correct Maven settings file.
- Helps Jenkins connect securely to the Nexus repository (or any artifact repository) by:
  - Resolving dependencies during the build.
  - Deploying the built artifacts to the repository.

---


