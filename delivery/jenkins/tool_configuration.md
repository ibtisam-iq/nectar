# Jenkins Tool Configuration — Complete Guide

This document explains the `Manage Jenkins → Tools` section in depth: what it is, why it exists, which tools need to be registered there, and which do not — with practical examples tailored to a single-server Jenkins setup.

---

## What Is `Manage Jenkins → Tools`?

Jenkins has a built-in **Tool Management system** that allows Jenkins itself to manage specific tools — meaning it can **download, install, and version-switch** tools automatically on any agent. This is configured under:

```
Manage Jenkins → Tools
```

This section only shows tool types that have a **Jenkins plugin** providing that integration. Out of the box (or with common plugins), you will see:

- JDK
- Maven
- Gradle
- Ant
- NodeJS (via NodeJS plugin)
- Git

Tools like `kubectl`, `helm`, `terraform`, `ansible`, `trivy`, `aws` — these have **no native Jenkins tool plugin**, so they never appear here.

---

## The Core Concept: Two Ways Jenkins Finds a Tool

### Way 1 — Shell PATH Resolution (default for all tools)

When you write this in a Jenkinsfile:

```groovy
sh 'mvn clean package'
```

Jenkins executes this as a shell command on the agent. The shell resolves `mvn` using the system `PATH` — exactly the same as typing `mvn` in your terminal. If the binary is on `PATH`, it works. **No Jenkins configuration needed.**

### Way 2 — Jenkins `tools {}` Directive

When you write this in a Jenkinsfile:

```groovy
tools {
    maven 'maven-3.9.15'
}
```

Jenkins looks up `maven-3.9.15` in its **internal tool registry** (`Manage Jenkins → Tools`). It finds the registered installation, sets `MAVEN_HOME` and prepends the tool's `bin/` to `PATH` for that pipeline run. If no tool with that name is registered, **the pipeline fails** — even if `mvn` is perfectly available on system PATH.

---

## Why Does the `tools {}` Directive Exist?

It was designed for **enterprise, multi-agent, multi-version** scenarios:

| Problem | How `tools {}` solves it |
|---|---|
| 50 build agents, tool not pre-installed on all | Jenkins auto-installs the tool on whichever agent picks the job |
| Pipeline A needs Maven 3.8, Pipeline B needs Maven 3.9 | Each pipeline declares its version name; Jenkins switches accordingly |
| New agent added to the pool | Jenkins installs all required tools automatically on first use |
| Reproducible builds across environments | Tool version is declared in code, not assumed from the OS |

In a **single-server setup with tools pre-installed**, none of these problems exist. The `tools {}` directive gives you zero benefit.

---

## Decision Rule — Simple and Final

```
Is the tool binary on system PATH?
        │
        └── YES
              │
              ├── Do you want Jenkins to auto-install / version-switch it?
              │         │
              │         ├── YES → Register in Manage Jenkins → Tools
              │         │          Use: tools { maven 'name' }
              │         │
              │         └── NO  → Just call it via sh ''
              │                    Configure NOTHING in Jenkins UI
              │
              └── NO → Install it on the OS first, then apply above logic
```

---

## Your 10 Tools — Applied Analysis

Your `install-pipeline-tools` script installs the following 10 tools. Here is the complete analysis for each.

### 1. Maven — `/usr/local/bin/mvn`

