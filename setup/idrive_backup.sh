#!/bin/bash

# IDrive backup setup script for Local AI Packaged environment
# This script configures backup directories and scripts for data protection

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

info "Setting up IDrive backup..."

# Create backup directories
mkdir -p /home/$USERNAME/backups
chown $USERNAME:$USERNAME /home/$USERNAME/backups

# Download IDrive for Linux package
wget -O /tmp/idriveforlinux.bin https://www.idrive.com/downloads/linux/download/idriveforlinux.bin
chmod +x /tmp/idriveforlinux.bin

# Create the IDrive backup script
cat > /home/$USERNAME/scripts/backup.sh << 'EOF'
#!/bin/bash

# IDrive backup script for local-ai-packaged
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/home/localai/backups"
BACKUP_FILE="$BACKUP_DIR/local_ai_backup_$TIMESTAMP.tar.gz"
LOG_FILE="$BACKUP_DIR/backup_$TIMESTAMP.log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop services for consistent backup
log "Stopping localai service for consistent backup..."
systemctl stop localai.service

# Create backup of entire local-ai-packaged directory
log "Creating backup archive..."
tar -czf "$BACKUP_FILE" -C /home/localai/apps local-ai-packaged 2>> "$LOG_FILE"

# Restart services
log "Restarting localai service..."
systemctl start localai.service

# Use IDrive CLI to upload backup
log "Uploading backup to IDrive..."
/bin/idrive/idrive --backup-file "$BACKUP_FILE" 2>> "$LOG_FILE"

# Clean up old backups (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "local_ai_backup_*.tar.gz" -type f -mtime +7 -delete
find "$BACKUP_DIR" -name "backup_*.log" -type f -mtime +7 -delete

log "Backup completed successfully"
EOF

# Make backup script executable
mkdir -p /home/$USERNAME/scripts
chmod +x /home/$USERNAME/scripts/backup.sh
chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts

# Create cron job for daily backups
echo "0 3 * * * $USERNAME /home/$USERNAME/scripts/backup.sh" > /etc/cron.d/idrive-backup
chmod 0644 /etc/cron.d/idrive-backup

info "IDrive backup setup completed successfully."
