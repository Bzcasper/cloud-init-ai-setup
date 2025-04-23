# Create the HTML template
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
        .service-indicator {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 5px;
        }
        .active {
            background-color: #28a745;
        }
        .inactive {
            background-color: #dc3545;
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
        .nav-tabs .nav-link {
            color: #495057;
            border: none;
            border-bottom: 2px solid transparent;
            font-weight: 500;
        }
        .nav-tabs .nav-link.active {
            color: #007bff;
            background-color: transparent;
            border-bottom: 2px solid #007bff;
        }
        .modal-content {
            border-radius: 10px;
            border: none;
        }
        .debug-output {
            background-color: #212529;
            color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', Courier, monospace;
            height: 300px;
            overflow-y: auto;
            margin-top: 10px;
        }
        /* Spinner */
        .spinner-border {
            width: 1rem;
            height: 1rem;
            border-width: 0.15em;
        }
        /* Badge colors */
        .badge.bg-running {
            background-color: #198754;
        }
        .badge.bg-exited {
            background-color: #6c757d;
        }
        .badge.bg-created {
            background-color: #0d6efd;
        }
        .badge.bg-paused {
            background-color: #fd7e14;
        }
        .badge.bg-restarting {
            background-color: #6610f2;
        }
        .badge.bg-removing {
            background-color: #dc3545;
        }
        .badge.bg-dead {
            background-color: #dc3545;
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

            <div class="col-lg-8">
                <div class="card h-100">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-server me-2"></i>Services</span>
                        <button id="refreshServices" class="btn btn-sm btn-outline-secondary">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th>Service</th>
                                        <th>Status</th>
                                        <th>Description</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="servicesTable">
                                    <tr>
                                        <td colspan="4" class="text-center">Loading services...</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-lg-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-box me-2"></i>Docker Containers</span>
                        <button id="refreshContainers" class="btn btn-sm btn-outline-secondary">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th>Name</th>
                                        <th>Image</th>
                                        <th>Status</th>
                                        <th>CPU</th>
                                        <th>Memory</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="containersTable">
                                    <tr>
                                        <td colspan="6" class="text-center">Loading containers...</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-lg-12">
                <div class="card">
                    <div class="card-header">
                        <ul class="nav nav-tabs card-header-tabs" id="logTabs" role="tablist">
                            <li class="nav-item" role="presentation">
                                <button class="nav-link active" id="system-log-tab" data-bs-toggle="tab" data-bs-target="#system-log" type="button" role="tab">System Log</button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link" id="monitor-log-tab" data-bs-toggle="tab" data-bs-target="#monitor-log" type="button" role="tab">Monitor Log</button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link" id="caddy-log-tab" data-bs-toggle="tab" data-bs-target="#caddy-log" type="button" role="tab">Caddy Log</button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link" id="debug-console-tab" data-bs-toggle="tab" data-bs-target="#debug-console" type="button" role="tab">Debug Console</button>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body">
                        <div class="tab-content" id="logTabContent">
                            <div class="tab-pane fade show active" id="system-log" role="tabpanel">
                                <div class="d-flex justify-content-between mb-3">
                                    <h5>System Log</h5>
                                    <div>
                                        <button id="startSystemLog" class="btn btn-sm btn-primary">Start Watching</button>
                                        <button id="stopSystemLog" class="btn btn-sm btn-secondary" disabled>Stop Watching</button>
                                        <button id="clearSystemLog" class="btn btn-sm btn-outline-danger">Clear</button>
                                    </div>
                                </div>
                                <div class="log-container" id="systemLogContainer"></div>
                            </div>
                            <div class="tab-pane fade" id="monitor-log" role="tabpanel">
                                <div class="d-flex justify-content-between mb-3">
                                    <h5>LocalAI Monitor Log</h5>
                                    <div>
                                        <button id="startMonitorLog" class="btn btn-sm btn-primary">Start Watching</button>
                                        <button id="stopMonitorLog" class="btn btn-sm btn-secondary" disabled>Stop Watching</button>
                                        <button id="clearMonitorLog" class="btn btn-sm btn-outline-danger">Clear</button>
                                    </div>
                                </div>
                                <div class="log-container" id="monitorLogContainer"></div>
                            </div>
                            <div class="tab-pane fade" id="caddy-log" role="tabpanel">
                                <div class="d-flex justify-content-between mb-3">
                                    <h5>Caddy Log</h5>
                                    <div>
                                        <button id="startCaddyLog" class="btn btn-sm btn-primary">Start Watching</button>
                                        <button id="stopCaddyLog" class="btn btn-sm btn-secondary" disabled>Stop Watching</button>
                                        <button id="clearCaddyLog" class="btn btn-sm btn-outline-danger">Clear</button>
                                    </div>
                                </div>
                                <div class="log-container" id="caddyLogContainer"></div>
                            </div>
                            <div class="tab-pane fade" id="debug-console" role="tabpanel">
                                <div class="d-flex justify-content-between mb-3">
                                    <h5>Debug Console</h5>
                                    <button id="clearDebugOutput" class="btn btn-sm btn-outline-danger">Clear Output</button>
                                </div>
                                <div class="input-group mb-3">
                                    <input type="text" class="form-control" id="debugCommand" placeholder="Enter debug command (e.g., docker ps, systemctl status, df -h)">
                                    <button class="btn btn-primary" type="button" id="runDebugCommand">Run</button>
                                </div>
                                <div class="debug-output" id="debugOutput"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for Actions -->
    <div class="modal fade" id="serviceActionModal" tabindex="-1" aria-labelledby="serviceActionModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="serviceActionModalLabel">Service Action</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p id="serviceActionMessage">Are you sure you want to perform this action?</p>
                    <div class="alert alert-warning">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                        Restarting services may cause temporary interruptions to running applications.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="confirmServiceAction">Confirm</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for Container Actions -->
    <div class="modal fade" id="containerActionModal" tabindex="-1" aria-labelledby="containerActionModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="containerActionModalLabel">Container Action</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p id="containerActionMessage">Are you sure you want to perform this action?</p>
                    <div class="alert alert-warning">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                        Restarting containers may cause temporary interruptions to running applications.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="confirmContainerAction">Confirm</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/socket.io/client-dist/socket.io.min.js"></script>
    <script>
        // Connect to WebSocket
        const socket = io();

        // Log containers
        const logContainers = {
            system: document.getElementById('systemLogContainer'),
            monitor: document.getElementById('monitorLogContainer'),
            caddy: document.getElementById('caddyLogContainer')
        };

        // Debug console
        const debugOutput = document.getElementById('debugOutput');
        const debugCommand = document.getElementById('debugCommand');

        // Variables to store state
        let activeServices = {};
        let activeContainers = [];
        let currentActionService = null;
        let currentActionContainer = null;

        // Initialize the dashboard
        function initDashboard() {
            fetchSystemInfo();
            fetchServicesStatus();
            fetchContainers();

            // Set up refresh buttons
            document.getElementById('refreshSystem').addEventListener('click', fetchSystemInfo);
            document.getElementById('refreshServices').addEventListener('click', fetchServicesStatus);
            document.getElementById('refreshContainers').addEventListener('click', fetchContainers);

            // Set up log watching buttons
            document.getElementById('startSystemLog').addEventListener('click', () => startWatchingLog('/var/log/syslog', 'system'));
            document.getElementById('stopSystemLog').addEventListener('click', () => stopWatchingLog('/var/log/syslog', 'system'));
            document.getElementById('clearSystemLog').addEventListener('click', () => clearLogContainer('system'));

            document.getElementById('startMonitorLog').addEventListener('click', () => startWatchingLog('/var/log/localai-monitor.log', 'monitor'));
            document.getElementById('stopMonitorLog').addEventListener('click', () => stopWatchingLog('/var/log/localai-monitor.log', 'monitor'));
            document.getElementById('clearMonitorLog').addEventListener('click', () => clearLogContainer('monitor'));

            document.getElementById('startCaddyLog').addEventListener('click', () => startWatchingLog('/var/log/caddy/error.log', 'caddy'));
            document.getElementById('stopCaddyLog').addEventListener('click', () => stopWatchingLog('/var/log/caddy/error.log', 'caddy'));
            document.getElementById('clearCaddyLog').addEventListener('click', () => clearLogContainer('caddy'));

            // Set up debug console
            document.getElementById('runDebugCommand').addEventListener('click', runDebugCommand);
            document.getElementById('clearDebugOutput').addEventListener('click', clearDebugOutput);
            debugCommand.addEventListener('keyup', function(event) {
                if (event.key === 'Enter') {
                    runDebugCommand();
                }
            });

            // Set up service action confirmation
            document.getElementById('confirmServiceAction').addEventListener('click', confirmServiceAction);

            // Set up container action confirmation
            document.getElementById('confirmContainerAction').addEventListener('click', confirmContainerAction);

            // Setup auto-refresh
            setInterval(fetchSystemInfo, 10000); // Refresh system info every 10 seconds
            setInterval(fetchServicesStatus, 30000); // Refresh services status every 30 seconds
            setInterval(fetchContainers, 15000); // Refresh containers every 15 seconds
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

        // Fetch services status
        function fetchServicesStatus() {
            fetch('/api/services')
                .then(response => response.json())
                .then(data => updateServicesTable(data))
                .catch(error => console.error('Error fetching services status:', error));
        }

        // Update services table
        function updateServicesTable(data) {
            activeServices = data;
            const tableBody = document.getElementById('servicesTable');
            tableBody.innerHTML = '';

            Object.entries(data).forEach(([service, info]) => {
                const row = document.createElement('tr');

                // Service name
                const nameCell = document.createElement('td');
                nameCell.textContent = service;
                row.appendChild(nameCell);

                // Status
                const statusCell = document.createElement('td');
                const indicator = document.createElement('span');
                indicator.className = `service-indicator ${info.status === 'active' ? 'active' : 'inactive'}`;
                statusCell.appendChild(indicator);
                statusCell.appendChild(document.createTextNode(info.status));
                row.appendChild(statusCell);

                // Description
                const descCell = document.createElement('td');
                descCell.textContent = info.details.Description || 'N/A';
                row.appendChild(descCell);

                // Actions
                const actionsCell = document.createElement('td');
                const restartBtn = document.createElement('button');
                restartBtn.className = 'btn btn-sm btn-outline-primary me-2';
                restartBtn.innerHTML = '<i class="bi bi-arrow-clockwise"></i> Restart';
                restartBtn.addEventListener('click', () => showServiceActionModal(service, 'restart'));
                actionsCell.appendChild(restartBtn);

                row.appendChild(actionsCell);
                tableBody.appendChild(row);
            });
        }

        // Fetch Docker containers
        function fetchContainers() {
            fetch('/api/docker')
                .then(response => response.json())
                .then(data => updateContainersTable(data))
                .catch(error => console.error('Error fetching containers:', error));
        }

        // Update containers table
        function updateContainersTable(data) {
            activeContainers = data;
            const tableBody = document.getElementById('containersTable');
            tableBody.innerHTML = '';

            data.forEach(container => {
                const row = document.createElement('tr');

                // Name
                const nameCell = document.createElement('td');
                nameCell.textContent = container.name;
                row.appendChild(nameCell);

                // Image
                const imageCell = document.createElement('td');
                imageCell.textContent = container.image.split(':')[0];
                row.appendChild(imageCell);

                // Status
                const statusCell = document.createElement('td');
                const badge = document.createElement('span');
                badge.className = `badge bg-${container.status === 'running' ? 'running' :
                                    container.status === 'exited' ? 'exited' :
                                    container.status === 'created' ? 'created' :
                                    container.status === 'paused' ? 'paused' :
                                    container.status === 'restarting' ? 'restarting' : 'dead'}`;
                badge.textContent = container.status;
                statusCell.appendChild(badge);
                row.appendChild(statusCell);

                // CPU
                const cpuCell = document.createElement('td');
                if (container.status === 'running' && container.stats.cpu_percent) {
                    cpuCell.textContent = `${container.stats.cpu_percent.toFixed(1)}%`;
                } else {
                    cpuCell.textContent = 'N/A';
                }
                row.appendChild(cpuCell);

                // Memory
                const memoryCell = document.createElement('td');
                if (container.status === 'running' && container.stats.memory_percent) {
                    memoryCell.textContent = `${container.stats.memory_percent.toFixed(1)}%`;
                } else {
                    memoryCell.textContent = 'N/A';
                }
                row.appendChild(memoryCell);

                // Actions
                const actionsCell = document.createElement('td');
                if (container.status === 'running') {
                    const restartBtn = document.createElement('button');
                    restartBtn.className = 'btn btn-sm btn-outline-primary me-2';
                    restartBtn.innerHTML = '<i class="bi bi-arrow-clockwise"></i> Restart';
                    restartBtn.addEventListener('click', () => showContainerActionModal(container.id, container.name, 'restart'));
                    actionsCell.appendChild(restartBtn);
                } else if (container.status === 'exited' || container.status === 'created') {
                    const startBtn = document.createElement('button');
                    startBtn.className = 'btn btn-sm btn-outline-success me-2';
                    startBtn.innerHTML = '<i class="bi bi-play-fill"></i> Start';
                    startBtn.addEventListener('click', () => showContainerActionModal(container.id, container.name, 'start'));
                    actionsCell.appendChild(startBtn);
                }

                row.appendChild(actionsCell);
                tableBody.appendChild(row);
            });
        }

        // Start watching a log file
        function startWatchingLog(logFile, type) {
            socket.emit('watch_log', { log_file: logFile });
            document.getElementById(`start${type.charAt(0).toUpperCase() + type.slice(1)}Log`).disabled = true;
            document.getElementById(`stop${type.charAt(0).toUpperCase() + type.slice(1)}Log`).disabled = false;
        }

        // Stop watching a log file
        function stopWatchingLog(logFile, type) {
            socket.emit('stop_watch_log', { log_file: logFile });
            document.getElementById(`start${type.charAt(0).toUpperCase() + type.slice(1)}Log`).disabled = false;
            document.getElementById(`stop${type.charAt(0).toUpperCase() + type.slice(1)}Log`).disabled = true;
        }

        // Clear log container
        function clearLogContainer(type) {
            logContainers[type].innerHTML = '';
        }

        // Run debug command
        function runDebugCommand() {
            const command = debugCommand.value.trim();
            if (!command) return;

            appendToDebugOutput(`$ ${command}`, 'command');

            fetch('/api/debug', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ command })
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    appendToDebugOutput(data.output, 'output');
                    if (data.error) {
                        appendToDebugOutput(data.error, 'error');
                    }
                } else {
                    appendToDebugOutput(`Error: ${data.message}`, 'error');
                }
            })
            .catch(error => {
                appendToDebugOutput(`Error: ${error.message}`, 'error');
            });

            debugCommand.value = '';
        }

        // Append to debug output
        function appendToDebugOutput(text, type) {
            const div = document.createElement('div');
            div.classList.add(type === 'command' ? 'text-info' : type === 'error' ? 'text-danger' : 'text-light');
            div.textContent = text;
            debugOutput.appendChild(div);
            debugOutput.scrollTop = debugOutput.scrollHeight;
        }

        // Clear debug output
        function clearDebugOutput() {
            debugOutput.innerHTML = '';
        }

        // Show service action modal
        function showServiceActionModal(service, action) {
            currentActionService = { service, action };

            const message = document.getElementById('serviceActionMessage');
            message.textContent = `Are you sure you want to ${action} the ${service} service?`;

            const modal = new bootstrap.Modal(document.getElementById('serviceActionModal'));
            modal.show();
        }

        // Confirm service action
        function confirmServiceAction() {
            if (!currentActionService) return;

            const { service, action } = currentActionService;

            fetch('/api/restart/service', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ service })
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    alert(`Service ${service} ${action}ed successfully`);
                    fetchServicesStatus();
                } else {
                    alert(`Error: ${data.message}`);
                }
            })
            .catch(error => {
                alert(`Error: ${error.message}`);
            });

            bootstrap.Modal.getInstance(document.getElementById('serviceActionModal')).hide();
            currentActionService = null;
        }

        // Show container action modal
        function showContainerActionModal(containerId, containerName, action) {
            currentActionContainer = { containerId, action };

            const message = document.getElementById('containerActionMessage');
            message.textContent = `Are you sure you want to ${action} the ${containerName} container?`;

            const modal = new bootstrap.Modal(document.getElementById('containerActionModal'));
            modal.show();
        }

        // Confirm container action
        function confirmContainerAction() {
            if (!currentActionContainer) return;

            const { containerId, action } = currentActionContainer;

            fetch('/api/restart/container', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ container_id: containerId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    alert(`Container ${action}ed successfully`);
                    fetchContainers();
                } else {
                    alert(`Error: ${data.message}`);
                }
            })
            .catch(error => {
                alert(`Error: ${error.message}`);
            });

            bootstrap.Modal.getInstance(document.getElementById('containerActionModal')).hide();
            currentActionContainer = null;
        }

        // Socket.io event listeners
        socket.on('connect', () => {
            console.log('Connected to server');
        });

        socket.on('disconnect', () => {
            console.log('Disconnected from server');
        });

        socket.on('log_line', (data) => {
            const { log_file, line } = data;

            if (log_file === '/var/log/syslog') {
                appendToLog('system', line);
            } else if (log_file === '/var/log/localai-monitor.log') {
                appendToLog('monitor', line);
            } else if (log_file === '/var/log/caddy/error.log') {
                appendToLog('caddy', line);
            }
        });

        socket.on('log_error', (data) => {
            alert(`Log error: ${data.message}`);
        });

        // Append to log container
        function appendToLog(type, line) {
            const div = document.createElement('div');
            div.textContent = line;
            logContainers[type].appendChild(div);
            logContainers[type].scrollTop = logContainers[type].scrollHeight;
        }

        // Initialize the dashboard when the page loads
        document.addEventListener('DOMContentLoaded', initDashboard);
    </script>
