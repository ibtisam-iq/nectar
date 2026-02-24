#!/bin/bash
set -euo pipefail

#######################################################################
# Health Check Script
#
# This script performs comprehensive health checks on the Jenkins
# rootfs image to ensure all components are properly installed.
#
# NOTE: This script runs at BUILD TIME inside Docker.
# - systemd is NOT running during build
# - Services are checked via filesystem symlinks, not systemctl
# - Package checks use dpkg-query (reliable after apt list cleanup)
#
# Usage:
#   ./healthcheck.sh
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter for failures
FAILURES=0

echo -e "${BLUE}===============================${NC}"
echo -e "${BLUE}Running Health Checks${NC}"
echo -e "${BLUE}===============================${NC}"
echo ""

# Function to check command existence
check_command() {
    local cmd="${1}"
    local name="${2:-${cmd}}"

    if command -v "${cmd}" &> /dev/null; then
        echo -e "${GREEN}✓${NC} ${name}: $("${cmd}" --version 2>&1 | head -n 1)"
        return 0
    else
        echo -e "${RED}✗${NC} ${name}: Not found"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Function to check file existence
check_file() {
    local file="${1}"
    local name="${2:-${file}}"

    if [ -f "${file}" ]; then
        echo -e "${GREEN}✓${NC} File exists: ${name}"
        return 0
    else
        echo -e "${RED}✗${NC} File missing: ${name}"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Function to check directory existence
check_directory() {
    local dir="${1}"
    local name="${2:-${dir}}"

    if [ -d "${dir}" ]; then
        echo -e "${GREEN}✓${NC} Directory exists: ${name}"
        return 0
    else
        echo -e "${RED}✗${NC} Directory missing: ${name}"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Function to check systemd service (build-time symlink check)
check_service() {
    local service="${1}"
    local wants_link="/etc/systemd/system/multi-user.target.wants/${service}.service"
    local unit_file="/etc/systemd/system/${service}.service"
    local lib_unit="/lib/systemd/system/${service}.service"

    if [ -L "${wants_link}" ] || [ -f "${unit_file}" ] || [ -f "${lib_unit}" ]; then
        echo -e "${GREEN}✓${NC} Systemd service configured: ${service}"
        return 0
    else
        echo -e "${RED}✗${NC} Systemd service missing: ${service}"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Function to check user existence
check_user() {
    local username="${1}"

    if id "${username}" &>/dev/null; then
        echo -e "${GREEN}✓${NC} User exists: ${username} (UID: $(id -u "${username}"))"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} User not found: ${username} (will be created at runtime)"
        return 0
    fi
}

# Function to check debian package installation
check_package() {
    local pkg="${1}"
    local name="${2:-${pkg}}"

    if dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "install ok installed"; then
        local version
        version=$(dpkg-query -W -f='${Version}' "${pkg}" 2>/dev/null)
        echo -e "${GREEN}✓${NC} ${name} package: Installed (${version})"
        return 0
    else
        echo -e "${RED}✗${NC} ${name} package: Not installed"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

echo -e "${BLUE}[1] Checking System Tools${NC}"
echo "-----------------------------------"
check_command curl "cURL"
check_command wget "wget"
check_command git "Git"
check_command vim "Vim"
check_command nginx "Nginx"
echo ""

echo -e "${BLUE}[2] Checking Java Installation${NC}"
echo "-----------------------------------"
# Ensure JAVA_HOME is exported for the check
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
check_command java "Java Runtime"
check_command javac "Java Compiler"

if [ -n "${JAVA_HOME:-}" ]; then
    echo -e "${GREEN}✓${NC} JAVA_HOME: ${JAVA_HOME}"
else
    echo -e "${RED}✗${NC} JAVA_HOME: Not set"
    FAILURES=$((FAILURES + 1))
fi
echo ""

echo -e "${BLUE}[3] Checking Jenkins Installation${NC}"
echo "-----------------------------------"
check_package "jenkins" "Jenkins"
check_directory "/var/lib/jenkins" "Jenkins home"
check_directory "/var/lib/jenkins/plugins" "Jenkins plugins directory"
check_user "jenkins"  # Fixed daemon user created by package
echo ""

echo -e "${BLUE}[4] Checking Nginx Configuration${NC}"
echo "-----------------------------------"
check_file "/etc/nginx/sites-available/jenkins" "Nginx Jenkins config"

if [ -L /etc/nginx/sites-enabled/jenkins ]; then
    echo -e "${GREEN}✓${NC} Nginx Jenkins site: Enabled"
else
    echo -e "${RED}✗${NC} Nginx Jenkins site: Not enabled"
    FAILURES=$((FAILURES + 1))
fi

if [ ! -f /etc/nginx/sites-enabled/default ]; then
    echo -e "${GREEN}✓${NC} Nginx default site: Removed"
else
    echo -e "${YELLOW}⚠${NC} Nginx default site: Still present"
fi

if nginx -t &>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx configuration: Valid"
else
    echo -e "${RED}✗${NC} Nginx configuration: Invalid"
    FAILURES=$((FAILURES + 1))
fi
echo ""

echo -e "${BLUE}[5] Checking Systemd Services${NC}"
echo "-----------------------------------"
check_service "ssh"
check_service "nginx"
check_service "jenkins"
echo ""

echo -e "${BLUE}[6] Checking SSH Configuration${NC}"
echo "-----------------------------------"
check_file "/etc/ssh/sshd_config" "SSH daemon config"
check_file "/usr/sbin/sshd" "SSH daemon binary"

if ls /etc/ssh/ssh_host_*_key 1> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} SSH host keys: Present"
else
    echo -e "${YELLOW}⚠${NC} SSH host keys: Not generated (will be created at boot)"
fi
echo ""

echo -e "${BLUE}[7] Checking User Configuration${NC}"
echo "-----------------------------------"
# Interactive/lab user is dynamic (passed from Dockerfile ENV INTERACTIVE_USER=${USERNAME})
INTERACTIVE_USER="${INTERACTIVE_USER:-ubuntu}"
check_user "${INTERACTIVE_USER}"

# Daemon user sudoers (fixed name)
if [ -f /etc/sudoers.d/jenkins-user ]; then
    echo -e "${GREEN}✓${NC} Sudo configuration for jenkins daemon: Present"
else
    echo -e "${YELLOW}⚠${NC} Sudo configuration for jenkins daemon: Not found"
fi

# Interactive user sudoers (dynamic name from ARG)
if [ -f "/etc/sudoers.d/${INTERACTIVE_USER}" ]; then
    echo -e "${GREEN}✓${NC} Sudo configuration for interactive user (${INTERACTIVE_USER}): Present"
else
    echo -e "${YELLOW}⚠${NC} Sudo configuration for interactive user (${INTERACTIVE_USER}): Not found"
fi
echo ""

echo -e "${BLUE}[8] Checking File Permissions${NC}"
echo "-----------------------------------"
if [ -d /var/lib/jenkins ]; then
    JENKINS_OWNER=$(stat -c '%U' /var/lib/jenkins)
    if [ "${JENKINS_OWNER}" = "jenkins" ]; then
        echo -e "${GREEN}✓${NC} Jenkins home ownership: Correct (jenkins)"
    else
        echo -e "${RED}✗${NC} Jenkins home ownership: Incorrect (${JENKINS_OWNER})"
        FAILURES=$((FAILURES + 1))
    fi
fi
echo ""

# Final summary
echo -e "${BLUE}===============================${NC}"
if [ ${FAILURES} -eq 0 ]; then
    echo -e "${GREEN}✓ All health checks passed!${NC}"
    echo -e "${BLUE}===============================${NC}"
    exit 0
else
    echo -e "${RED}✗ ${FAILURES} health check(s) failed${NC}"
    echo -e "${BLUE}===============================${NC}"
    exit 1
fi
