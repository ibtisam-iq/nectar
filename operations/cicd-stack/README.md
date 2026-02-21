# Self-Hosted CI/CD Stack on iximiuz Labs

Complete production-grade CI/CD infrastructure running on iximiuz Labs MiniLAN playground.

## Architecture Overview

**Playground 1: CI/CD Services (4 nodes)**

- node-01: Jenkins (CI/CD Orchestration)
- node-02: SonarQube (Code Quality & Security)
- node-03: Nexus Repository (Artifact Management)
- node-04: Reserved (Future expansion)

## Setup Guides

1. [Jenkins Server Setup](01-jenkins-setup.md)
2. [SonarQube Server Setup](02-sonarqube-setup.md)
3. [Nexus Repository Setup](03-nexus-setup.md)

## Public Access

- Jenkins: https://jenkins.ibtisam-iq.com
- SonarQube: https://sonar.ibtisam-iq.com
- Nexus: https://nexus.ibtisam-iq.com
- Docker Registry: https://docker.ibtisam-iq.com:5000
