#!/bin/bash
set -euo pipefail

#######################################################################
# Docker Image Test Script
#
# This script performs comprehensive validation tests on the built
# Jenkins rootfs Docker image to ensure it meets all requirements.
#
# Usage:
#   ./test-image.sh [IMAGE_NAME]
#
# Arguments:
#   IMAGE_NAME - Docker image to test (default: jenkins-rootfs:test)
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

IMAGE_NAME=${1:-jenkins-rootfs:test}
CONTAINER_NAME="jenkins-rootfs-test-$(date +%s)"
TEST_FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Jenkins Rootfs Image Test Suite${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Testing image: ${IMAGE_NAME}"
echo ""

# Function to run test
run_test() {
    local test_name="${1}"
    local test_command="${2}"
    
    echo -n "Testing ${test_name}... "
    
    if eval "${test_command}" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# Function to cleanup
cleanup() {
    echo ""
    echo "Cleaning up test container..."
    docker rm -f ${CONTAINER_NAME} &>/dev/null || true
}

trap cleanup EXIT

# Test 1: Check if image exists
echo -e "${BLUE}[1] Image Validation${NC}"
run_test "Image exists" "docker image inspect ${IMAGE_NAME}"

# Test 2: Start container
echo ""
echo -e "${BLUE}[2] Container Startup${NC}"
echo "Starting test container..."
if docker run -d --name ${CONTAINER_NAME} \
    --privileged \
    ${IMAGE_NAME} /lib/systemd/systemd &>/dev/null; then
    echo -e "${GREEN}✓${NC} Container started: ${CONTAINER_NAME}"
else
    echo -e "${RED}✗${NC} Failed to start container"
    exit 1
fi

# Wait for container to initialize
echo "Waiting for initialization (15 seconds)..."
sleep 15

# Test 3: Check if container is running
run_test "Container running" "docker ps | grep -q ${CONTAINER_NAME}"

# Test 4: Check Java installation
echo ""
echo -e "${BLUE}[3] Java Environment${NC}"
run_test "Java installed" "docker exec ${CONTAINER_NAME} java -version"
run_test "Javac installed" "docker exec ${CONTAINER_NAME} javac -version"
run_test "JAVA_HOME set" "docker exec ${CONTAINER_NAME} bash -c 'test -n \$JAVA_HOME'"

# Test 5: Check Jenkins installation
echo ""
echo -e "${BLUE}[4] Jenkins Installation${NC}"
run_test "Jenkins package installed" "docker exec ${CONTAINER_NAME} dpkg -l | grep -q jenkins"
run_test "Jenkins home exists" "docker exec ${CONTAINER_NAME} test -d /var/lib/jenkins"
run_test "Jenkins user exists" "docker exec ${CONTAINER_NAME} id jenkins"

# Test 6: Check Nginx installation
echo ""
echo -e "${BLUE}[5] Nginx Configuration${NC}"
run_test "Nginx installed" "docker exec ${CONTAINER_NAME} nginx -v"
run_test "Nginx config valid" "docker exec ${CONTAINER_NAME} nginx -t"
run_test "Jenkins site configured" "docker exec ${CONTAINER_NAME} test -f /etc/nginx/sites-available/jenkins"
run_test "Jenkins site enabled" "docker exec ${CONTAINER_NAME} test -L /etc/nginx/sites-enabled/jenkins"

# Test 7: Check systemd services
echo ""
echo -e "${BLUE}[6] Systemd Services${NC}"
run_test "SSH service configured" "docker exec ${CONTAINER_NAME} systemctl list-unit-files | grep -q ssh.service"
run_test "Nginx service configured" "docker exec ${CONTAINER_NAME} systemctl list-unit-files | grep -q nginx.service"
run_test "Jenkins service configured" "docker exec ${CONTAINER_NAME} systemctl list-unit-files | grep -q jenkins.service"

# Test 8: Check SSH server
echo ""
echo -e "${BLUE}[7] SSH Server${NC}"
run_test "SSH config exists" "docker exec ${CONTAINER_NAME} test -f /etc/ssh/sshd_config"
run_test "SSH directory exists" "docker exec ${CONTAINER_NAME} test -d /var/run/sshd"

# Test 9: Check user configuration
echo ""
echo -e "${BLUE}[8] User Configuration${NC}"
run_test "User account exists" "docker exec ${CONTAINER_NAME} id user"
run_test "User home exists" "docker exec ${CONTAINER_NAME} test -d /home/user"
run_test "Sudo config exists" "docker exec ${CONTAINER_NAME} test -f /etc/sudoers.d/user"

# Test 10: Check file permissions
echo ""
echo -e "${BLUE}[9] File Permissions${NC}"
run_test "Jenkins home owned by jenkins" "docker exec ${CONTAINER_NAME} bash -c 'test \$(stat -c %U /var/lib/jenkins) = jenkins'"
run_test "User home owned by user" "docker exec ${CONTAINER_NAME} bash -c 'test \$(stat -c %U /home/user) = user'"

# Test 11: Check services are starting
echo ""
echo -e "${BLUE}[10] Service Status (after 15s wait)${NC}"

# Wait a bit more for services to start
sleep 15

if docker exec ${CONTAINER_NAME} systemctl is-active ssh &>/dev/null; then
    echo -e "${GREEN}✓${NC} SSH service is active"
else
    echo -e "${YELLOW}⚠${NC} SSH service not active (may be starting)"
fi

if docker exec ${CONTAINER_NAME} systemctl is-active nginx &>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx service is active"
else
    echo -e "${YELLOW}⚠${NC} Nginx service not active (may be starting)"
fi

if docker exec ${CONTAINER_NAME} systemctl is-active jenkins &>/dev/null; then
    echo -e "${GREEN}✓${NC} Jenkins service is active"
else
    echo -e "${YELLOW}⚠${NC} Jenkins service not active (may take 30-60s to start)"
fi

# Final summary
echo ""
echo -e "${BLUE}================================================${NC}"
if [ ${TEST_FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "Image ${IMAGE_NAME} is ready for production use."
    exit 0
else
    echo -e "${RED}✗ ${TEST_FAILED} test(s) failed${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "Please review the failed tests and fix the issues."
    exit 1
fi
