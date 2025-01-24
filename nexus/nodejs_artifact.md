# Publishing Node.js Artifacts to Nexus using Jenkins

## Step 1: Create a Custom `.npmrc` File in Jenkins

1. **Navigate to Jenkins Configuration:**
   - Go to **Manage Jenkins** > **Managed Files**.

2. **Create a New Custom File:**
   - Click on **Add a new Config**.
   - Select **Custom file** and name it `.npmrc`.

3. **Add Authentication Details:**
   - Convert your Nexus credentials to base64:
     ```bash
     echo -n 'admin:aditya' | base64
     ```
   - Example output:
     ```
     YWRtaW46YWRpdHlh
     ```
   - Add the following lines to the `.npmrc` file:
      - For Snapshot Repository:
     ```
     registry=http://13.235.245.200:8081/repository/npm-snapshot
     //13.235.245.200:8081/repository/npm-snapshot/:_auth=YWRtaW46YWRpdHlh
     ```
      - For Release Repository:
     ``` 
     registry=http://13.235.245.200:8081/repository/npm-release
     //13.235.245.200:8081/repository/npm-release/:_auth=YWRtaW46YWRpdHlh
     ```

---

## Step 2: Jenkins Pipeline Configuration

Create a Jenkins pipeline with the following stages:

```groovy
pipeline {
    agent any
    stages {
        stage('Git') {
            steps {
                git branch: 'main', url: 'https://github.com/jaiswaladi246/NodejS-JEST.git'
            }
        }
        stage('NPM Dependencies') {
            steps {
                nodejs('node20') {
                    sh "npm install"
                }
            }
        }
        stage('Publish to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'npmrc', targetLocation: '.')]) {
                    nodejs('node20') {
                        sh "npm publish"
                    }
                }
            }
        }
    }
}
```

- The .npmrc file created earlier is provided to the pipeline using configFileProvider.
- The artifacts are published to Nexus using the npm publish command.
- Replace the registry URL in the .npmrc file with the actual Nexus repository URL.