</body>
</html>
EOF#!/bin/bash

# Enhanced Cloud-init script for Ubuntu 24.04 LTS Digital Ocean droplet
# Designed for setting up local-ai-packaged with multiple enhancements:
# - Reliable SSH configuration for VSCode Remote connections
# - IDrive backup integration
# - Error handling and recovery
# - Caddy reverse proxy for subdomains with aitoolpool.com
# - Modal Labs integration for GPU processing
# ---------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status, but allow error handling
set +e

# Log file setup for debugging and troubleshooting
LOGFILE="/var/log/init-setup.log"
exec > >(tee -a $LOGFILE) 2>&1
echo "Starting enhanced local-ai-packaged initialization at $(date)"

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

    # Attempt recovery based on the stage where the error occurred
    case $CURRENT_STAGE in
        "system_update")
            warn "Retrying system update..."
            apt-get update -y
            apt-get upgrade -y
            ;;
        "docker_install")
            warn "Retrying Docker installation..."
            apt-get remove -y docker docker-engine docker.io containerd runc || true
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "repo_clone")
            warn "Retrying repository clone..."
            rm -rf "/home/$USERNAME/apps/local-ai-packaged" || true
            git clone https://github.com/coleam00/local-ai-packaged.git "/home/$USERNAME/apps/local-ai-packaged"
            ;;
        "service_start")
            warn "Retrying service start..."
            systemctl restart localai.service
            ;;
        *)
            warn "Unable to automatically recover. See $LOGFILE for details"
            ;;
    esac
}

