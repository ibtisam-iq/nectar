#!/bin/bash
set -euo pipefail

#######################################################################
# Jenkins Installation Script
#
# This script installs Jenkins LTS or Weekly on Ubuntu.
#
# Usage:
#   ./install-jenkins.sh [VERSION]
#
# Arguments:
#   VERSION - Jenkins version (lts or weekly) - default: lts
#
# Author: Muhammad Ibtisam
#######################################################################

JENKINS_VERSION=${1:-lts}
JENKINS_PORT=${2:-8080}

echo "===================================="
echo "Installing Jenkins ${JENKINS_VERSION}"
echo "===================================="

# Validate Jenkins version
if [[ ! "${JENKINS_VERSION}" =~ ^(lts|weekly)$ ]]; then
    echo "ERROR: Invalid Jenkins version: ${JENKINS_VERSION}"
    echo "Valid options: lts, weekly"
    exit 1
fi

echo "Installing Java 21"
apt-get update
apt-get install -y --no-install-recommends fontconfig openjdk-21-jdk
java -version

# Determine repository based on version
if [ "${JENKINS_VERSION}" = "lts" ]; then
    JENKINS_REPO="https://pkg.jenkins.io/debian-stable"
    echo "Using stable (LTS) repository"
else
    JENKINS_REPO="https://pkg.jenkins.io/debian"
    echo "Using weekly repository"
fi

# Add Jenkins repository GPG key
echo "Adding Jenkins GPG key..."
wget -q -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins APT repository
echo "Adding Jenkins repository..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] ${JENKINS_REPO} binary/" \
    > /etc/apt/sources.list.d/jenkins.list

# Update package index
echo "Updating package index..."
apt-get update

# Install Jenkins
echo "Installing Jenkins..."
apt-get install -y --no-install-recommends jenkins

# Create Jenkins home directory if not exists
echo "Setting up Jenkins home directory..."
mkdir -p /var/lib/jenkins
chown -R jenkins:jenkins /var/lib/jenkins
chmod -R 755 /var/lib/jenkins

# Pre-create plugins directory
mkdir -p /var/lib/jenkins/plugins
chown -R jenkins:jenkins /var/lib/jenkins/plugins

# Create workspace directory
mkdir -p /var/lib/jenkins/workspace
chown -R jenkins:jenkins /var/lib/jenkins/workspace

# Create .ssh directory
mkdir -p /var/lib/jenkins/.ssh
chown jenkins:jenkins /var/lib/jenkins/.ssh
chmod -R 700 /var/lib/jenkins/.ssh

# Create logs directory
mkdir -p /var/log/jenkins
chown -R jenkins:jenkins /var/log/jenkins

# Verify Jenkins user and group
echo "Verifying Jenkins user..."
id jenkins

echo ""
echo "✓ Jenkins installed successfully"
echo "  Version: $(dpkg -l | grep jenkins | awk '{print $3}')"
echo "  Home: /var/lib/jenkins"
echo "  User: jenkins"
echo "  Group: jenkins"

# Set Jenkins HTTP port in defaults file
# This is the single source of truth — read by both the wrapper
echo "Configuring Jenkins port..."
if [ -f /etc/default/jenkins ]; then
    sed -i "s/^HTTP_PORT=.*/HTTP_PORT=${JENKINS_PORT}/" /etc/default/jenkins
    echo "✓ Jenkins port set to ${JENKINS_PORT}"
else
    echo "HTTP_PORT=${JENKINS_PORT}" >> /etc/default/jenkins
    echo "✓ Created /etc/default/jenkins with port ${JENKINS_PORT}"
fi
