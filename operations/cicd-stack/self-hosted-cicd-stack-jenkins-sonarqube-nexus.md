# Self-Hosted CI/CD Stack on iximiuz Labs

This document walks through every step I took to provision and configure my complete CI/CD infrastructure — Jenkins, SonarQube, and Nexus — running on custom domains with SSL, ready to execute production-grade DevSecOps pipelines.

---

## Stack Overview

| Service | URL | Purpose |
|---|---|---|
| Jenkins | `https://jenkins.ibtisam-iq.com` | CI/CD orchestrator |
| SonarQube | `https://sonar.ibtisam-iq.com` | Static code analysis & quality gate |
| Nexus | `https://nexus.ibtisam-iq.com` | Artifact repository (Maven, npm, Docker) |

All three run as separate nodes in an [iximiuz Labs](https://labs.iximiuz.com) playground environment, provisioned via a single manifest file.

---

## Phase 1 — Provision the Infrastructure

I use iximiuz Labs playgrounds as my lab environment. The full CI/CD stack (4 nodes: 1 dev machine, 1 Jenkins server, 1 SonarQube server, 1 Nexus server) is defined in a single manifest file and spun up with one command.

```bash
labctl playground create --base flexbox cicd-stack \
  -f iximiuz/manifests/cicd-stack.yml
```

The manifest is maintained in [SilverStack](https://github.com/ibtisam-iq/silver-stack/blob/main/iximiuz/manifests/cicd-stack.yml).

Each server node boots with systemd, Nginx as reverse proxy, and cloudflared pre-configured for instant SSL via Cloudflare Tunnel — so all three services are immediately accessible on their custom domains.

---

## Phase 2 — Jenkins Post-Setup

Once the Jenkins server was live at `https://jenkins.ibtisam-iq.com`, I ran two post-setup scripts that are pre-placed on the server's `PATH` during the image build.

### Step 1 — Install Pipeline Tools

This installs 10 CI/CD tools system-wide on the Jenkins server OS:

```bash
sudo install-pipeline-tools
```

Tools installed: Maven `3.9.15`, Node.js `22 LTS`, npm, Python `3.12`, Docker `29.x`, Trivy `0.69.3`, AWS CLI v2, kubectl `1.35`, Helm `4.1.4`, Terraform `1.14.x`, Ansible `core 2.20`.

All tools land on system `PATH` — no Jenkins UI configuration needed for these.

> See [tool-configuration.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/jenkins/tool-configuration.md) for the full explanation of why PATH-installed tools require no Jenkins UI config.

### Step 2 — Install Jenkins Plugins

After completing the Jenkins setup wizard (admin user created, Jenkins URL confirmed), I installed all required plugins via:

```bash
sudo install-plugins
```

The script prompts for Jenkins URL, username, and password, then installs a complete enterprise plugin set covering SCM, build tools, code quality, security scanning, artifact management, Docker, Kubernetes, notifications, and observability.

---

## Phase 3 — Jenkins Initial Configuration

### Step 3 — Unlock the Built-in Node

By default Jenkins restricts the built-in node from running jobs. I enabled it:

```
Manage Jenkins → Nodes → Built-In Node → Configure
  Number of executors: 2
```

### Step 4 — Set Jenkins URL

I verified the Jenkins URL is correctly set so that SonarQube webhooks and other callbacks resolve properly:

```
Manage Jenkins → System → Jenkins URL
  https://jenkins.ibtisam-iq.com/
```

---

## Phase 4 — Credentials

I added four credentials under:

```
Manage Jenkins → Credentials → System → Global credentials (unrestricted) → Add Credentials
```

### Credential 1 — SonarQube Token

Rather than using the default `admin` account, I created a dedicated user in SonarQube first:

```
SonarQube UI → Administration → Security → Users → Create User
  Login:    jenkins-ci
  Name:     Jenkins CI
  Password: <set a strong password>
```

Then I generated a token for that user:

```
SonarQube UI → My Account (as jenkins-ci) → Security → Generate Token
  Name:  jenkins-token
  Type:  User Token
```

Added to Jenkins:

```
Kind:    Secret text
Secret:  squ_xxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← token from SonarQube
ID:      sonarqube-token
```

### Credential 2 — GitHub

I used my GitHub Personal Access Token (PAT) as the password:

```
GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
  Scopes: repo, read:org, workflow
```

Added to Jenkins:

```
Kind:     Username with password
Username: ibtisam-iq
Password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← PAT
ID:       github-creds
```

### Credential 3 — Docker Hub

I used a Docker Hub Access Token (not my account password):

```
hub.docker.com → Account Settings → Security → New Access Token
  Name:   jenkins-ci
  Scopes: Read, Write
```

Added to Jenkins:

```
Kind:     Username with password
Username: mibtisam
Password: dckr_pat_xxxxxxxxxxxxxxxxxxxx   ← access token
ID:       docker-creds
```

### Credential 4 — Nexus

I created a dedicated CI user in Nexus rather than using the `admin` account:

```
Nexus UI → Security → Users → Create local user
  User ID:  jenkins-ci
  Password: <set a strong password>
  Roles:    nx-admin + nx-anonymous
```

Added to Jenkins:

```
Kind:     Username with password
Username: jenkins-ci
Password: <nexus password>
ID:       nexus-creds
```

### Add GHCR Credential to Jenkins

Later, I also added a separate credential for pushing to GitHub Container Registry (GHCR), using a GitHub PAT with `write:packages` scope:

```
Kind:     Username with password
Username: ibtisam-iq
Password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← PAT with write:packages scope
ID:       ghcr-creds
```

> Note: If your existing `github-creds` PAT already has `write:packages` scope, you can reuse it instead of creating a separate credential.

> See [credentials.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/jenkins/credentials.md) for the full deep-dive on credential types, injection methods, and security best practices.

---

## Phase 5 — Tool Configuration

### Step 5 — SonarQube Scanner

The only tool I configured in `Manage Jenkins → Tools` was the SonarQube Scanner. Unlike Maven, Docker, kubectl, etc. (which are plain binaries installed on the OS), the SonarQube Scanner cannot be installed directly on the server — it is managed exclusively through Jenkins:

```
Manage Jenkins → Tools → SonarQube Scanner installations → Add SonarQube Scanner
  Name:                 sonar-scanner
  Install automatically: ✓ checked
  Version:              SonarQube Scanner (latest)
```

All other tools (Maven, Node.js, Docker, Trivy, kubectl, Helm, Terraform, Ansible, AWS CLI) were **not** configured here because they are already installed on the OS PATH and Jenkins finds them automatically via shell resolution.

> Full reasoning in [tool-configuration.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/jenkins/tool-configuration.md).

---

## Phase 6 — System Configuration

### Step 6 — Add SonarQube Server

I configured the SonarQube server URL and linked the credential I created earlier:

```
Manage Jenkins → System → SonarQube servers → Add SonarQube
  Name:               sonar-server
  Server URL:         https://sonar.ibtisam-iq.com
  Server auth token:  sonarqube-token   ← the Secret Text credential ID
```

This is what allows `withSonarQubeEnv('sonar-server')` to work in pipelines.

> Reference: [sonar-jenkins.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/sonarqube/sonar-jenkins.md)

---

## Phase 7 — SonarQube Webhook

### Step 7 — Configure Webhook in SonarQube

For the `waitForQualityGate` step to work in Jenkins pipelines, SonarQube must notify Jenkins when analysis is complete. I configured this webhook in SonarQube:

```
SonarQube UI → Administration → Configuration → Webhooks → Create
  Name:   Jenkins
  URL:    https://jenkins.ibtisam-iq.com/sonarqube-webhook/
  Secret: (leave blank or set a shared secret for HMAC validation)
```

This webhook fires after every analysis and triggers the quality gate check in the Jenkins pipeline.

---

## Phase 8 — Nexus Maven Settings

### Step 8 — Configure `settings.xml` via Config File Provider

Maven needs credentials to push artifacts to Nexus. Rather than hardcoding them in the repo, I used the **Config File Provider** plugin to store a `settings.xml` inside Jenkins:

```
Manage Jenkins → Managed files → Add a new Config → Global Maven settings.xml
  ID:   maven-settings
```

Inside the file, I added the Nexus server credentials:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0
          https://maven.apache.org/xsd/settings-1.2.0.xsd">
  <servers>
    <server>
      <id>maven-releases</id>
      <username>jenkins-ci</username>
      <password>nexus-password</password>
    </server>
    <server>
      <id>maven-snapshots</id>
      <username>jenkins-ci</username>
      <password>nexus-password</password>
    </server>
  </servers>
</settings>
```

This `settings.xml` is then referenced in pipelines via `withMaven(globalMavenSettingsConfig: 'maven-settings')` — no credentials ever appear in the Jenkinsfile or source code.

> Reference: [nexus-jenkins.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/nexus/nexus-jenkins.md)

#### Troubleshooting: settings.xml — Two Common Mistakes

While setting this up, I ran into two issues that are easy to miss:

**Issue 1 — Missing XML document wrapper (bare `<servers>` block)**

The file must be a complete, valid XML document. A bare `<servers>...</servers>` block without the `<?xml ...?>` declaration and `<settings>` root element will be silently ignored by Maven, causing a 401 Unauthorized error when pushing to Nexus.

Wrong:
```xml
<servers>
  <server>...</server>
</servers>
```

Correct: the full structure shown above — `<?xml version="1.0"?>` + `<settings xmlns="...">` wrapper is mandatory.

**Issue 2 — Special characters in passwords must be XML-escaped**

If your Nexus password contains special characters (e.g. `&`, `<`, `>`, `"`, `'`), they must be escaped in the XML file or Maven will fail to parse the file entirely.

| Character | Escaped form |
|---|---|
| `&` | `&amp;` |
| `<` | `&lt;` |
| `>` | `&gt;` |
| `"` | `&quot;` |
| `'` | `&apos;` |

Example — password `P@ss&Word!` becomes:
```xml
<password>P@ss&amp;Word!</password>
```

---

## Phase 9 — Nexus Docker Registry

### Step 9 — Add a Docker (Hosted) Repository in Nexus

To push Docker images to Nexus from the pipeline, I created a dedicated Docker hosted repository. Nexus uses the **Docker Registry HTTP API v2** — a completely separate protocol from Maven — so it requires its own repository type.

```
Nexus UI → Settings → Repository → Repositories → Create repository → docker (hosted)
  Name:    docker-hosted
  Online:  ✓ checked
```

**Connector selection — Path based routing (no dedicated port needed):**

Because my Nexus server sits behind a Cloudflare Tunnel (all external traffic arrives on port 443 via Cloudflare → Nginx → Nexus on port 8081), I cannot expose an additional TCP port for Docker. Instead, I selected **Path based routing**:

```
Repository Connectors:
  ● Path based routing   ← selected this
  ○ Other Connectors

  HTTP:  (unchecked — no dedicated port)
  HTTPS: (unchecked — no dedicated port)
```

With path-based routing, Docker clients use the repository name in the URL path instead of a port:

```
# Push format:
docker push nexus.ibtisam-iq.com/docker-hosted/java-monolith:1.0.0

# Pull format:
docker pull nexus.ibtisam-iq.com/docker-hosted/java-monolith:1.0.0
```

### Step 10 — Enable Docker Bearer Token Realm

Docker login to Nexus requires the Bearer Token realm to be active. Without this, `docker login` will always return 401 even with correct credentials.

```
Nexus UI → Security → Realms
  Move "Docker Bearer Token Realm" from Available → Active
  Save
```

---

## Stack Ready

After completing all phases above, my CI/CD stack was fully operational:

| What | Status |
|---|---|
| Jenkins running with SSL | ✅ `https://jenkins.ibtisam-iq.com` |
| SonarQube running with SSL | ✅ `https://sonar.ibtisam-iq.com` |
| Nexus running with SSL | ✅ `https://nexus.ibtisam-iq.com` |
| 10 pipeline tools on Jenkins OS PATH | ✅ mvn, node, docker, trivy, kubectl, helm, terraform, ansible, aws |
| All Jenkins plugins installed | ✅ via `sudo install-plugins` |
| 5 credentials configured | ✅ sonarqube-token, github-creds, docker-creds, nexus-creds, ghcr-creds |
| SonarQube Scanner registered in Jenkins | ✅ `sonar-scanner` |
| SonarQube server linked to Jenkins | ✅ `sonar-server` |
| SonarQube webhook pointing to Jenkins | ✅ `/sonarqube-webhook/` |
| Nexus `settings.xml` in Config File Provider | ✅ `maven-settings` (full XML wrapper + escaped password) |
| Nexus Docker hosted repository | ✅ `docker-hosted` (path-based routing, no port) |
| Docker Bearer Token Realm active | ✅ Nexus Security → Realms |

The stack is now ready to execute any pipeline in this repository.

---

## Related Documentation

| Topic | File |
|---|---|
| Why most tools need no Jenkins UI config | [tool-configuration.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/jenkins/tool-configuration.md) |
| Credential types and injection methods | [credentials.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/jenkins/credentials.md) |
| SonarQube ↔ Jenkins integration detail | [sonar-jenkins.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/sonarqube/sonar-jenkins.md) |
| Nexus ↔ Jenkins integration detail | [nexus-jenkins.md](https://github.com/ibtisam-iq/nectar/blob/main/delivery/nexus/nexus-jenkins.md) |
| Jenkins server image (rootfs) | [silver-stack/jenkins](https://github.com/ibtisam-iq/silver-stack/tree/main/iximiuz/rootfs/jenkins) |
| Blog post: Self-Hosted CI/CD Lab | [blog.ibtisam-iq.com](https://blog.ibtisam-iq.com/self-hosted-cicd-lab-jenkins-sonarqube-nexus/) |
