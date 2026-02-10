#!/bin/bash
# Script to create all .pages files for remaining directories with human-readable titles

#####################################
# CLOUD INFRASTRUCTURE
#####################################

# Create cloud-infrastructure/.pages
cat > cloud-infrastructure/.pages << 'EOF'
title: Cloud & Infrastructure
nav:
  - aws
  - cloudflare
  - github-pages
EOF

# Create cloud-infrastructure/aws/.pages
cat > cloud-infrastructure/aws/.pages << 'EOF'
title: AWS (Amazon Web Services)
nav:
  - Introduction: introduction.md
  - AWS Overview: AWS.md
  - IAM (Identity and Access Management): iam.md
  - Identity Center: identity-center.md
  - ARN (Amazon Resource Names): arn.md
  - Policies: policies.md
  - Console Output: consoleOutput.txt
EOF

# Create cloud-infrastructure/cloudflare/.pages
cat > cloud-infrastructure/cloudflare/.pages << 'EOF'
title: Cloudflare
nav:
  - Home: README.md
  - Cloudflare Gmail Domain Email Setup: cloudflare-gmail-domain-email-setup.md
EOF

# Create cloud-infrastructure/github-pages/.pages
cat > cloud-infrastructure/github-pages/.pages << 'EOF'
title: GitHub Pages
nav:
  - Custom Domain Setup: custom-domain-setup.md
EOF

#####################################
# DELIVERY (CI/CD)
#####################################

# Create delivery/.pages
cat > delivery/.pages << 'EOF'
title: CI/CD & Software Delivery
nav:
  - git
  - github-actions
  - jenkins
  - nexus
  - sonarqube
EOF

# Create delivery/git/.pages
cat > delivery/git/.pages << 'EOF'
title: Git
nav:
  - Git Guide: Git.md
  - Git Cheat Sheet: gitCheatSheet.md
  - Troubleshooting: troubleshooting.md
EOF

# Create delivery/github-actions/.pages
cat > delivery/github-actions/.pages << 'EOF'
title: GitHub Actions
nav:
  - MkDocs Projects Deployment: MkDocs-projects-deployment.md
  - Permissions: permissions.md
EOF

# Create delivery/jenkins/.pages
cat > delivery/jenkins/.pages << 'EOF'
title: Jenkins
nav:
  - Overview: overview.md
  - Jenkins Guide: Jenkins.md
  - New Item: new item.md
  - Jenkinsfile: Jenkinsfile.md
  - Parameters and Variables: params_and_var.md
  - Shared Library: shared_lib.md
  - Slave Setup: slave_setup.md
  - Webhook Setup: webhook_setup.md
  - Security: security.md
  - Mail Configuration: mail_conf.md
  - Plugins List: plugins.txt
  - Troubleshooting: troubleshooting.md
EOF

# Create delivery/nexus/.pages
cat > delivery/nexus/.pages << 'EOF'
title: Nexus Repository Manager
nav:
  - Nexus Overview: Nexus.md
  - Proxy Repository: proxy_repo.md
  - Nexus with Docker: nexus_docker.md
  - Nexus with Jenkins: nexus_jenkins.md
  - Artifact Downloading: artifact_downloading.md
EOF

# Create delivery/sonarqube/.pages
cat > delivery/sonarqube/.pages << 'EOF'
title: SonarQube
nav:
  - Overview: overview.md
  - SonarQube Guide: SonarQube.md
  - Local Setup: local_setup.md
  - Properties Configuration: properties.md
  - SonarQube with Jenkins: sonar_jenkins.md
  - Code Coverage: coverage.md
  - Troubleshooting: troubleshooting.md
EOF

#####################################
# OBSERVABILITY & SECURITY
#####################################

# Create observability-security/.pages
cat > observability-security/.pages << 'EOF'
title: Observability & Security
nav:
  - trivy
EOF

