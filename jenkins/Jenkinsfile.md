# Jenkinsfile Cheat Sheet

Have a look on the official Jenkins documentations
- [Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

- [Directive Generator](http://localhost:8080/directive-generator/)
- [Snippet Generator](http://localhost:8080/pipeline-syntax/)
- [Global Variable Reference](http://localhost:8080/pipeline-syntax/globals)


## Adding Comments in Jenkinsfile

```groovy
// This is a single-line comment

/* 
This is a multi-line comment.{
It spans multiple lines.
*/
```

## Pipeline Definition

```groovy
pipeline {
    agent any                // agent is a directive
    agent {label 'slave-1'}  // specify a specific agent
}
```

## Tools

```groovy
    tools { 
        maven "maven3"
        jdk "jdk17"
        nodejs 'nodejs23'
    }
```

## Parameters
- Use this directive when the pipeline is not parameterized.
- Parameters: string, choice, boolean, file
```groovy
    parameters {
        choice choices: ['main', 'dev', 'ibtisam'], description: 'write description', name: 'env'
        string defaultValue: 'main', description: 'enter description', name: 'Branch_name'
    }
```

## Stages

### Parallel Stages

```groovy
    stages {
        stage('Hello Parallel') {
            parallel {
                stage('Stage One') {
                    steps {
                        echo 'Running Stage One'
                    }
                }
                stage('Stage Two') {
                    steps {
                        echo 'Running Stage Two'
                    }
                }
            }
        }
```

### Sequential Stages

```groovy
        stage('Hello World') { // copy 5 lines from stage('Hello') and paste for new stage
            steps {
                echo "Hello World" // it runs inside Jenkins itself.
            }       
        }
        stage('Hello sh') {
            steps {
                sh 'echo "Hello World"' // it runs on the Jenkins agent/slave.
            }       
        }
        stage('Git Checkout') {
            steps {
                git branch: "${params.Branch_name}", url: 'Github URL' // Use when the pipeline is parameterized.
            }
        }
        stage('Compile') {
            steps {
                dir('03.Projects/00.LocalOps/0.1.01-jar_Boardgame') {
                    sh 'mvn compile'
                }
            }
        }
        stage('Test') {
            // executes this stage only if any change happens in 'path_to_file.txt'  
            when {
                changeset 'path_to_file.txt'
            }
            steps {
                echo 'mvn test'
            }
        }
        stage('Package') {
            steps {
                sh "mvn clean package"
            }
        }
        stage('Deploy') {
            steps {
                // deploy to tomcat server
                deploy adapters: [tomcat9(credentialsId: 'tomcat-server', path: '', url: 'http://localhost:8080/')], contextPath: 'hello-world', onFailure: false, war: 'target/*.war'
                // deploy to multi env
                script {
                    if (params.env == 'dev') {
                        sh 'mvn clean deploy'
                    } 
                    else if (params.env == 'prod') {
                        sh 'mvn clean deploy'
                    } 
                    else {
                        echo 'Invalid environment'
                    }
                }
            }
        }
        stage('Install') {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                    echo "Love you, Sweetheart Ibtisam"
                }
            }
        }
    }
```

## Post Actions

![](./images/Post%20Directive.png)

```groovy
    post {
        success {
            // One or more steps need to be included within each condition's block.
            build 'Job B' // mention downstream job name
        }
        failure {
            // One or more steps need to be included within each condition's block.
            build 'Job C' // mention downstream job name
        }
        always {
            // One or more steps need to be included within each condition's block.
            cleanWs() // to clean up the workspace after the job is done
        }
    }
```

## Email Setup
```groovy
    post {
        failure {
            // Send a notification when the build fails
            echo 'Build failed'
            mail to: 'loveyou@mibtisam.com',
                subject: 'Build failed: ${env.JOB_NAME} -  Build #${env.BUILD_NUMBER}',
                body: 'Job ${env.JOB_NAME} failed with build number ${env.BUILD_NUMBER}.'
        }
        success {
            // Send a notification when the build is successful
            echo 'Build successful'
            archiveArtifacts artifacts: '**/target/*.jar', followSymlinks: false, onlyIfSuccessful: true
        }
    }
```
## Scenario Based Implementation

### 1. Changeset
```groovy
        stage('Test') {
            // executes this stage only if any change happens in 'path_to_file.txt', otherwise, it will skip this stage  
            when {
                changeset 'path_to_file.txt'
            }
            steps {
                echo 'mvn test'
            }
        }
```

---

### 2. Change directory
```groovy
        stage('Git Checkout') {
            steps {
                git branch: "${params.Branch_name}", url: 'Github URL' // Use when the pipeline is parameterized.
            }
        }
        stage('Compile') {
            steps {
                dir('03.Projects/00.LocalOps/0.1.01-jar_Boardgame') {
                    sh 'mvn compile'
                }
            }
        }
```

---

### 3. Deploy to a specific env (Multi Env)

```groovy
    parameters {
        choice choices: ['main', 'dev', 'ibtisam'], description: 'write description', name: 'env'
    }

        stage('Deploy') {
            steps {
                echo "deploy to multi env"
                script {
                    if (params.env == 'dev') {
                        sh 'mvn clean deploy'
                    } 
                    else if (params.env == 'ibtisam') {
                        sh 'mvn clean deploy'
                    } 
                    else {
                        echo 'main'
                    }
                }
            }
        }
```

---

### 4. Parallel Stage Pipeline
### 5. Post cleanup 
```groovy
    post {
        always {
            echo "cleaning up the workspace after the job is done"
            cleanWs()
        }
    }
```

![](./images/cleanWS.png)

---

### 6. Timeout

```groovy
        stage('Install') {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                    echo "Love you, Sweetheart Ibtisam"
                }
            }
        }
```

---

## Maven Pipeline

```groovy
pipeline {
    agent any
    tools {
        maven "maven3"
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn compile'
                sh 'mvn clean test'
                sh 'mvn clean package'
            }
        }
    }
    post {
        success {
            archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false, onlyIfSuccessful: true
        }
    }
}
```

---

## Python Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup Virtual Environment') {
            steps {
                sh '''
                    # Remove any existing virtual environments
                    rm -rf IbtisamX

                    # Create a new virtual environment
                    python3 -m venv IbtisamX

                    # Set permissions
                    chmod -R 755 IbtisamX
                    
                    # The error /var/lib/jenkins/workspace/.../script.sh.copy: 12: source: not found occurs because the source command is not recognized by the shell executing the script.
                    # The source command is a shell built-in command, and it is not available in the shell that is executing the script.
                    # the default shell being used in Jenkins (sh) is not Bash but a more basic shell like dash, which doesn't support source.
                    # To fix this error, you can use the dot (.) command instead of source to activate the virtual environment.

                    # Activate virtual environment and install dependencies
                    . IbtisamX/bin/activate

                    # Upgrade pip package itself using pip
                    pip install --upgrade pip

                    # Install dependencies
                    sh 'python --version'
                    pip install -r requirements.txt
                '''
                /*
                sh '''
                rm -rf IbtisamX
                python3 -m venv IbtisamX
                chmod -R 755 IbtisamX
                bash -c "
                source IbtisamX/bin/activate
                pip install --upgrade pip
                pip install -r requirements.txt
                "
                '''
                */
            }
        }

        stage('Run Tests - Pytest') {
            steps {
                sh '''
                    # Activate virtual environment and run tests with coverage
                    . IbtisamX/bin/activate
                    python --version

                    # Install coverage package for pytest framework
                    pip install pytest pytest-cov

                    # Run tests with pytest and generate coverage reports
                    pytest --cov=app tests/ --cov-report=xml --cov-report=term-missing --disable-warnings
                '''
            }
        }

        stage('Run Tests - Unittest') {
            steps {
                sh '''
                    # Activate virtual environment and run tests with coverage
                    . IbtisamX/bin/activate
                    python --version

                    # Install coverage package for pytest framework
                    pip install coverage

                    # Run tests with pytest and generate coverage reports
                    coverage run -m unittest discover
                    coverage xml
                '''
            }
        }
    }
}
```

---

## Jenkinsfile for Node.js

```groovy
pipeline {
    agent any
    tools {
        nodejs 'nodejs23'
    }
    stages {
        stage('Build') {
            steps {
                dir('SonarQube/Nodejs-jest') {
                    nodejs('nodejs23') {
                        sh 'npm install'
                        sh 'npm run test' // test is the script name in package.json, that's it is written as npm `run` test
                    }    
                }
            }    
        }
    }
}
```

---