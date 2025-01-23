# Integrating SonarQube with Jenkins

## Steps to Integrate

- **Install Plugins**: `SonarQube Scanner` plugin in Jenkins to publish the results to SonarQube Server.

- **Add SonarQube Scanner**: `Manage Jenkins > Tool`, configure scanner.

![](./images/Scanner.png)

- **Configure SonarQube Server**: `Manage Jenkins > System`, add SonarQube server details.

![](./images/Server.png)

  - Best Practice: Use an access token (generated in SonarQube) instead of a `username` and `password`. Save the token as a `Secret Text` under `Credentials`.

![](./images/Create%20User.png)

![](./images/Token.png)

- **Configure Webhook**: Set up a webhook in SonarQube Server to send analysis results to Jenkins.
    - Read the official documentation [here](https://docs.sonarsource.com/sonarqube-server/9.9/project-administration/webhooks/)

![](./images/Webhook.png)

## Pipeline Stages

1. **SonarQube Analysis**
   ```groovy
   // This stage must be after "Testing"
  
   stage('SonarQube Analysis') {
        steps {
            dir('03.Projects/00.LocalOps/0.1.01-jar_Boardgame') {
                withSonarQubeEnv('sonar-server') {
                    sh "$SCANNER_HOME/bin/sonar-scanner"
                    }
                }
            }
        }
   ```

2. **Quality Gate Check**
   ```groovy
   stage('Quality Gate') {
       steps {
            timeout(5) {
                waitForQualityGate abortPipeline: false
            }
       }
   }
   ```

---

### For Python Projects

Add the following depencendies to your `requirements.txt` file:

```bash
sonar-scanner==4.6.2.2472
# For testing and code coverage
pytest==7.4.2
pytest-cov==4.1.0
coverage==7.3.1
```

### Configuration
- Create `sonar-project.properties` file in the root directory as [following](./properties.md).
- For details, please refer to the official documentation [here](https://docs.sonarqube.org/latest/analysis/analysis-parameters/).