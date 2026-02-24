#!/bin/bash
set -euo pipefail

#######################################################################
# Directory Structure Setup Script for Silver Stack
#
# This script creates the complete directory structure for custom
# rootfs images (Jenkins, SonarQube, Nexus) for iximiuz Labs.
#
# Usage:
#   chmod +x setup-directory-structure.sh
#   ./setup-directory-structure.sh
#
# Location: /Users/ibtisam-iq/gitHub/silver-stack/iximiuz/
#
# Author: Muhammad Ibtisam Iqbal
# Date: February 22, 2026
#######################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory (current location)
BASE_DIR="$(pwd)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Silver Stack Directory Structure Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "Base directory: ${GREEN}${BASE_DIR}${NC}"
echo ""

# Function to create directory with confirmation
create_dir() {
    local dir_path="${1}"
    if [ ! -d "${dir_path}" ]; then
        mkdir -p "${dir_path}"
        echo -e "${GREEN}✓${NC} Created: ${dir_path}"
    else
        echo -e "${YELLOW}→${NC} Exists: ${dir_path}"
    fi
}

# Function to create file with content
create_file() {
    local file_path="${1}"
    local content="${2}"
    
    if [ ! -f "${file_path}" ]; then
        echo "${content}" > "${file_path}"
        echo -e "${GREEN}✓${NC} Created: ${file_path}"
    else
        echo -e "${YELLOW}→${NC} Exists: ${file_path}"
    fi
}

# Function to make file executable
make_executable() {
    local file_path="${1}"
    chmod +x "${file_path}"
    echo -e "${GREEN}✓${NC} Made executable: ${file_path}"
}

echo -e "${BLUE}Creating root structure...${NC}"
echo ""

# Root directories
create_dir "${BASE_DIR}/rootfs"
create_dir "${BASE_DIR}/docs"
create_dir "${BASE_DIR}/.github"
create_dir "${BASE_DIR}/.github/workflows"

echo ""
echo -e "${BLUE}Creating Jenkins rootfs structure...${NC}"
echo ""

# Jenkins directories
create_dir "${BASE_DIR}/rootfs/jenkins"
create_dir "${BASE_DIR}/rootfs/jenkins/scripts"
create_dir "${BASE_DIR}/rootfs/jenkins/configs"

# Jenkins files
create_file "${BASE_DIR}/rootfs/jenkins/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/jenkins/scripts/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/jenkins/configs/.gitkeep" "# Keep this directory in git"

echo ""
echo -e "${BLUE}Creating SonarQube rootfs structure...${NC}"
echo ""

# SonarQube directories
create_dir "${BASE_DIR}/rootfs/sonarqube"
create_dir "${BASE_DIR}/rootfs/sonarqube/scripts"
create_dir "${BASE_DIR}/rootfs/sonarqube/configs"

# SonarQube files
create_file "${BASE_DIR}/rootfs/sonarqube/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/sonarqube/scripts/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/sonarqube/configs/.gitkeep" "# Keep this directory in git"

echo ""
echo -e "${BLUE}Creating Nexus rootfs structure...${NC}"
echo ""

# Nexus directories
create_dir "${BASE_DIR}/rootfs/nexus"
create_dir "${BASE_DIR}/rootfs/nexus/scripts"
create_dir "${BASE_DIR}/rootfs/nexus/configs"

# Nexus files
create_file "${BASE_DIR}/rootfs/nexus/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/nexus/scripts/.gitkeep" "# Keep this directory in git"
create_file "${BASE_DIR}/rootfs/nexus/configs/.gitkeep" "# Keep this directory in git"

echo ""
echo -e "${BLUE}Creating documentation structure...${NC}"
echo ""

# Documentation files
create_file "${BASE_DIR}/docs/.gitkeep" "# Keep this directory in git"

echo ""
echo -e "${BLUE}Creating GitHub Actions workflows...${NC}"
echo ""

# GitHub workflows
create_file "${BASE_DIR}/.github/workflows/.gitkeep" "# Keep this directory in git"

echo ""
echo -e "${BLUE}Creating root-level files...${NC}"
echo ""

# Root-level README if doesn't exist
if [ ! -f "${BASE_DIR}/README.md" ]; then
    cat > "${BASE_DIR}/README.md" << 'EOF'
# Silver Stack - Self-Hosted CI/CD on iximiuz Labs

Custom rootfs images for Jenkins, SonarQube, and Nexus on iximiuz Labs playgrounds.

## Directory Structure

```
iximiuz/
├── rootfs/                    # Custom rootfs image definitions
│   ├── jenkins/              # Jenkins LTS with Java 21
│   ├── sonarqube/            # SonarQube with PostgreSQL
│   └── nexus/                # Nexus Repository Manager
├── docs/                      # Setup documentation
├── .github/workflows/         # CI/CD automation
└── README.md                 # This file
```

## Quick Start

See individual service README files:
- [Jenkins Setup](./rootfs/jenkins/README.md)
- [SonarQube Setup](./rootfs/sonarqube/README.md)
- [Nexus Setup](./rootfs/nexus/README.md)

## Documentation

Complete guides available in `docs/` directory.

## Author

Muhammad Ibtisam Iqbal
EOF
    echo -e "${GREEN}✓${NC} Created: ${BASE_DIR}/README.md"
else
    echo -e "${YELLOW}→${NC} Exists: ${BASE_DIR}/README.md"
fi

# Create .gitignore if doesn't exist
if [ ! -f "${BASE_DIR}/.gitignore" ]; then
    cat > "${BASE_DIR}/.gitignore" << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log

# Temporary files
*.tmp
*.bak
*.cache

# Secrets (never commit)
*.pem
*.key
*-credentials.json
.env
.env.*

# Build artifacts
*.tar.gz
*.zip
node_modules/
target/
dist/
build/
EOF
    echo -e "${GREEN}✓${NC} Created: ${BASE_DIR}/.gitignore"
else
    echo -e "${YELLOW}→${NC} Exists: ${BASE_DIR}/.gitignore"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Directory structure created successfully!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Display tree structure
echo -e "${BLUE}Current directory tree:${NC}"
echo ""

if command -v tree &> /dev/null; then
    tree -L 3 -a --dirsfirst "${BASE_DIR}"
else
    echo -e "${YELLOW}Note: Install 'tree' command for better visualization:${NC}"
    echo -e "  brew install tree"
    echo ""
    echo "Directory structure:"
    find "${BASE_DIR}" -type d | sed 's|^'"${BASE_DIR}"'||' | sed 's|^/||' | sort
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo -e "1. ${GREEN}Generate individual service files:${NC}"
echo -e "   cd ${BASE_DIR}"
echo -e "   # Copy Dockerfile, scripts, and configs for each service"
echo ""
echo -e "2. ${GREEN}Initialize git repository (if not already):${NC}"
echo -e "   git init"
echo -e "   git add ."
echo -e "   git commit -m 'Initial directory structure'"
echo ""
echo -e "3. ${GREEN}Push to GitHub:${NC}"
echo -e "   git remote add origin https://github.com/ibtisam-iq/silver-stack.git"
echo -e "   git branch -M main"
echo -e "   git push -u origin main"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
