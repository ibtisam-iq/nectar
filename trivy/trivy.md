# Trivy Usage Guide

Trivy is a comprehensive and versatile security scanner. It has scanners that look for security issues and targets where it can find those issues. This guide will walk you through the installation, configuration, and usage of Trivy for scanning folders and Docker images.

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
    - [Ubuntu](#ubuntu)
    - [Docker](#docker)
3. [Trivy Scanners](#trivy-scanners)
4. [Trivy Targets](#trivy-targets)
5. [Usage](#usage)
    - [Folder Scan](#folder-scan)
    - [Docker Image Scan](#docker-image-scan)
    - [Remote Git Repository Scan](#remote-git-repository-scan)
    - [Kubernetes Cluster Scan](#kubernetes-cluster-scan)
    - [Configuration](#configuration)
6. [Important Flags](#important-flags)
6. [References](#references)

---

## Introduction

Trivy is a powerful vulnerability scanner for containers and filesystems. It supports most popular programming languages, operating systems, and platforms. For a complete list, see the [Scanning Coverage](https://trivy.dev/latest/docs/coverage/) page.

---

## Installation

### Ubuntu

1. **Install Prerequisites**:
    ```bash
    sudo apt-get install wget gnupg
    ```

2. **Add Trivy Repository**:
    ```bash
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    ```

3. **Install Trivy**:
    ```bash
    sudo apt-get update
    sudo apt-get install trivy
    ```

### Docker

1. **Run Trivy Docker Image**:
    ```bash
    docker run aquasec/trivy image python:3.4-alpine
    ```
---

Trivy has scanners that look for security issues, and targets where it can find those issues.

## Trivy Scanners

Trivy can find the following security issues:

- **OS packages and software dependencies in use (SBOM)**
- **Known vulnerabilities (CVEs)**
- **IaC issues and misconfigurations**
- **Sensitive information and secrets**
- **Software licenses**

---

## Trivy Targets

Trivy can scan the following targets:

- **Container Image**
- **Filesystem**
- **Git Repository (remote)**
- **Virtual Machine Image**
- **Kubernetes**

---

## Usage

### Folder Scan
```
Usage:
  trivy filesystem [flags] PATH

Aliases:
  filesystem, fs
```
To scan a folder or directory for vulnerabilities, use the following command:

```bash
trivy fs path/to/scan
```

To save the scan result in HTML format, use the --format and -o options:

```bash
trivy fs --format html -o result.html /path/to/scan
```

You can also specify the types of security checks to perform using the --security-checks option:

```bash
trivy fs --format html -o result.html --security-checks vuln,config path_to_scan
```

### Docker Image Scan

```
Usage:
  trivy image [flags] IMAGE_NAME

Aliases:
  image, i

Examples:
  # Scan a container image
  $ trivy image python:3.4-alpine

  # Scan a container image from a tar archive
  $ trivy image --input ruby-3.1.tar

  # Filter by severities
  $ trivy image --severity HIGH,CRITICAL alpine:3.15

  # Ignore unfixed/unpatched vulnerabilities
  $ trivy image --ignore-unfixed alpine:3.15

  # Scan a container image in client mode
  $ trivy image --server http://127.0.0.1:4954 alpine:latest

  # Generate json result
  $ trivy image --format json --output result.json alpine:3.15

  # Generate a report in the CycloneDX format
  $ trivy image --format cyclonedx --output result.cdx alpine:3.15
```

To scan a Docker image for vulnerabilities, use the following command:

```bash
trivy image my_image:latest
```

To save the scan result in HTML format, use the -f and -o options:

```bash
trivy image -f html -o results.html my_image:latest
```

You can specify the severity levels of vulnerabilities to include in the report using the --severity option:

```bash
trivy image -f html -o results.html --severity HIGH,CRITICAL my_image:latest
```

### Remote Git Repository Scan
```
Usage:
  trivy repository [flags] (REPO_PATH | REPO_URL)

Aliases:
  repository, repo
```
To scan a remote Git repository for vulnerabilities, use the following command:

```bash
trivy repo https://github.com/ibtisamops/3TierFullStackApp-Flask-Postgres.git
```

### Kubernetes Cluster Scan
To scan a Kubernetes cluster for vulnerabilities, use the following command:
```bash
trivy cluster --namespace default --image my_image:latest
```

### Configuration File
You can specify a configuration file using the -c option. The configuration file should contain the following format:
```yaml
trivy: 
security-checks:
    - vuln
    - config
```    
---

## Important Flags

```bash
-f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
-o, --output string              output file name
--security-checks strings        security checks to perform (vuln,config,license,secret,osv) (default "vuln")
-s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
--config-file string             path to the configuration file
-c, --config string             config path (default "trivy.yaml")
-d, --debug                     debug mode
```

---

## References

- [Installation](https://trivy.dev/latest/getting-started/installation/)
- [GitHub](https://github.com/aquasecurity/trivy)
- [Docker Hub](https://hub.docker.com/r/aquasec/trivy)
- [Docs](https://trivy.dev/latest/docs/)

---

This guide provides a comprehensive overview of Trivy, its installation, and usage for scanning folders and Docker images. For more detailed instructions, refer to the official Trivy documentation.