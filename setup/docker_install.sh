#!/bin/bash

# Docker installation script for Local AI Packaged environment
# This script installs Docker and configures it for optimal performance

# Log file setup for debugging and troubleshooting
LOGFILE="/var/log/cloud-init-ai-setup.log"
exec > >(tee -a $LOGFILE) 2>&1

# Color codes for better log visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Functions for logging
info() {
    echo -e "${GREEN}[INFO] $(date): $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $(date): $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $(date): $1${NC}"
}

# Variables
USERNAME="localai"

# Stage tracking for error recovery
CURRENT_STAGE="docker_install"

info "Installing Docker..."

# Remove any old versions
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Add Docker official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, containerd, and Docker Compose plugin
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
usermod -aG docker "$USERNAME"
info "Docker installed and $USERNAME added to docker group"

# Apply Docker daemon optimizations
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker

info "Docker installation and configuration completed successfully."
