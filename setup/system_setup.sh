#!/bin/bash

# System setup script for Local AI Packaged environment
# This script handles system updates, user creation, and basic utility installations

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
PASSWORD=$(openssl rand -base64 12)

# Stage tracking for error recovery
CURRENT_STAGE="system_update"

info "Updating system packages..."
apt-get update
apt-get upgrade -y

info "Installing basic utilities..."
apt-get install -y curl wget git unzip apt-transport-https ca-certificates gnupg lsb-release software-properties-common fail2ban jq

# Create a non-root user with sudo privileges
info "Creating non-root user: $USERNAME..."
useradd -m -s /bin/bash -U "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

info "System setup completed successfully."
