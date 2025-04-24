#!/bin/bash

# System optimization script for Local AI Packaged environment
# This script handles system tuning and swap file creation for optimal performance

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

# Create swap file if less than 8GB RAM
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$MEM_TOTAL" -lt 8000000 ]; then
    info "Less than 8GB RAM detected. Creating swap file..."
    if [ ! -f /var/swap.1 ]; then
        fallocate -l 4G /var/swap.1
        chmod 600 /var/swap.1
        mkswap /var/swap.1
        swapon /var/swap.1
        echo '/var/swap.1 swap swap defaults 0 0' | tee -a /etc/fstab
        info "4GB swap file created"
    else
        warn "Swap file already exists"
    fi
fi

# System kernel parameter tuning
cat > /etc/sysctl.d/60-custom.conf << EOF
# Increase system file descriptor limit
fs.file-max = 100000

# Optimize network settings
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# VM settings for better performance
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

# Apply sysctl settings
sysctl --system

info "System optimization completed successfully."
