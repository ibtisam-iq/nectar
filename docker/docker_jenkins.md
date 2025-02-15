- Run `sudo usermod -aG docker $USER` to add the Jenkin's server user to the docker group.
- Restart the Jenkins server instead of running `newgrp docker`.

Install the following plugins:
- `Docker Pipeline`:
    - used to build and push Docker images to a registry, such as Docker Hub.
    - used to run Docker containers in a pipeline.
    - used to build Docker containers from pipeline scripts.
- `Docker Compose Build Step`:
    - used to build and push Docker Compose files to a registry.
    - used to run Docker Compose services in a pipeline.


```groovy
stage('Deploy Artifact to Nexus'){
    steps {
        withMaven(globalMavenSettingsConfig: 'global-maven-settings', jdk: 'jdk17', maven: 'maven3' mavenSettingsConfig: '', traceability: false) {
            sh 'mvn deploy'
        }
    }
}

/*
In case of rollback
stage('Rollback'){
    steps {
        dir('artifact/'){
            withCredentials([usernamePassword(credentialsId: 'nexus-cred', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
            sh '''
            curl -u $USER:$PASS -o v6.jar NEXUS_REPO_URL
            '''
            }
        }
    }
}
Now, modify the Dockerfile, from which location it will pick the artifact, and copy it in Image.
ENV APP_HOME /app
COPY target/*.jar $APP_HOME/app.jar
COPY artifact/*.jar $APP_HOME/app.jar

In companies, for rollback, we use the Docker image, not the artifact.
*/

stage('Build Docker Image') {
    steps {
        script{
            withDockerRegistry(credentialsId: 'docker-cred') {
                sh 'docker build -t my-image:latest .'
                sh 'docker tag my-image:latest my-registry:5000/my-image:latest'
                sh 'docker push my-registry:5000/my-image:latest'
                sh 'docker run -d -p 8082:8080 my-registry:5000/my-image:latest'
            }
        }
    }
}       
```
