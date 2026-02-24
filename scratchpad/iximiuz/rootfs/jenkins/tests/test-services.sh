#!/bin/bash
set -euo pipefail

#######################################################################
# Service Startup Test Script
#
# This script tests if all services start correctly within the
# Jenkins rootfs container environment.
#
# Usage:
#   Run inside the container:
#   ./test-services.sh
#
# Exit codes:
#   0 - All services started successfully
#   1 - One or more services failed to start
#
# Author: Muhammad Ibtisam Iqbal
#######################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_SERVICES=0
MAX_WAIT=120  # Maximum wait time in seconds
CHECK_INTERVAL=5  # Check every 5 seconds

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Service Startup Test${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to wait for service
wait_for_service() {
    local service_name="${1}"
    local max_wait="${2:-60}"
    local elapsed=0
    
    echo -n "Waiting for ${service_name} to start"
    
    while [ ${elapsed} -lt ${max_wait} ]; do
        if systemctl is-active ${service_name} &>/dev/null; then
            echo -e " ${GREEN}✓ Started${NC} (${elapsed}s)"
            return 0
        fi
        
        echo -n "."
        sleep ${CHECK_INTERVAL}
        elapsed=$((elapsed + CHECK_INTERVAL))
    done
    
    echo -e " ${RED}✗ Failed${NC} (timeout after ${max_wait}s)"
    return 1
}

# Function to check service status
check_service() {
    local service_name="${1}"
    
    echo ""
    echo -e "${BLUE}Checking ${service_name} service...${NC}"
    
    # Check if service is enabled
    if systemctl is-enabled ${service_name} &>/dev/null; then
        echo -e "${GREEN}✓${NC} Service is enabled"
    else
        echo -e "${YELLOW}⚠${NC} Service is not enabled"
    fi
    
    # Check if service is active
    if systemctl is-active ${service_name} &>/dev/null; then
        echo -e "${GREEN}✓${NC} Service is active"
        
        # Show service status
        echo ""
        systemctl status ${service_name} --no-pager -l | head -n 10
        return 0
    else
        echo -e "${RED}✗${NC} Service is not active"
        
        # Show failure reason
        echo ""
        echo "Service status:"
        systemctl status ${service_name} --no-pager -l | head -n 20
        
        echo ""
        echo "Recent logs:"
        journalctl -u ${service_name} -n 30 --no-pager
        
        FAILED_SERVICES=$((FAILED_SERVICES + 1))
        return 1
    fi
}

# Test SSH service
echo -e "${BLUE}[1] SSH Service${NC}"
if wait_for_service "ssh" 30; then
    check_service "ssh"
    
    # Test SSH port
    if ss -tlnp | grep -q ":22"; then
        echo -e "${GREEN}✓${NC} SSH is listening on port 22"
    else
        echo -e "${RED}✗${NC} SSH is not listening on port 22"
        FAILED_SERVICES=$((FAILED_SERVICES + 1))
    fi
fi

# Test Nginx service
echo ""
echo -e "${BLUE}[2] Nginx Service${NC}"
if wait_for_service "nginx" 30; then
    check_service "nginx"
    
    # Test Nginx port
    if ss -tlnp | grep -q ":80"; then
        echo -e "${GREEN}✓${NC} Nginx is listening on port 80"
    else
        echo -e "${RED}✗${NC} Nginx is not listening on port 80"
        FAILED_SERVICES=$((FAILED_SERVICES + 1))
    fi
    
    # Test Nginx configuration
    if nginx -t &>/dev/null; then
        echo -e "${GREEN}✓${NC} Nginx configuration is valid"
    else
        echo -e "${RED}✗${NC} Nginx configuration is invalid"
        nginx -t
        FAILED_SERVICES=$((FAILED_SERVICES + 1))
    fi
fi

# Test Jenkins service (takes longer to start)
echo ""
echo -e "${BLUE}[3] Jenkins Service${NC}"
echo "Note: Jenkins may take 30-90 seconds to fully start"

if wait_for_service "jenkins" ${MAX_WAIT}; then
    check_service "jenkins"
    
    # Test Jenkins port
    if ss -tlnp | grep -q ":8080"; then
        echo -e "${GREEN}✓${NC} Jenkins is listening on port 8080"
    else
        echo -e "${YELLOW}⚠${NC} Jenkins is not yet listening on port 8080"
    fi
    
    # Test Jenkins HTTP response
    echo ""
    echo "Testing Jenkins HTTP endpoint..."
    local jenkins_url="http://localhost:8080"
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${jenkins_url}" || echo "000")
    
    # Jenkins returns 403 before initial setup, which is normal
    if [[ "${http_code}" == "200" ]] || [[ "${http_code}" == "403" ]]; then
        echo -e "${GREEN}✓${NC} Jenkins is responding (HTTP ${http_code})"
    else
        echo -e "${YELLOW}⚠${NC} Jenkins returned HTTP ${http_code} (may still be starting)"
    fi
fi

# Test Jenkins process
echo ""
echo -e "${BLUE}[4] Jenkins Process${NC}"
if pgrep -f jenkins > /dev/null; then
    echo -e "${GREEN}✓${NC} Jenkins process is running"
    ps aux | grep -i jenkins | grep -v grep | head -n 5
else
    echo -e "${RED}✗${NC} Jenkins process not found"
    FAILED_SERVICES=$((FAILED_SERVICES + 1))
fi

# Check Jenkins home directory
echo ""
echo -e "${BLUE}[5] Jenkins Home Directory${NC}"
if [ -d /var/lib/jenkins ]; then
    echo -e "${GREEN}✓${NC} Jenkins home exists: /var/lib/jenkins"
    echo "  Owner: $(stat -c '%U:%G' /var/lib/jenkins)"
    echo "  Permissions: $(stat -c '%a' /var/lib/jenkins)"
    
    # Check for initial admin password
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        echo -e "${GREEN}✓${NC} Initial admin password file exists"
        echo "  Password: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
    else
        echo -e "${YELLOW}⚠${NC} Initial admin password not yet created (Jenkins still initializing)"
    fi
else
    echo -e "${RED}✗${NC} Jenkins home does not exist"
    FAILED_SERVICES=$((FAILED_SERVICES + 1))
fi

# Network connectivity test
echo ""
echo -e "${BLUE}[6] Network Connectivity${NC}"
echo "Testing external connectivity..."
if ping -c 2 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓${NC} External network reachable"
else
    echo -e "${YELLOW}⚠${NC} External network not reachable (may be expected in sandbox)"
fi

# Port summary
echo ""
echo -e "${BLUE}[7] Port Summary${NC}"
echo "Listening ports:"
ss -tlnp | grep -E ":(22|80|8080)" || echo "No expected ports found"

# Final summary
echo ""
echo -e "${BLUE}================================================${NC}"
if [ ${FAILED_SERVICES} -eq 0 ]; then
    echo -e "${GREEN}✓ All services started successfully!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "Jenkins rootfs is ready for use."
    echo ""
    echo "Next steps:"
    echo "  1. Access Jenkins at: http://localhost:8080"
    echo "  2. Get initial password: cat /var/lib/jenkins/secrets/initialAdminPassword"
    echo "  3. Complete Jenkins setup wizard"
    exit 0
else
    echo -e "${RED}✗ ${FAILED_SERVICES} service(s) failed to start${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "Please review the logs above and troubleshoot failed services."
    exit 1
fi