**Plugin available:** Yes — [Maven Integration Plugin](https://plugins.jenkins.io/maven-plugin/)

**Does it need UI config?** Only if you use `tools { maven '...' }` in your Jenkinsfile.

**Recommendation for single-server setup:** Skip UI config. Use directly:

```groovy
sh 'mvn clean package -DskipTests'
sh 'mvn clean verify'
```

**If you want to use `tools {}` (optional):**

```bash
# Find MAVEN_HOME
mvn -version
# Output: Maven home: /opt/maven/apache-maven-3.9.15
```

```
Manage Jenkins → Tools → Maven installations → Add Maven
  Name:                  maven-3.9.15
  MAVEN_HOME:            /opt/maven/apache-maven-3.9.15
  Install automatically: ✗ unchecked
```

Then in Jenkinsfile:
```groovy
tools { maven 'maven-3.9.15' }
// now mvn is on PATH for this pipeline
sh 'mvn clean package'
```

---

### 2. Node.js — `/usr/bin/node`
### 3. npm — `/usr/bin/npm`

**Plugin available:** Yes — [NodeJS Plugin](https://plugins.jenkins.io/nodejs/)

**Does it need UI config?** Only if you use `tools { nodejs '...' }` in your Jenkinsfile.

**Recommendation for single-server setup:** Skip UI config. Use directly:

```groovy
sh 'node --version'
sh 'npm install'
sh 'npm run build'
```

**If you want to use `tools {}` (optional):**

```
Manage Jenkins → Tools → NodeJS installations → Add NodeJS
  Name:                    nodejs-22
  Installation directory:  /usr/bin
  Install automatically:   ✗ unchecked
```

Then in Jenkinsfile:
```groovy
tools { nodejs 'nodejs-22' }
sh 'npm install && npm run build'
```

> **Note:** `npm` does not have its own tool type. It comes bundled with Node.js. Registering Node.js covers `npm` automatically.

---

### 4. Python — `/usr/bin/python3`

**Plugin available:** No Jenkins-native tool plugin for Python.

**Does it need UI config?** No.

**Use directly in Jenkinsfile:**

```groovy
sh 'python3 --version'
sh 'python3 -m pytest tests/'
sh 'pip3 install -r requirements.txt'
```

---

### 5. Docker — `/usr/bin/docker`

**Plugin available:** Yes — [Docker Plugin](https://plugins.jenkins.io/docker-plugin/) and [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)

**Does it need UI config?** No — these plugins provide pipeline DSL (`docker.build()`, `docker.image()`) but do **not** require `Manage Jenkins → Tools` registration. The Docker binary is found via PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'docker build -t myapp:latest .'
sh 'docker push myapp:latest'

// OR using Docker Pipeline plugin DSL (no tools{} needed)
docker.build('myapp:latest').push()
```

> **Important:** The `jenkins` OS user must be in the `docker` group to run Docker commands without `sudo`:
> ```bash
> sudo usermod -aG docker jenkins
> sudo systemctl restart jenkins
> ```

---

### 6. Trivy — `/usr/bin/trivy`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL myapp:latest'
sh 'trivy fs --exit-code 0 --severity MEDIUM .'
```

> ⚠️ Pinned to `v0.69.3` — see [silver-stack README](https://github.com/ibtisam-iq/silver-stack/blob/main/iximiuz/rootfs/jenkins/README.md) for the supply chain attack note on `v0.69.4`.

---

### 7. AWS CLI — `/usr/local/bin/aws`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'aws --version'
sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com'
sh 'aws s3 cp target/app.jar s3://my-bucket/releases/'
```

> **Credentials:** AWS credentials are passed via Jenkins credentials (environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), not through `Manage Jenkins → Tools`.

---

### 8. kubectl — `/usr/local/bin/kubectl`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'kubectl version --client'
sh 'kubectl apply -f k8s/deployment.yaml'
sh 'kubectl rollout status deployment/myapp -n production'
```

---

### 9. Helm — `/usr/local/bin/helm`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'helm version --short'
sh 'helm upgrade --install myapp ./charts/myapp --namespace production'
sh 'helm lint ./charts/myapp'
```

---

### 10. Terraform — `/usr/local/bin/terraform`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'terraform version'
sh 'terraform init'
sh 'terraform plan -out=tfplan'
sh 'terraform apply -auto-approve tfplan'
```

---

### 11. Ansible — `/usr/bin/ansible`

**Plugin available:** No Jenkins-native tool plugin.

**Does it need UI config?** No. Plain binary on PATH.

**Use directly in Jenkinsfile:**

```groovy
sh 'ansible --version'
sh 'ansible-playbook -i inventory/production deploy.yml'
```

---

## Final Reference Table

| Tool | Binary Path | Jenkins Plugin | Needs `Manage Jenkins → Tools`? | How to Use in Pipeline |
|---|---|---|---|---|
| Maven | `/usr/local/bin/mvn` | ✅ maven-plugin | Optional | `sh 'mvn ...'` or `tools { maven 'name' }` |
| Node.js | `/usr/bin/node` | ✅ nodejs-plugin | Optional | `sh 'node ...'` or `tools { nodejs 'name' }` |
| npm | `/usr/bin/npm` | Bundled with Node.js | Optional (via Node.js) | `sh 'npm ...'` |
| Python | `/usr/bin/python3` | ❌ None | **No** | `sh 'python3 ...'` |
| Docker | `/usr/bin/docker` | ✅ docker-plugin (DSL only) | **No** | `sh 'docker ...'` |
| Trivy | `/usr/bin/trivy` | ❌ None | **No** | `sh 'trivy ...'` |
| AWS CLI | `/usr/local/bin/aws` | ❌ None | **No** | `sh 'aws ...'` |
| kubectl | `/usr/local/bin/kubectl` | ❌ None | **No** | `sh 'kubectl ...'` |
| Helm | `/usr/local/bin/helm` | ❌ None | **No** | `sh 'helm ...'` |
| Terraform | `/usr/local/bin/terraform` | ❌ None | **No** | `sh 'terraform ...'` |
| Ansible | `/usr/bin/ansible` | ❌ None | **No** | `sh 'ansible-playbook ...'` |

---

## When Would You Actually Use `Manage Jenkins → Tools`?

Register a tool in the UI **only** when one of these is true:

1. **You want Jenkins to auto-install the tool** — useful when you have multiple agents and don't want to pre-install manually on each
2. **You need multiple versions of the same tool** — e.g., Maven 3.8 for legacy projects and Maven 3.9 for new ones, on the same server
3. **You are using the `tools {}` directive** in your Jenkinsfile and want the benefits of Jenkins-managed environment variable injection (`MAVEN_HOME`, `JAVA_HOME`, etc.)

For a **single Jenkins server with all tools pre-installed**, the correct answer is: **configure nothing in `Manage Jenkins → Tools`**. All 10 tools are on `PATH` and work directly via `sh ''` steps.

---

## Complete Jenkinsfile Example (Single Server, No `tools {}` Needed)

```groovy
pipeline {
    agent any

    environment {
        APP_IMAGE    = 'myapp:latest'
        ECR_REGISTRY = '123456789.dkr.ecr.us-east-1.amazonaws.com'
    }

    stages {

        stage('Build — Java') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build — Node') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${APP_IMAGE} ."
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${APP_IMAGE}"
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh """
                        aws ecr get-login-password --region us-east-1 \\
                          | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        docker tag ${APP_IMAGE} ${ECR_REGISTRY}/${APP_IMAGE}
                        docker push ${ECR_REGISTRY}/${APP_IMAGE}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'helm upgrade --install myapp ./charts/myapp --namespace production'
                sh 'kubectl rollout status deployment/myapp -n production'
            }
        }

        stage('Provision Infrastructure') {
            steps {
                sh 'terraform init && terraform apply -auto-approve'
            }
        }

        stage('Configure Servers') {
            steps {
                sh 'ansible-playbook -i inventory/production deploy.yml'
            }
        }

    }
}
```

All stages work with zero `Manage Jenkins → Tools` configuration because every binary is on system PATH.
