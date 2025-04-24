#!/bin/bash

# Service setup script for Local AI Packaged environment
# This script configures systemd services for managing the Local AI Packaged environment

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
CURRENT_STAGE="service_start"

info "Creating systemd service..."
cat > /etc/systemd/system/localai.service << EOF
[Unit]
Description=Local AI Packaged Services
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/home/$USERNAME/apps/local-ai-packaged
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=10

# Error handling and recovery
StartLimitIntervalSec=300
StartLimitBurst=3
StartLimitAction=reboot-force

# Resource management
TimeoutStartSec=180
TimeoutStopSec=120
MemoryLimit=8G

[Install]
WantedBy=multi-user.target
EOF

# Setup service monitoring and automatic recovery
cat > /etc/systemd/system/localai-monitor.service << EOF
[Unit]
Description=Local AI Service Monitor
After=localai.service
Requires=localai.service

[Service]
Type=simple
User=root
ExecStart=/bin/bash /home/$USERNAME/scripts/monitor_service.sh
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Create monitoring script with improved error handling and diagnostics
cat > /home/$USERNAME/scripts/monitor_service.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/localai-monitor.log"
exec >> $LOG_FILE 2>&1

echo "[$(date)] Service monitor started"

# Function to save diagnostics
save_diagnostics() {
    local service=$1
    local diag_file="/var/log/localai-diagnostics-$(date +%Y%m%d-%H%M%S).log"

    echo "[$(date)] Saving diagnostics to $diag_file"

    # System info
    echo "=== SYSTEM INFO ===" > $diag_file
    free -h >> $diag_file
    df -h >> $diag_file
    top -b -n 1 >> $diag_file

    # Service info
    echo "=== SERVICE INFO ===" >> $diag_file
    systemctl status $service >> $diag_file
    journalctl -u $service --no-pager -n 100 >> $diag_file

    # Docker info
    echo "=== DOCKER INFO ===" >> $diag_file
    docker ps -a >> $diag_file
    docker stats --no-stream >> $diag_file

    echo "[$(date)] Diagnostics saved to $diag_file"
    return $diag_file
}

# Function to check container health
check_container_health() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)

    if [ "$status" != "running" ]; then
        echo "[$(date)] Container $container is not running (status: $status)"
        return 1
    fi

    # Check if container is healthy if it has a health check
    local health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null)
    if [ -n "$health" ] && [ "$health" != "healthy" ]; then
        echo "[$(date)] Container $container is not healthy (health: $health)"
        return 1
    fi

    return 0
}

# Main monitoring loop with improved recovery
while true; do
    # Check if localai service is running
    if ! systemctl is-active --quiet localai.service; then
        echo "[$(date)] localai service is down, attempting to restart..."
        save_diagnostics "localai.service"
        systemctl restart localai.service
        sleep 30

        # Check if restart was successful
        if systemctl is-active --quiet localai.service; then
            echo "[$(date)] Service restart successful"
        else
            echo "[$(date)] Service restart failed, attempting recovery..."

            # Check for Docker issues
            if ! systemctl is-active --quiet docker; then
                echo "[$(date)] Docker service is down, restarting Docker..."
                systemctl restart docker
                sleep 15
                systemctl restart localai.service
            else
                # Check individual containers
                echo "[$(date)] Checking individual containers..."

                # Get list of expected containers
                expected_containers=$(docker compose -f /home/localai/apps/local-ai-packaged/docker-compose.yml config --services)

                for container in $expected_containers; do
                    container_name="local-ai-packaged-${container}-1"

                    if ! check_container_health $container_name; then
                        echo "[$(date)] Restarting unhealthy container: $container_name"
                        docker restart $container_name
                    fi
                done

                echo "[$(date)] Forcing cleanup of containers..."
                docker compose -f /home/localai/apps/local-ai-packaged/docker-compose.yml down -v
                sleep 10
                systemctl restart localai.service
            fi
        fi
    else
        # Even if service is running, check individual containers
        docker_containers=$(docker ps --format '{{.Names}}' | grep "local-ai-packaged" || true)
        for container in $docker_containers; do
            if ! check_container_health $container; then
                echo "[$(date)] Container $container unhealthy but service running. Restarting..."
                docker restart $container
            fi
        done
    fi

    # Memory usage check with OOM prevention
    MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
        echo "[$(date)] High memory usage detected: ${MEM_USAGE}%, clearing caches and restarting service..."
        sync
        echo 3 > /proc/sys/vm/drop_caches

        # Find largest memory consumers
        echo "[$(date)] Top memory consumers:"
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -10 >> $LOG_FILE

        # If memory is still critical, restart the service
        if (( $(echo "$MEM_USAGE > 95" | bc -l) )); then
            echo "[$(date)] Critical memory situation, restarting service..."
            systemctl restart localai.service
        fi
    fi

    # Disk space check
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        echo "[$(date)] High disk usage detected: ${DISK_USAGE}%, cleaning up..."
        # Clean Docker
        docker system prune -f --volumes

        # Clean package cache
        apt-get clean

        # Clean logs
        journalctl --vacuum-time=2d

        # Find large files
        echo "[$(date)] Largest files in /var/log:"
        find /var/log -type f -exec du -h {} \; | sort -rh | head -10 >> $LOG_FILE
    fi

    # Sleep for 60 seconds before next check
    sleep 60
done
EOF

# Make script executable
chmod +x /home/$USERNAME/scripts/monitor_service.sh
chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts

chown $USERNAME:$USERNAME /home/$USERNAME/apps/local-ai-packaged -R
systemctl daemon-reload
systemctl enable localai.service localai-monitor.service
systemctl start localai-monitor.service
info "Service monitoring configured"

# Start local-ai-packaged with error handling
info "Starting local-ai-packaged services..."
if ! systemctl start localai.service; then
    error "LocalAI service failed to start. Attempting recovery..."
    # Check Docker status
    if ! systemctl is-active --quiet docker.service; then
        warn "Docker service is not running. Attempting to restart..."
        systemctl restart docker.service
        sleep 10
    fi

    # Try to restart the service
    systemctl restart localai.service
    sleep 5

    if ! systemctl is-active --quiet localai.service; then
        error "LocalAI service failed to start after recovery. Attempting docker system prune..."
        docker system prune -f
        systemctl restart localai.service

        if ! systemctl is-active --quiet localai.service; then
            error "LocalAI service could not be started. Please check logs with: journalctl -u localai.service"
        else
            info "LocalAI service recovery successful after docker prune."
        fi
    else
        info "LocalAI service recovery successful."
    fi
else
    info "LocalAI service started successfully."
fi

# Start monitoring service with error handling
if ! systemctl start localai-monitor.service; then
    error "Monitor service failed to start. Check permissions and logs."
    # Verify script permissions
    chmod +x /home/$USERNAME/scripts/monitor_service.sh
    systemctl restart localai-monitor.service
else
    info "Monitor service started successfully."
fi

info "Service setup completed successfully."
