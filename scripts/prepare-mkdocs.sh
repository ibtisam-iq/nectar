#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar

ROOT_DIR="$(pwd)"
DOCS_DIR="${ROOT_DIR}/docs"

echo "1) Ensuring docs directory exists: ${DOCS_DIR}"
mkdir -p "${DOCS_DIR}"

###############################################################################
# 2) Rename README.md -> index.md everywhere under /docs
###############################################################################
echo "2) Renaming README.md -> index.md where needed..."

while IFS= read -r -d '' readme; do
  dir="$(dirname "$readme")"
  target="${dir}/index.md"

  if [ -f "${target}" ]; then
    echo " - Skipped: ${readme} (index.md already exists)"
  else
    echo " - Renaming ${readme} -> ${target}"
    mv "$readme" "$target"
  fi
done < <(find "${DOCS_DIR}" -type f -name 'README.md' -print0)

###############################################################################
# 3) Normalize filenames — replace spaces with hyphens
###############################################################################
echo "3) Normalizing filenames (spaces → hyphens)..."

extensions=("md" "png" "jpg" "jpeg" "gif" "yaml" "yml" "conf" "txt" "pdf")

for ext in "${extensions[@]}"; do
  while IFS= read -r -d '' f; do
    dir="$(dirname "$f")"
    base="$(basename "$f")"
    newbase="$(echo "$base" | tr ' ' '-' | sed 's/%20/-/g')"

    if [ "$base" != "$newbase" ]; then
      if [ -f "${dir}/${newbase}" ]; then
        echo " - Skipped rename (target exists): ${f}"
      else
        echo " - Renaming ${f} -> ${dir}/${newbase}"
        mv "$f" "${dir}/${newbase}"
      fi
    fi
  done < <(find "${DOCS_DIR}" -type f -name "* *.$ext" -print0)
done

###############################################################################
# 4) Create top-level .pages (fixed heredoc)
###############################################################################
TOP_PAGES="${DOCS_DIR}/.pages"
echo "4) Writing top-level .pages → ${TOP_PAGES}"

cat << 'YAML' > "${TOP_PAGES}"
title: Nectar
arrange:
  - index.md
  - apps
  - aws
  - docker
  - docker-compose
  - foundation
  - git
  - helm
  - jenkins
  - kubernetes
  - kustomize
  - linux
  - networking
  - nexus
  - nginx
  - sonarqube
  - trivy
  - yaml
  - troubleshooting
YAML

###############################################################################
# 5) Section-level .pages files
###############################################################################
echo "5) Creating section-level .pages files..."

# Kubernetes
mkdir -p "${DOCS_DIR}/kubernetes"
cat << 'YAML' > "${DOCS_DIR}/kubernetes/.pages"
title: kubernetes
arrange:
  - 00-cluster-setup
  - 01-core-concepts
  - 02-cli-operations
  - 03-networking
  - 04-storage
  - 05-scheduling-and-affinity
  - 06-resource-management
  - 07-security
  - 08-debugging-monitoring
  - 09-workloads
  - 10-references
  - practice-labs
  - unorganized
YAML

# Docker
mkdir -p "${DOCS_DIR}/docker"
cat << 'YAML' > "${DOCS_DIR}/docker/.pages"
title: docker
arrange:
  - index.md
  - architecture.md
  - installation.md
  - build.md
  - multi-stage1.md
  - multi-stage2.md
  - multi-stage3.md
  - network.md
  - volumes.md
  - troubleshooting.md
YAML

# AWS
mkdir -p "${DOCS_DIR}/aws"
cat << 'YAML' > "${DOCS_DIR}/aws/.pages"
title: aws
arrange:
  - introduction.md
  - AWS.md
  - iam.md
  - identity-center.md
  - arn.md
  - policies.md
  - images
  - consoleOutput.txt
YAML

# Helm
mkdir -p "${DOCS_DIR}/helm"
cat << 'YAML' > "${DOCS_DIR}/helm/.pages"
title: helm
arrange:
  - index.md
  - helm-guide.md
  - helm-as-pkg-manager.md
  - helm-lab.md
  - quick-ref.md
YAML

# Jenkins
mkdir -p "${DOCS_DIR}/jenkins"
cat << 'YAML' > "${DOCS_DIR}/jenkins/.pages"
title: jenkins
arrange:
  - overview.md
  - Jenkins.md
  - Jenkinsfile.md
  - webhook_setup.md
  - mail_conf.md
  - troubleshooting.md
YAML

# Kustomize
mkdir -p "${DOCS_DIR}/kustomize"
cat << 'YAML' > "${DOCS_DIR}/kustomize/.pages"
title: kustomize
arrange:
  - index.md
  - 01-dir-structure.md
  - 02-manage-directories.md
  - 03-kustomization.yaml.md
  - 04-transformers.md
  - 05-patches.md
  - 06-overlays.md
  - 07-components.md
YAML

###############################################################################
# 6) Ensure docs/index.md exists
###############################################################################
HOME_MD="${DOCS_DIR}/index.md"

if [ ! -f "${HOME_MD}" ]; then
  echo "6) Creating homepage index.md"
  cat << 'MD' > "${HOME_MD}"
# Nectar — Engineering Knowledge System

Welcome to Nectar — your centralized engineering knowledge base covering Cloud, Kubernetes, Docker, CI/CD, networking and more.

Use the left sidebar to explore topics. This site is auto-generated from the repo structure and uses `.pages` metadata files to control ordering.
MD
else
  echo "6) docs/index.md already exists — OK"
fi

###############################################################################
# 7) Summary
###############################################################################
echo
echo "=== DONE ==="
echo "All MkDocs preparation steps completed successfully."
echo "Run locally with:"
echo "  mkdocs serve -a 0.0.0.0:8000"

