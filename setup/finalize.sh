#!/bin/bash

# Finalization script for Local AI Packaged environment
# This script completes the setup process with a welcome message and validation checks

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
DOMAIN="aitoolpool.com"
CREDENTIALS_FILE="/root/credentials.txt"

# Get server IP
SERVER_IP=$(curl -s icanhazip.com)

# Read dashboard credentials from the credentials file
DASHBOARD_USERNAME=$(grep "Dashboard Username:" $CREDENTIALS_FILE | awk '{print $3}')
DASHBOARD_PASSWORD=$(grep "Dashboard Password:" $CREDENTIALS_FILE | awk '{print $3}')

# Create a welcome message that displays on login
cat > /etc/update-motd.d/99-local-ai-welcome << EOF
#!/bin/bash
echo ""
echo "Welcome to your Enhanced Local AI Packaged Server!"
echo "=============================================="
echo "All services are running as systemd service: localai.service"
echo ""
echo "Access your services at:"
echo "- n8n: http://$SERVER_IP:5678 or https://n8n.${DOMAIN} (after DNS setup)"
echo "- Open WebUI: http://$SERVER_IP:3000 or https://webui.${DOMAIN} (after DNS setup)"
echo "- Flowise: http://$SERVER_IP:3001 or https://flowise.${DOMAIN} (after DNS setup)"
echo "- Supabase Dashboard: http://$SERVER_IP:8000 or https://supabase.${DOMAIN} (after DNS setup)"
echo "- System Dashboard: http://$SERVER_IP:5000 or https://dashboard.${DOMAIN} (after DNS setup)"
echo ""
echo "Supabase Dashboard credentials:"
echo "Username: $DASHBOARD_USERNAME"
echo "Password: $DASHBOARD_PASSWORD"
echo ""
echo "All credentials and instructions are saved in /root/credentials.txt"
echo "=============================================="
EOF

chmod +x /etc/update-motd.d/99-local-ai-welcome
info "Welcome message created"

# Final validation checks
info "---------------------------------------------------------"
info "Running final validation checks..."

# Check Docker installation
if ! command -v docker &> /dev/null; then
    error "Docker installation failed. Attempting reinstall..."
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if ! command -v docker &> /dev/null; then
        error "Docker reinstallation failed. System may not function properly."
    else
        info "Docker reinstallation successful."
    fi
else
    info "Docker installation check: OK"
fi

# Check service status
for service in docker.service localai.service dashboard.service localai-monitor.service caddy.service; do
    if systemctl is-enabled --quiet $service; then
        info "Service $service is enabled: OK"
    else
        warn "Service $service is not enabled. Enabling..."
        systemctl enable $service
    fi

    if systemctl is-active --quiet $service; then
        info "Service $service is running: OK"
    else
        warn "Service $service is not running. Starting..."
        systemctl start $service
    fi
done

# Verify network ports are accessible
for port in 22 80 443 3000 3001 5678 8000 5000; do
    if nc -z localhost $port; then
        info "Port $port is open: OK"
    else
        warn "Port $port is not accessible. Checking service..."
    fi
done

# Verify user permissions
if groups $USERNAME | grep -q "docker"; then
    info "User $USERNAME is in docker group: OK"
else
    warn "User $USERNAME is not in docker group. Adding..."
    usermod -aG docker $USERNAME
fi

if groups $USERNAME | grep -q "adm"; then
    info "User $USERNAME is in adm group: OK"
else
    warn "User $USERNAME is not in adm group. Adding..."
    usermod -aG adm $USERNAME
fi

info "Finalization completed successfully."
