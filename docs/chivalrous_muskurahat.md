## Infra Server
```bash
#!/bin/bash
echo "Updating system packages..."
sudo apt update > /dev/null 2>&1
echo "Installing essential tools..."
sudo apt install -y python3-pip tree wget curl gnupg ca-certificates > /dev/null 2>&1
echo -e "The system is up to date now.\n"

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip > /dev/null 2>&1
unzip awscliv2.zip > /dev/null 2>&1
sudo ./aws/install
rm -rf aws awscliv2.zip aws
echo -e "AWS CLI is installed and it's version is:\n$(aws --version)"

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure
echo -e "AWS CLI is configured.\n"

# Install Terraform
echo "Installing Terraform..."
sudo apt update && sudo apt install -y gnupg software-properties-common > /dev/null 2>&1

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y terraform > /dev/null 2>&1
echo -e "Terraform is installed and it's version is:\n$(terraform --version)"

# Install Ansible
echo "Installing Ansible..."
sudo apt update && sudo apt install -y software-properties-common > /dev/null 2>&1
sudo add-apt-repository --yes --update ppa:ansible/ansible > /dev/null
sudo apt update && sudo apt install -y ansible > /dev/null 2>&1
echo -e "Ansible is installed and it's version is:\n$(ansible --version)"

# Install Kubectl
echo "Installing Kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -rf kubectl kubectl.sha256
echo -e "Kubectl is installed and it's version is:\n$(kubectl version --client)"

# Install ekctl
echo "Installing ekctl..."
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
rm -rf eksctl_.tar.gz 
echo -e "ekctl is installed and it's version is:\n$(eksctl version)"

# Install Helm
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
echo -e "Helm is installed and it's version is:\n$(helm version)"

echo -e "Infra Server is set up now.\n"
```

## Jenkins Server

```bash
#!/bin/bash
echo "Updating system packages..."
sudo apt update > /dev/null 2>&1
echo "Installing essential tools..."
sudo apt install -y python3-pip tree wget curl gnupg ca-certificates > /dev/null 2>&1
echo -e "The system is up to date now.\n"

# Install Jenkins
echo "Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key > /dev/null 2>&1
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
echo "Updating system packages to install Jenkins..."
sudo apt update > /dev/null 2>&1
sudo apt install openjdk-17-jre-headless jenkins -y > /dev/null 2>&1
echo "Jenkins Version: $(dpkg -l | grep jenkins | awk '{print $3}')"
sudo systemctl enable jenkins > /dev/null 2>&1
sudo systemctl restart jenkins > /dev/null 2>&1
if systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins is running."
else
    echo "❌ Jenkins is NOT running. Starting Jenkins..."
    sudo systemctl start jenkins
fi
Please put the password to unlock Jenkins: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Install Docker
echo "Installing Docker..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y ca-certificates curl > /dev/null 2>&1
sudo install -m 0755 -d /etc/apt/keyrings 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins > /dev/null 2>&1
echo "Docker version: $(docker --version | awk '{print $3}' | sed 's/,//')"
if systemctl is-active --quiet docker; then
    echo "✅ Docker is running."
else
    echo "❌ Docker is NOT running. Starting Docker..."
    sudo systemctl start docker
fi

# Install Trivy
echo "Installing Trivy..."
sudo apt install -y wget gnupg > /dev/null 2>&1
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update > /dev/null 2>&1
sudo apt install trivy -y > /dev/null 2>&1
echo "Trivy version: $(trivy --version)"

# Install Kubectl
echo "Installing Kubectl..."
# KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -rf kubectl kubectl.sha256
echo "Kubectl version: $(kubectl version --client --output=yaml)"

echo "✅ All tools installed successfully!"
```

## SonarQube Server

```bash
#!/bin/bash
echo "Updating system packages..."
sudo apt update > /dev/null 2>&1
echo "Installing essential tools..."
sudo apt install -y python3-pip tree wget curl openjdk-17-jdk-headless > /dev/null 2>&1
echo -e "The system is up to date now.\n"

# Install Docker
echo "Installing Docker..."
sudo apt update > /dev/null 2>&1
sudo apt install -y ca-certificates curl > /dev/null 2>&1
sudo install -m 0755 -d /etc/apt/keyrings 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
sudo usermod -aG docker $USER
echo "Docker version: $(docker --version | awk '{print $3}' | sed 's/,//')"
if systemctl is-active --quiet docker; then
    echo "✅ Docker is running."
else
    echo "❌ Docker is NOT running. Starting Docker..."
    sudo systemctl start docker
fi
echo -e "SonarQube Server is being set up through Docker.\n"
# newgrp docker
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
```

## Nexus Server

```bash
#!/bin/bash
echo "Updating system packages..."
sudo apt update > /dev/null 2>&1
echo "Installing essential tools..."
sudo apt install -y python3-pip tree wget curl openjdk-17-jdk-headless > /dev/null 2>&1
echo -e "The system is up to date now.\n"

# Install Docker
echo "Installing Docker..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y ca-certificates curl > /dev/null 2>&1
sudo install -m 0755 -d /etc/apt/keyrings 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
sudo usermod -aG docker $USER
echo "Docker version: $(docker --version | awk '{print $3}' | sed 's/,//')"
if systemctl is-active --quiet docker; then
    echo "✅ Docker is running."
else
    echo "❌ Docker is NOT running. Starting Docker..."
    sudo systemctl start docker
fi
echo -e "Nexus Server is being set up through Docker.\n"
# newgrp docker
docker run -d --name nexus -p 8081:8081 sonatype/nexus3
Please put the password to unlock Nexus: $(docker exec nexus cat /nexus-data/admin.password)
```




### Additional Commands
`grep -rl 'ap-south-1' . | xargs -d '\n' sed -i 's/ap-south-1/us-east-1/g'`


















