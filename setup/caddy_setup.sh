#!/bin/bash

# Caddy reverse proxy setup script for Local AI Packaged environment
# This script configures Caddy for subdomains and SSL termination

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
DOMAIN="aitoolpool.com"
CREDENTIALS_FILE="/root/credentials.txt"

info "Installing Caddy for reverse proxy..."

# Install Caddy
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# Get server IP
SERVER_IP=$(curl -s icanhazip.com)

# Basic Caddy configuration with subdomains for local-ai-packaged
cat > /etc/caddy/Caddyfile << EOF
# Global settings
{
    email admin@${DOMAIN}
    acme_ca https://acme-v02.api.letsencrypt.org/directory
}

# Main domain
${DOMAIN} {
    redir https://www.${DOMAIN}{uri}
}

# Subdomain configurations for local-ai-packaged services
n8n.${DOMAIN} {
    reverse_proxy localhost:5678
}

webui.${DOMAIN} {
    reverse_proxy localhost:3000
}

flowise.${DOMAIN} {
    reverse_proxy localhost:3001
}

supabase.${DOMAIN} {
    reverse_proxy localhost:8000
}

# Dashboard monitoring app
dashboard.${DOMAIN} {
    reverse_proxy localhost:5000
}

# Default fallback for www
www.${DOMAIN} {
    respond "Local AI Packaged Server" 200
}
EOF

# Restart Caddy to apply configuration
systemctl restart caddy
systemctl enable caddy

# DNS setup instructions
cat >> $CREDENTIALS_FILE << EOF

CADDY REVERSE PROXY SETUP
-----------------------
To complete the Caddy setup, create the following DNS A records for ${DOMAIN}:
- ${DOMAIN} → ${SERVER_IP}
- www.${DOMAIN} → ${SERVER_IP}
- n8n.${DOMAIN} → ${SERVER_IP}
- webui.${DOMAIN} → ${SERVER_IP}
- flowise.${DOMAIN} → ${SERVER_IP}
- supabase.${DOMAIN} → ${SERVER_IP}

After DNS propagation (may take up to 24 hours), the services will be available at:
- n8n: https://n8n.${DOMAIN}
- Open WebUI: https://webui.${DOMAIN}
- Flowise: https://flowise.${DOMAIN}
- Supabase: https://supabase.${DOMAIN}
EOF

info "Caddy reverse proxy setup completed successfully."
