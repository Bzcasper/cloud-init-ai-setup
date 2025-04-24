#!/bin/bash

# Local AI Packaged installation script for Local AI Packaged environment
# This script clones the repository and sets up environment variables

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
CREDENTIALS_FILE="/root/credentials.txt"

# Stage tracking for error recovery
CURRENT_STAGE="repo_clone"

info "Cloning local-ai-packaged repository..."
mkdir -p "/home/$USERNAME/apps"
cd "/home/$USERNAME/apps"
git clone https://github.com/coleam00/local-ai-packaged.git
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/apps"
cd local-ai-packaged
info "Repository cloned to /home/$USERNAME/apps/local-ai-packaged"

# Setup environment variables
info "Setting up environment variables..."
cp .env.example .env
# Generate secure random values for environment variables
POSTGRES_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 32)
ANON_KEY=$(openssl rand -base64 24)
SERVICE_ROLE_KEY=$(openssl rand -base64 24)
DASHBOARD_USERNAME="admin"
DASHBOARD_PASSWORD=$(openssl rand -base64 12)
POOLER_TENANT_ID=$(openssl rand -hex 16)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 24)
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -base64 24)

# Replace environment variables in .env file
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
sed -i "s/^ANON_KEY=.*/ANON_KEY=$ANON_KEY/" .env
sed -i "s/^SERVICE_ROLE_KEY=.*/SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY/" .env
sed -i "s/^DASHBOARD_USERNAME=.*/DASHBOARD_USERNAME=$DASHBOARD_USERNAME/" .env
sed -i "s/^DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD/" .env
sed -i "s/^POOLER_TENANT_ID=.*/POOLER_TENANT_ID=$POOLER_TENANT_ID/" .env
sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY/" .env
sed -i "s/^N8N_USER_MANAGEMENT_JWT_SECRET=.*/N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET/" .env

# Save service credentials to file
cat >> $CREDENTIALS_FILE << EOF

LOCAL AI PACKAGED CREDENTIALS
-----------------------
Dashboard Username: $DASHBOARD_USERNAME
Dashboard Password: $DASHBOARD_PASSWORD
EOF

info "Environment variables set up and saved to credentials file"
info "Local AI Packaged installation completed successfully."