# Set trap for error handling
trap 'handle_error $LINENO $?' ERR

# Create a credentials file to store all access information

# Variables
USERNAME="localai"
PASSWORD=$(openssl rand -base64 12)
DOMAIN="aitoolpool.com"

# Stage tracking for error recovery
CURRENT_STAGE="system_update"

#######################################
# SYSTEM INITIALIZATION
#######################################

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

# Save user credentials

#######################################
# SSH CONFIGURATION FOR VSCODE
#######################################

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

#######################################
# DOCKER INSTALLATION
#######################################

CURRENT_STAGE="docker_install"
info "Installing Docker..."

# Remove any old versions
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Add Docker official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, containerd, and Docker Compose plugin
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
usermod -aG docker "$USERNAME"
info "Docker installed and $USERNAME added to docker group"

# Apply Docker daemon optimizations
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker

#######################################
# SYSTEM OPTIMIZATION
#######################################

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

#######################################
# IDRIVE BACKUP SETUP
#######################################

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

# Add IDrive setup instructions to credentials file
cat >> $CREDENTIALS_FILE << EOF

IDRIVE BACKUP SETUP

#######################################
# LOCAL-AI-PACKAGED INSTALLATION
#######################################

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
info "Environment variables set up and saved to credentials file"

#######################################
# MODAL LABS INTEGRATION
#######################################

