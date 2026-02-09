- Git checkout
- Compile
- Unit test
- Package
- Trivy fs
- Code analysis
- Quality gate
- Deploy artifact to Nexus using Maven
- Build image
- Trivy image scan
- Push image to Docker Hub
- Deploy to Kubernetes

List of servers/pods
- Jenkins agent: This is where the build happens, and it's a pod that can be scaled up or down.
    - Docker and trivy, these are tools, and installed here.
- Jenkins server
- SonarQube
- Nexus
- Terraform & Ansible, these are also tools just to interact with cloud, and installed on any machine that can run them.
- Kubernetes cluster

