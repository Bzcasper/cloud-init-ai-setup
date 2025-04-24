#!/bin/bash

# SSH configuration script for Local AI Packaged environment
# This script configures SSH for reliable VSCode connections and security settings

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

info "Configuring SSH for reliable VSCode connections..."

# Create SSH directory and set correct permissions
mkdir -p /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Optimize SSH configuration for VSCode
cat > /etc/ssh/sshd_config.d/vscode.conf << EOF
# SSH optimizations for VSCode Remote connections
ClientAliveInterval 30
ClientAliveCountMax 240
TCPKeepAlive yes
IPQoS lowdelay throughput
UseDNS no
GSSAPIAuthentication no
PermitEmptyPasswords no
MaxSessions 50
MaxStartups 50:30:100
EOF

# Configure key-based authentication
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Add user to required groups for log access
usermod -aG adm,systemd-journal "$USERNAME"

# Install Python packages for the monitoring dashboard
pip3 install virtualenv

# Allow SSH through firewall
info "Configuring firewall..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
# Ports needed for local-ai-packaged
ufw allow 3000/tcp # Open WebUI
ufw allow 3001/tcp # Flowise
ufw allow 5678/tcp # n8n
ufw allow 8000/tcp # Supabase
ufw allow 11434/tcp # Ollama
echo "y" | ufw enable

# Restart SSH service to apply changes
systemctl restart sshd
info "SSH optimized for VSCode connections"

# Add custom SSH configuration to prevent timeouts
cat > /home/$USERNAME/.ssh/config << EOF
Host *
    ServerAliveInterval 30
    ServerAliveCountMax 120
    TCPKeepAlive yes
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
EOF

mkdir -p /home/$USERNAME/.ssh/sockets
chmod 700 /home/$USERNAME/.ssh/sockets
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

info "SSH configuration completed successfully."