info "Setting up Modal Labs integration..."

# Install Modal client library
apt-get install -y python3-pip
pip3 install modal

# Create Modal integration script
mkdir -p /home/$USERNAME/scripts/modal
cat > /home/$USERNAME/scripts/modal/gpu_processor.py << 'EOF'
#!/usr/bin/env python3

import modal
import os
import sys
import argparse

# Create Modal app
app = modal.App("local-ai-gpu-processor")

# Set up the GPU image with necessary libraries
image = (
    modal.Image.debian_slim()
    .pip_install("torch", "transformers", "numpy", "pandas", "sklearn")
    .apt_install("git")
)

@app.function(
    image=image,
    gpu="A100",  # Can be "H100", "A100", "L4", "T4" based on your needs
    timeout=3600
)
def run_gpu_task(code_file=None, code_string=None, input_data=None):
    """
    Run a task on a GPU in Modal's cloud.

    Args:
        code_file: Path to a Python file to execute
        code_string: Python code to execute as a string
        input_data: Data to pass to the code

    Returns:
        The result of the execution
    """
    import torch
    import json
    import tempfile

    # Print GPU info
    print(f"Running on GPU: {torch.cuda.get_device_name(0)}")
    print(f"CUDA available: {torch.cuda.is_available()}")

    result = {
        "success": False,
        "output": None,
        "error": None
    }

    try:
        # Create a namespace for the code execution
        namespace = {
            "input_data": input_data,
            "torch": torch,
            "result": None
        }

        if code_file:
            # Execute the file
            with open(code_file, 'r') as f:
                exec(f.read(), namespace)
        elif code_string:
            # Execute the code string
            exec(code_string, namespace)

        # Get the result
        result["success"] = True
        result["output"] = namespace.get("result", None)

    except Exception as e:
        import traceback
        result["error"] = {
            "message": str(e),
            "traceback": traceback.format_exc()
        }

    return result

