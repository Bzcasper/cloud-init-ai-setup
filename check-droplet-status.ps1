# Enhanced check-droplet-status.ps1
# Get latest droplet info and monitor setup logs remotely for both droplets

param (
    [Parameter()]
    [string]$DropletName = "ai-init-droplet",  # Default to ai-init-droplet, but can be overridden

    [Parameter()]
    [switch]$All = $false  # Flag to check all droplets
)

# Function to check a single droplet
function Check-Droplet {
    param (
        [string]$Name
    )

    Write-Host "`n=======================================================" -ForegroundColor Cyan
    Write-Host "Checking droplet: $Name" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan

    # Get droplet info
    $droplet = doctl compute droplet list --no-header --format Name,PublicIPv4,Region | Where-Object { $_ -like "$Name*" }

    if (-not $droplet) {
        Write-Host "❌ Droplet '$Name' not found." -ForegroundColor Red
        return
    }

    $dropletInfo = $droplet -split '\s+'
    $dropletIP = $dropletInfo[1]
    $region = $dropletInfo[2]

    Write-Host "🌐 Droplet '$Name' found at IP: $dropletIP (Region: $region)" -ForegroundColor Cyan

    # Wait for SSH to become available
    Write-Host "`n🔍 Waiting for SSH to respond..." -ForegroundColor Yellow
    $timeout = 60  # Timeout in seconds
    $timer = [Diagnostics.Stopwatch]::StartNew()

    while (-not (Test-NetConnection -ComputerName $dropletIP -Port 22 -InformationLevel Quiet)) {
        if ($timer.Elapsed.TotalSeconds -gt $timeout) {
            Write-Host "⚠️ Timeout waiting for SSH to respond. The droplet might still be initializing." -ForegroundColor Yellow
            return
        }

        Start-Sleep -Seconds 5
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }

    Write-Host "`n✅ SSH is active! Connecting and streaming setup logs..." -ForegroundColor Green

    # Check if the log file exists
    $logExists = ssh -o StrictHostKeyChecking=no root@$dropletIP "test -f /var/log/init-setup.log && echo 'exists' || echo 'not found'"

    if ($logExists -eq "exists") {
        # Stream setup log
        Write-Host "`n📋 Last 20 lines of setup log:" -ForegroundColor Magenta
        ssh -o StrictHostKeyChecking=no root@$dropletIP "tail -n 20 /var/log/init-setup.log"

        Write-Host "`n🔄 Now streaming log in real-time (press Ctrl+C to stop):" -ForegroundColor Magenta
        ssh -o StrictHostKeyChecking=no root@$dropletIP "tail -f /var/log/init-setup.log"
    } else {
        Write-Host "`n⚠️ Setup log file not found. The cloud-init process might still be initializing." -ForegroundColor Yellow

        # Check cloud-init status
        Write-Host "`n📋 Cloud-init status:" -ForegroundColor Magenta
        ssh -o StrictHostKeyChecking=no root@$dropletIP "cloud-init status"

        Write-Host "`n📋 Last 20 lines of cloud-init log:" -ForegroundColor Magenta
        ssh -o StrictHostKeyChecking=no root@$dropletIP "tail -n 20 /var/log/cloud-init.log"
    }
}

# Main script execution
if ($All) {
    # Check all droplets
    $droplets = doctl compute droplet list --no-header --format Name | ForEach-Object { $_.Trim() }

    if (-not $droplets) {
        Write-Host "❌ No droplets found." -ForegroundColor Red
        exit 1
    }

    foreach ($droplet in $droplets) {
        Check-Droplet -Name $droplet
    }
} else {
    # Check only the specified droplet
    Check-Droplet -Name $DropletName
}

Write-Host "`n✅ Droplet status check complete." -ForegroundColor Green
Write-Host "To check a specific droplet, run: ./check-droplet-status.ps1 -DropletName <name>" -ForegroundColor Cyan
Write-Host "To check all droplets, run: ./check-droplet-status.ps1 -All" -ForegroundColor Cyan
