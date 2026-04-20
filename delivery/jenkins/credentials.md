# Jenkins Credentials — Complete Guide

This document explains how Jenkins Credentials work, the different credential types, why they differ per service, the two ways to inject them in a Jenkinsfile, and step-by-step configuration for every tool used in this pipeline.

---

## What Are Jenkins Credentials?

Jenkins Credentials is a **secure vault** built into Jenkins. Instead of hardcoding passwords, tokens, or keys inside your Jenkinsfile (which would be visible in Git history), you store them in Jenkins once and reference them by a short **ID** string in your pipeline.

All credentials are managed at:

```
Manage Jenkins → Credentials → System → Global credentials (unrestricted) → Add Credentials
```

---

## Credential Types — Why They Differ

Different external services use different authentication protocols. Jenkins provides a matching type for each:

| Type | When to Use | Example Services |
|---|---|---|
| **Username with Password** | Service requires both a login name and a password/token | Docker Hub, Nexus, GitHub (HTTPS) |
| **Secret Text** | Service issues a single standalone token (no username needed) | SonarQube, GitHub PAT (token-only), Slack webhook |
| **Secret File** | Service requires an entire file for authentication | kubeconfig, GCP service account JSON |
| **SSH Username with Private Key** | SSH-based git or server access | GitHub SSH, Ansible target servers |
| **AWS Credentials** | AWS IAM access key + secret key pair | ECR, S3, EKS, ECS |

The reason some need a username+password and some need only a token is the **design of that service's API** — not a Jenkins decision.

---

## Two Ways to Inject Credentials in a Jenkinsfile

Once a credential is stored in Jenkins, you inject it into your pipeline using one of two syntaxes. Both work for any credential type — the choice is about **scope and readability**.

### Option 1 — `environment {}` block

```groovy
pipeline {
    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }
    stages {
        stage('Scan') {
            steps {
                sh 'mvn sonar:sonar -Dsonar.token=$SONAR_TOKEN'
            }
        }
    }
}
```

- Credential is available to **all stages** — global pipeline scope
- Clean and readable — declared once at the top
- Best for **Secret Text** (maps to one variable cleanly)
- For `Username with Password` type, Jenkins auto-creates **three** variables:
  - `VARNAME` → `username:password` combined
  - `VARNAME_USR` → username only
  - `VARNAME_PSW` → password only

### Option 2 — `withCredentials {}` block

```groovy
stage('Docker Push') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        }
    }
}
```

- Credential is available **only inside that block** — tightly scoped
- You explicitly name the injected variables yourself
- Best when credential is used in **only one stage**
- Required for `Secret File` and `SSH` types (no `environment {}` shorthand for these)

### When to Use Which

| Situation | Use |
|---|---|
| Single token used across multiple stages | `environment { credentials() }` |
| Username + Password needing separate variables | `withCredentials [usernamePassword(...)]` |
| Credential needed in only one stage | `withCredentials` — keeps scope tight |
| Secret file (e.g., kubeconfig) | `withCredentials [file(...)]` — only option |
| SSH private key | `withCredentials [sshUserPrivateKey(...)]` — only option |

> There is **no technical difference** in what gets injected — only scope and readability differ. Both syntaxes can be used for any compatible credential type.

---

## Tool-by-Tool Credential Configuration

### 1. Docker Hub

**Authentication:** Username + Access Token (not your real account password)

**Generate token:** `hub.docker.com → Account Settings → Security → New Access Token`

Scopes needed: `Read`, `Write`, `Delete` (or `Read & Write` minimum for push)

**Add to Jenkins:**
```
Kind:     Username with password
Username: your-dockerhub-username
Password: dckr_pat_xxxxxxxxxxxxxxxxxxxx   ← access token
ID:       dockerhub-creds
```

**In Jenkinsfile:**
```groovy
withCredentials([usernamePassword(
    credentialsId: 'dockerhub-creds',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
)]) {
    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
    sh 'docker push myapp:latest'
}
```

---

### 2. GitHub (HTTPS — for SCM checkout and API)

**Authentication:** Username + Personal Access Token (PAT)

**Generate token:** `GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)`

Scopes needed: `repo`, `read:org` (add `workflow` if triggering GitHub Actions)

**Add to Jenkins:**
```
Kind:     Username with password
Username: your-github-username
Password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← PAT
ID:       github-creds
```

**Used automatically** by Jenkins when checking out a private repo via HTTPS URL. In Jenkinsfile:
```groovy
checkout scmGit(
    branches: [[name: 'main']],
    userRemoteConfigs: [[
        url: 'https://github.com/your-org/your-repo.git',
        credentialsId: 'github-creds'
    ]]
)
```

---

### 3. GitHub (SSH — for Git operations via SSH URL)

**Authentication:** SSH private key

**Generate key pair on your machine:**
```bash
ssh-keygen -t ed25519 -C "jenkins@your-domain.com" -f ~/.ssh/jenkins_github
# Generates: jenkins_github (private) and jenkins_github.pub (public)
```

**Add public key to GitHub:** `GitHub → Settings → SSH and GPG keys → New SSH key` → paste `jenkins_github.pub`

**Add private key to Jenkins:**
```
Kind:        SSH Username with private key
Username:    git
Private Key: ← paste contents of jenkins_github (private key)
ID:          github-ssh
```

**Use SSH repo URL in your Jenkins job:** `git@github.com:your-org/your-repo.git`

---

### 4. SonarQube

**Authentication:** Single token — no username required