# Create observability-security/trivy/.pages
cat > observability-security/trivy/.pages << 'EOF'
title: Trivy (Security Scanner)
nav:
  - Trivy Guide: Trivy.md
EOF

#####################################
# OPERATIONS
#####################################

# Create operations/.pages
cat > operations/.pages << 'EOF'
title: Operations & Self-Managed Systems
nav:
  - Home: README.md
  - wireguard
EOF

# Create operations/wireguard/.pages
cat > operations/wireguard/.pages << 'EOF'
title: WireGuard VPN
nav:
  - Home: README.md
EOF

#####################################
# SCRATCHPAD
#####################################

# Create scratchpad/.pages
cat > scratchpad/.pages << 'EOF'
title: Engineering Scratchpad
nav:
  - Home: README.md
  - ibtisam-iq Blueprint: ibtisam-iq blueprint.md
  - Chivalrous Muskurahat: chivalrous_muskurahat.md
  - Dual Boot Setup: dual-boot.md
  - MkDocs Troubleshooting: mkdocs-troubleshhoting.md
  - Bulk URL Change Script: bulk-url-change.sh
EOF

#####################################
# SERVERS
#####################################

# Create servers/.pages
cat > servers/.pages << 'EOF'
title: Servers & Runtime Systems
nav:
  - Home: README.md
  - nginx
  - tomcat
  - mysql
  - mariadb
  - postgresql
  - mongodb
EOF

# Create servers/nginx/.pages
cat > servers/nginx/.pages << 'EOF'
title: Nginx
nav:
  - Nginx Guide: Nginx.md
  - ibtisam-iq Configuration: ibtisam-iq.conf
  - Console Output: consoleOutput.txt
EOF

# Create servers/tomcat/.pages
cat > servers/tomcat/.pages << 'EOF'
title: Apache Tomcat
nav:
  - Tomcat Guide: Tomcat.md
EOF

# Create servers/mysql/.pages
cat > servers/mysql/.pages << 'EOF'
title: MySQL
nav:
  - MySQL Guide: MySQL.md
EOF

# Create servers/mariadb/.pages
cat > servers/mariadb/.pages << 'EOF'
title: MariaDB
nav:
  - MariaDB Guide: MariaDB.md
EOF

# Create servers/postgresql/.pages
cat > servers/postgresql/.pages << 'EOF'
title: PostgreSQL
nav:
  - PostgreSQL Guide: PostgreSQL.md
EOF

# Create servers/mongodb/.pages
cat > servers/mongodb/.pages << 'EOF'
title: MongoDB
nav:
  - MongoDB Guide: MongoDB.md
EOF

#####################################
# TECHNICAL GROUNDING
#####################################

# Create technical-grounding/.pages
cat > technical-grounding/.pages << 'EOF'
title: Technical Grounding
nav:
  - Home: README.md
  - basics
  - codebase-structures
  - linux
  - networking
  - bash
  - python
  - vim
  - yaml
  - dual-boot
EOF

# Create technical-grounding/basics/.pages
cat > technical-grounding/basics/.pages << 'EOF'
title: Basics
nav:
  - Index: index.md
  - SDLC (Software Development Life Cycle): SDLC.md
  - Programming Fundamentals: programming.md
  - Frameworks Overview: frameworks.md
  - Database Fundamentals: database.md
  - Understanding CLI Commands: understanding-CLI-commands.md
EOF

# Create technical-grounding/codebase-structures/.pages
cat > technical-grounding/codebase-structures/.pages << 'EOF'
title: Codebase Structures
nav:
  - Home: README.md
  - Java Project Structure: java.md
  - Node.js Project Structure: nodejs.md
  - Python Project Structure: python.md
  - .NET Project Structure: dotNet.md
EOF

# Create technical-grounding/linux/.pages
cat > technical-grounding/linux/.pages << 'EOF'
title: Linux
nav:
  - Linux Guide: Linux.md
  - Cheat Sheet: cheatSheet.md
  - STDOUT & STDERR Guide: STDOUT_STDERR_Guide.md
  - Tar Command: tar-command.md
  - Troubleshooting: troubleshooting.md