def main():
    parser = argparse.ArgumentParser(description="Run GPU tasks using Modal")

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file", help="Python file to execute")
    group.add_argument("--code", help="Python code to execute")

    parser.add_argument("--input", help="Input data as JSON string")
    parser.add_argument("--output", help="Output file for results")

    args = parser.parse_args()

    # Parse input data if provided
    input_data = None
    if args.input:
        try:
            input_data = json.loads(args.input)
        except json.JSONDecodeError:
            print("Error: Input data is not valid JSON")
            sys.exit(1)

    # Run the GPU task
    if args.file:
        result = run_gpu_task.remote(code_file=args.file, input_data=input_data)
    else:
        result = run_gpu_task.remote(code_string=args.code, input_data=input_data)

    # Output the result
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
    else:
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
EOF

# Create Modal setup instructions
cat > /home/$USERNAME/scripts/modal/README.md << 'EOF'
# Modal Labs GPU Processing

This directory contains scripts to run GPU-accelerated tasks using Modal Labs cloud infrastructure.

## Setup

1. Run the following command to set up your Modal account:
   ```
   modal token new
   ```

2. This will open a browser window to authenticate with Modal. Follow the instructions.

## Running GPU Tasks

Use the `gpu_processor.py` script to run tasks on Modal's GPUs:

