#!/bin/bash

# Main setup script for Local AI Packaged environment
# This script orchestrates the setup process by calling individual setup scripts
# Log file setup for debugging and troubleshooting
LOGFILE="/var/log/cloud-init-ai-setup.log"
exec > >(tee -a $LOGFILE) 2>&1
echo "Starting enhanced local AI setup at $(date)"

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

# Error handling function
handle_error() {
    error "An error occurred on line $1 with exit code $2"
    warn "Check $LOGFILE for details. Attempting to continue with setup..."
}

# Set trap for error handling
trap 'handle_error $LINENO $?' ERR

# Variables
USERNAME="localai"
PASSWORD=$(openssl rand -base64 12)
DOMAIN="aitoolpool.com"
CREDENTIALS_FILE="/root/credentials.txt"

# Create credentials file
echo "Local AI Packaged Setup Credentials" > $CREDENTIALS_FILE
echo "Generated at: $(date)" >> $CREDENTIALS_FILE
echo "----------------------------------------" >> $CREDENTIALS_FILE
echo "Server User: $USERNAME" >> $CREDENTIALS_FILE
echo "Password: $PASSWORD" >> $CREDENTIALS_FILE
echo "----------------------------------------" >> $CREDENTIALS_FILE

# Stage tracking for error recovery
CURRENT_STAGE="initialization"

info "Starting setup process for Local AI Packaged environment"

# Execute setup scripts in order
info "Running system setup..."
/root/setup/system_setup.sh

info "Running SSH configuration..."
/root/setup/ssh_config.sh

info "Running Docker installation..."
/root/setup/docker_install.sh

info "Running system optimization..."
/root/setup/system_optimize.sh

info "Running IDrive backup setup..."
/root/setup/idrive_backup.sh

info "Running Local AI Packaged installation..."
/root/setup/local_ai_install.sh

info "Running Modal Labs integration..."
/root/setup/modal_labs.sh

info "Running Flask dashboard setup..."
/root/setup/flask_dashboard.sh

info "Running Caddy reverse proxy setup..."
/root/setup/caddy_setup.sh

info "Running service setup and monitoring..."
/root/setup/service_setup.sh

info "Finalizing setup..."
/root/setup/finalize.sh

info "---------------------------------------------------------"
info "INSTALLATION COMPLETED SUCCESSFULLY!"
info "All user and service credentials are saved in $CREDENTIALS_FILE"
info "The system is configured to display service access information on login"
info "---------------------------------------------------------"