**Generate token:** `SonarQube UI → My Account → Security → Generate Token`

Token type: `User Token` (or `Project Analysis Token` for project-scoped access)

**Add to Jenkins:**
```
Kind:    Secret text
Secret:  squ_xxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← SonarQube token
ID:      sonarqube-token
```

**SonarQube server URL** is configured separately — not in Credentials:
```
Manage Jenkins → System → SonarQube servers → Add SonarQube
  Name:           SonarQube
  Server URL:     http://localhost:9000   (or your SonarQube server address)
  Server auth token: sonarqube-token     ← select the credential ID above
```

**In Jenkinsfile:**
```groovy
environment {
    SONAR_TOKEN = credentials('sonarqube-token')
}

stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {   // must match name in Jenkins System config
            sh 'mvn sonar:sonar -Dsonar.token=$SONAR_TOKEN'
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

---

### 5. Nexus

Nexus is used for two purposes: **pulling dependencies** (Maven reads from Nexus instead of Maven Central) and **pushing build artifacts** (JARs, Docker images).

**Authentication:** Username + Password

**Best practice:** Create a dedicated `ci-user` in Nexus with only the permissions your pipeline needs (not the `admin` account).

**Add to Jenkins:**
```
Kind:     Username with password
Username: ci-user                  ← dedicated CI user in Nexus
Password: your-nexus-password
ID:       nexus-creds
```

**For Maven artifact push** — credentials go into `settings.xml`, not directly in Jenkinsfile:

```xml
<!-- settings.xml (committed to repo or placed on Jenkins server) -->
<settings>
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASS}</password>
    </server>
  </servers>
</settings>
```

```groovy
withCredentials([usernamePassword(
    credentialsId: 'nexus-creds',
    usernameVariable: 'NEXUS_USER',
    passwordVariable: 'NEXUS_PASS'
)]) {
    sh 'mvn deploy -s settings.xml'
}
```

**For Docker image push to Nexus Docker registry:**
```groovy
withCredentials([usernamePassword(
    credentialsId: 'nexus-creds',
    usernameVariable: 'NEXUS_USER',
    passwordVariable: 'NEXUS_PASS'
)]) {
    sh '''
        echo $NEXUS_PASS | docker login nexus.your-domain.com:8082 \
          -u $NEXUS_USER --password-stdin
        docker push nexus.your-domain.com:8082/myapp:latest
    '''
}
```

---

### 6. AWS (ECR, S3, EKS)

**Authentication:** IAM Access Key ID + Secret Access Key

**Generate:** `AWS Console → IAM → Users → your-ci-user → Security credentials → Create access key`

**Best practice:** Create a dedicated IAM user for Jenkins with only the permissions it needs (not root or admin).

**Add to Jenkins** (requires [AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/)):
```
Kind:              AWS Credentials
Access Key ID:     AKIAIOSFODNN7EXAMPLE
Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ID:                aws-creds
```

**In Jenkinsfile:**
```groovy
withCredentials([[
    $class: 'AmazonWebServicesCredentialsBinding',
    credentialsId: 'aws-creds'
]]) {
    sh '''
        aws ecr get-login-password --region us-east-1 \
          | docker login --username AWS --password-stdin \
            123456789.dkr.ecr.us-east-1.amazonaws.com
        docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
    '''
}
```

---

### 7. Kubernetes (kubeconfig)

**Authentication:** The entire kubeconfig file — contains cluster endpoint, CA cert, and user token all in one file.

**Get the file:**
```bash
cat ~/.kube/config   # on the machine that has kubectl access to your cluster
```

**Add to Jenkins:**
```
Kind:     Secret file
File:     ← upload your kubeconfig file
ID:       kubeconfig
```

**In Jenkinsfile:**
```groovy
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh 'kubectl apply -f k8s/deployment.yaml'
    sh 'kubectl rollout status deployment/myapp -n production'
    sh 'helm upgrade --install myapp ./charts/myapp --namespace production'
}
```

> The `KUBECONFIG` environment variable is the standard way `kubectl` and `helm` find cluster configuration. Setting it to the temp file path Jenkins creates is all that is needed.

---

## Complete Credentials Reference

| Service | Credential Kind | Recommended ID | Where to Generate |
|---|---|---|---|
| Docker Hub | Username with password | `dockerhub-creds` | hub.docker.com → Security → Access Tokens |
| GitHub (HTTPS) | Username with password | `github-creds` | GitHub → Settings → Developer settings → PAT |
| GitHub (SSH) | SSH Username with private key | `github-ssh` | `ssh-keygen` locally, public key added to GitHub |
| SonarQube | Secret text | `sonarqube-token` | SonarQube → My Account → Security → Generate Token |
| Nexus | Username with password | `nexus-creds` | Nexus → Security → Users |
| AWS | AWS Credentials | `aws-creds` | AWS IAM → Users → Security credentials |
| Kubernetes | Secret file | `kubeconfig` | `~/.kube/config` on your cluster admin machine |

---

## Security Best Practices

- **Never hardcode** any credential in a Jenkinsfile or commit it to Git
- **Use dedicated service accounts** for CI — never use personal accounts or root/admin credentials
- **Limit permissions** — each credential should have only the permissions the pipeline actually needs
- **Rotate tokens regularly** — especially after team member changes
- **Use Access Tokens instead of passwords** wherever the service supports it (Docker Hub, GitHub) — tokens can be scoped and revoked independently
- Jenkins **automatically masks** credential values in build logs — they appear as `****`