EOF

# Create technical-grounding/networking/.pages
cat > technical-grounding/networking/.pages << 'EOF'
title: Networking
nav:
  - Networking Basics: Networking.md
  - DNS Resolution with Curl: curl-dns-resolution.md
EOF

# Create technical-grounding/bash/.pages
cat > technical-grounding/bash/.pages << 'EOF'
title: Bash Scripting
nav:
  - Bash Script Notes: ibtisam.sh
EOF

# Create technical-grounding/python/.pages
cat > technical-grounding/python/.pages << 'EOF'
title: Python
nav:
  - Python Script Notes: ibtisam.py
EOF

# Create technical-grounding/vim/.pages
cat > technical-grounding/vim/.pages << 'EOF'
title: Vim Editor
nav:
  - Vimrc Guide: vimrc_guide.md
EOF

# Create technical-grounding/yaml/.pages
cat > technical-grounding/yaml/.pages << 'EOF'
title: YAML
nav:
  - Home: README.md
  - Detailed Example: detailed-example.md
  - Lists in YAML: list-in-yml.md
  - Dictionaries in YAML: dict-in-yml.md
  - Lists and Dictionaries: list-and-dict.md
  - Multi-line Strings in YAML: multi-line-strings-in-yml.md
EOF

# Create technical-grounding/dual-boot/.pages
cat > technical-grounding/dual-boot/.pages << 'EOF'
title: Dual Boot Setup
nav:
  - Dual Boot Pop OS and Windows: dual-boot-pop-os-windows.md
EOF

echo "✅ All .pages files created successfully with human-readable titles!"
echo ""
echo "Summary of created files:"
echo ""
echo "Cloud & Infrastructure:"
echo "  - cloud-infrastructure/.pages"
echo "  - cloud-infrastructure/aws/.pages"
echo "  - cloud-infrastructure/cloudflare/.pages"
echo "  - cloud-infrastructure/github-pages/.pages"
echo ""
echo "CI/CD & Software Delivery:"
echo "  - delivery/.pages"
echo "  - delivery/git/.pages"
echo "  - delivery/github-actions/.pages"
echo "  - delivery/jenkins/.pages"
echo "  - delivery/nexus/.pages"
echo "  - delivery/sonarqube/.pages"
echo ""
echo "Observability & Security:"
echo "  - observability-security/.pages"
echo "  - observability-security/trivy/.pages"
echo ""
echo "Operations:"
echo "  - operations/.pages"
echo "  - operations/wireguard/.pages"
echo ""
echo "Scratchpad:"
echo "  - scratchpad/.pages"
echo ""
echo "Servers & Runtime Systems:"
echo "  - servers/.pages"
echo "  - servers/nginx/.pages"
echo "  - servers/tomcat/.pages"
echo "  - servers/mysql/.pages"
echo "  - servers/mariadb/.pages"
echo "  - servers/postgresql/.pages"
echo "  - servers/mongodb/.pages"
echo ""
echo "Technical Grounding:"
echo "  - technical-grounding/.pages"
echo "  - technical-grounding/basics/.pages"
echo "  - technical-grounding/codebase-structures/.pages"
echo "  - technical-grounding/linux/.pages"
echo "  - technical-grounding/networking/.pages"
echo "  - technical-grounding/bash/.pages"
echo "  - technical-grounding/python/.pages"
echo "  - technical-grounding/vim/.pages"
echo "  - technical-grounding/yaml/.pages"
echo "  - technical-grounding/dual-boot/.pages"
echo ""
echo "Total: 33 new .pages files created"
echo "Combined with containers-orchestration: 53 total .pages files"
echo ""
echo "To verify all .pages files, run:"
echo "  find . -name '.pages' -type f | sort"
