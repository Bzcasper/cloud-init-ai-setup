#!/bin/bash

# Flask dashboard setup script for Local AI Packaged environment
# This script configures the monitoring dashboard for system resources and services

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

info "Setting up Flask monitoring dashboard..."

# Create dashboard directory
mkdir -p /home/$USERNAME/dashboard/templates
chown -R $USERNAME:$USERNAME /home/$USERNAME/dashboard

# Install required Python packages
pip3 install flask flask-socketio psutil docker

# Copy the Flask application code to app.py
cat > /home/$USERNAME/dashboard/app.py << 'EOFFLASK'
#!/usr/bin/env python3

import os
import json
import time
import psutil
import docker
import logging
import subprocess
import threading
from datetime import datetime
from flask import Flask, render_template, jsonify, request, Response
from flask_socketio import SocketIO

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/dashboard.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'local-ai-packaged-dashboard'
socketio = SocketIO(app)

# Global variables
logs_being_watched = {}
service_status = {}
last_docker_check = 0
docker_containers = []

# Connect to Docker
try:
    docker_client = docker.from_env()
except Exception as e:
    logger.error(f"Failed to connect to Docker: {e}")
    docker_client = None

# Helper functions
def get_system_info():
    """Get system resource usage information"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        # Get load averages
        load_avg = os.getloadavg()

        # Get network info
        net_io = psutil.net_io_counters()

        return {
            'cpu_percent': cpu_percent,
            'memory_percent': memory.percent,
            'memory_used': memory.used,
            'memory_total': memory.total,
            'disk_percent': disk.percent,
            'disk_used': disk.used,
            'disk_total': disk.total,
            'load_avg': load_avg,
            'net_sent': net_io.bytes_sent,
            'net_recv': net_io.bytes_recv,
            'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
    except Exception as e:
        logger.error(f"Error getting system info: {e}")
        return {}

def get_docker_containers():
    """Get information about Docker containers"""
    global docker_client, last_docker_check, docker_containers

    # Cache results to reduce API calls (refresh every 5 seconds)
    if time.time() - last_docker_check > 5:
        try:
            if docker_client:
                docker_containers = docker_client.containers.list(all=True)
                last_docker_check = time.time()
        except Exception as e:
            logger.error(f"Error getting Docker containers: {e}")
            docker_containers = []

    container_info = []
    for container in docker_containers:
        try:
            container.reload()  # Refresh container data

            # Get stats for running containers
            stats = {}
            if container.status == 'running':
                try:
                    stats_obj = container.stats(stream=False)
                    # Extract CPU usage
                    cpu_delta = stats_obj['cpu_stats']['cpu_usage']['total_usage'] - \
                                stats_obj.get('precpu_stats', {}).get('cpu_usage', {}).get('total_usage', 0)
                    system_delta = stats_obj['cpu_stats']['system_cpu_usage'] - \
                                  stats_obj.get('precpu_stats', {}).get('system_cpu_usage', 0)

                    if system_delta > 0 and cpu_delta > 0:
                        cpu_percent = (cpu_delta / system_delta) * 100.0
                    else:
                        cpu_percent = 0.0

                    # Extract memory usage
                    memory_used = stats_obj['memory_stats'].get('usage', 0)
                    memory_limit = stats_obj['memory_stats'].get('limit', 1)
                    memory_percent = (memory_used / memory_limit) * 100.0

                    stats = {
                        'cpu_percent': round(cpu_percent, 2),
                        'memory_used': memory_used,
                        'memory_limit': memory_limit,
                        'memory_percent': round(memory_percent, 2)
                    }
                except Exception as e:
                    logger.error(f"Error getting stats for container {container.name}: {e}")
            container_info.append({
                'id': container.id,
                'name': container.name,
                'image': container.image.tags[0] if container.image.tags else 'N/A',
                'status': container.status,
                'stats': stats
            })
        except Exception as e:
            logger.error(f"Error processing container {container.name}: {e}")
    return container_info

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/system')
def system_info():
    return jsonify(get_system_info())

@app.route('/api/docker')
def docker_info():
    return jsonify(get_docker_containers())

@app.route('/api/services')
def services_info():
    # Placeholder for services information
    return jsonify({})

@app.route('/api/debug', methods=['POST'])
def debug_command():
    data = request.get_json()
    command = data.get('command', '')
    try:
        result = subprocess.run(command, shell=True, check=False, capture_output=True, text=True)
        return jsonify({
            'status': 'success',
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        })

@app.route('/api/restart/service', methods=['POST'])
def restart_service():
    # Placeholder for restarting services
    return jsonify({'status': 'success'})

@app.route('/api/restart/container', methods=['POST'])
def restart_container():
    # Placeholder for restarting containers
    return jsonify({'status': 'success'})

# SocketIO event handlers
@socketio.on('watch_log')
def handle_watch_log(data):
    log_file = data.get('log_file')
    if log_file and log_file not in logs_being_watched:
        logs_being_watched[log_file] = True
        threading.Thread(target=tail_log, args=(log_file,)).start()

@socketio.on('stop_watch_log')
def handle_stop_watch_log(data):
    log_file = data.get('log_file')
    if log_file in logs_being_watched:
        logs_being_watched[log_file] = False

def tail_log(log_file):
    try:
        with open(log_file, 'r') as f:
            f.seek(0, os.SEEK_END)
            while logs_being_watched.get(log_file, False):
                line = f.readline()
                if not line:
                    time.sleep(0.1)
                    continue
                socketio.emit('log_line', {'log_file': log_file, 'line': line.strip()})
    except Exception as e:
        socketio.emit('log_error', {'message': f"Error reading log file {log_file}: {str(e)}"})
        logs_being_watched[log_file] = False

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000)
EOFFLASK

# Create a simplified HTML template (full template to be split into a separate file if needed)
cat > /home/$USERNAME/dashboard/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Local AI Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.3/font/bootstrap-icons.css">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }
        .card {
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
            border: none;
        }
        .card-header {
            background-color: #fff;
            border-bottom: 1px solid rgba(0, 0, 0, 0.125);
            border-top-left-radius: 10px;
            border-top-right-radius: 10px;
            font-weight: 600;
        }
        .system-metrics {
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
        }
        .metric-card {
            width: 48%;
            margin-bottom: 15px;
            text-align: center;
            padding: 15px;
            border-radius: 8px;
            background-color: #fff;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }
        .metric-title {
            font-size: 0.9rem;
            color: #6c757d;
            margin-bottom: 5px;
        }
        .metric-value {
            font-size: 1.5rem;
            font-weight: 600;
            color: #343a40;
        }
        .log-container {
            background-color: #212529;
            color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', Courier, monospace;
            height: 400px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="bi bi-boxes me-2"></i>
                Local AI Dashboard
            </a>
        </div>
    </nav>

    <div class="container py-4">
        <div class="row">
            <div class="col-lg-12 mb-4">
                <div class="alert alert-info">
                    <i class="bi bi-info-circle-fill me-2"></i>
                    Welcome to the Local AI Packaged Dashboard. Monitor system resources, Docker containers, and services.
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-lg-4">
                <div class="card h-100">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-pc-display me-2"></i>System Resources</span>
                        <button id="refreshSystem" class="btn btn-sm btn-outline-secondary">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </div>
                    <div class="card-body">
                        <div class="system-metrics">
                            <div class="metric-card">
                                <div class="metric-title">CPU Usage</div>
                                <div class="metric-value" id="cpuUsage">0%</div>
                                <div class="progress mt-2" style="height: 5px;">
                                    <div id="cpuProgress" class="progress-bar bg-primary" style="width: 0%"></div>
                                </div>
                            </div>
                            <div class="metric-card">
                                <div class="metric-title">Memory Usage</div>
                                <div class="metric-value" id="memoryUsage">0%</div>
                                <div class="progress mt-2" style="height: 5px;">
                                    <div id="memoryProgress" class="progress-bar bg-success" style="width: 0%"></div>
                                </div>
                            </div>
                            <div class="metric-card">
                                <div class="metric-title">Disk Usage</div>
                                <div class="metric-value" id="diskUsage">0%</div>
                                <div class="progress mt-2" style="height: 5px;">
                                    <div id="diskProgress" class="progress-bar bg-warning" style="width: 0%"></div>
                                </div>
                            </div>
                            <div class="metric-card">
                                <div class="metric-title">Load Average</div>
                                <div class="metric-value" id="loadAverage">0.00, 0.00, 0.00</div>
                            </div>
                        </div>
                        <div class="text-end mt-3">
                            <small class="text-muted" id="lastUpdated">Last updated: Never</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/socket.io/client-dist/socket.io.min.js"></script>
    <script>
        // Connect to WebSocket
        const socket = io();

        // Initialize the dashboard
        function initDashboard() {
            fetchSystemInfo();

            // Set up refresh button
            document.getElementById('refreshSystem').addEventListener('click', fetchSystemInfo);

            // Setup auto-refresh
            setInterval(fetchSystemInfo, 10000); // Refresh system info every 10 seconds
        }

        // Fetch system information
        function fetchSystemInfo() {
            fetch('/api/system')
                .then(response => response.json())
                .then(data => updateSystemInfo(data))
                .catch(error => console.error('Error fetching system info:', error));
        }

        // Update system information on the dashboard
        function updateSystemInfo(data) {
            document.getElementById('cpuUsage').textContent = `${data.cpu_percent.toFixed(1)}%`;
            document.getElementById('cpuProgress').style.width = `${data.cpu_percent}%`;

            document.getElementById('memoryUsage').textContent = `${data.memory_percent.toFixed(1)}%`;
            document.getElementById('memoryProgress').style.width = `${data.memory_percent}%`;

            document.getElementById('diskUsage').textContent = `${data.disk_percent.toFixed(1)}%`;
            document.getElementById('diskProgress').style.width = `${data.disk_percent}%`;

            document.getElementById('loadAverage').textContent = data.load_avg.map(l => l.toFixed(2)).join(', ');

            document.getElementById('lastUpdated').textContent = `Last updated: ${data.timestamp}`;
        }

        // Initialize the dashboard when the page loads
        document.addEventListener('DOMContentLoaded', initDashboard);
    </script>
</body>
</html>
EOF

# Create systemd service for the dashboard
cat > /etc/systemd/system/dashboard.service << EOF
[Unit]
Description=Local AI Dashboard
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/home/$USERNAME/dashboard
ExecStart=/usr/bin/python3 /home/$USERNAME/dashboard/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the dashboard service
systemctl daemon-reload
systemctl enable dashboard.service
systemctl start dashboard.service

info "Flask dashboard setup completed successfully."
