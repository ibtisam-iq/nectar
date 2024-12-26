// This is a single-line comment

/* 
This is a multi-line comment.
It spans multiple lines.
*/

pipeline {
    agent any //  agent {label 'slave-1'} // directive

    tools { 
        maven "maven3"
        jdk "jdk17"
    }
    parameters {            // use this directive when the pipeline is not parameterized.
        choice choices: ['main', 'dev', 'ibtisam'], description: 'write description', name: 'Branch_name'
//      string defaultValue: 'main', description: 'enter description', name: 'Branch_name'
    }

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
        stage('Hello World') {              // copy 5 lines from stage('Hello') and paste for new stage
            steps {
                echo "Hello World"          // it runs inside Jenkins itself.
            }       
        }
        stage('Hello sh') {
            steps {
                sh 'echo "Hello World"'     // it runs on the Jenkins agent/slave.
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
                // deoloy to tomcat server
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
        stage('Install') {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                echo "Love you, Sweetheart Ibtisam"
            }
        }
    }
    post {
        success {
            // One or more steps need to be included within each condition's block.
            build 'Job B' // mention downstream job name
        }
        failure {
            // One or more steps need to be included within each condition's block.
            build 'Job C' // mention downstream job name
        }
    }
    // to clean up the workspace after the job is done
    post {
        always {
    // One or more steps need to be included within each condition's block.
            cleanWs()
    }
}

}