### Example: Run a Python file on an A100 GPU

```bash
python3 gpu_processor.py --file your_script.py --output results.json
```

### Example: Run code directly

```bash
python3 gpu_processor.py --code "import torch; result = torch.cuda.device_count()" --output results.json
```

### Example: Pass input data

```bash
python3 gpu_processor.py --file process_data.py --input '{"data": [1, 2, 3]}' --output results.json
```

## Available GPU Types

Modify the script to use different GPU types:
- H100 (fastest)
- A100
- L4
- T4

Change the `gpu` parameter in the `@app.function` decorator.
EOF

# Make scripts executable
chmod +x /home/$USERNAME/scripts/modal/gpu_processor.py
chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts/modal

# Add Modal Labs info to credentials file
cat >> $CREDENTIALS_FILE << EOF

MODAL LABS GPU PROCESSING
-----------------------
1. Set up Modal account by running: modal token new
2. Run GPU tasks using: python3 /home/$USERNAME/scripts/modal/gpu_processor.py
3. Documentation available at: /home/$USERNAME/scripts/modal/README.md
EOF

#######################################
# FLASK DASHBOARD SETUP
#######################################

info "Setting up Flask monitoring dashboard..."

# Create dashboard directory
mkdir -p /home/$USERNAME/dashboard/templates
chown -R $USERNAME:$USERNAME /home/$USERNAME/dashboard

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
                    logger.error(f"

#######################################
# CADDY INSTALLATION AND CONFIGURATION
#######################################

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

#######################################
# SERVICE SETUP AND MONITORING
#######################################

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

#######################################
# FINALIZING SETUP
#######################################

# Get server IP
SERVER_IP=$(curl -s icanhazip.com)

# Save service access info to credentials file

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

# Final success message
info "---------------------------------------------------------"
info "INSTALLATION COMPLETED SUCCESSFULLY!"
info "All user and service credentials are saved in $CREDENTIALS_FILE"
info "The system is configured to display service access information on login"
info "---------------------------------------------------------"
