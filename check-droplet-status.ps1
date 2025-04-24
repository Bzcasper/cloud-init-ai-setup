# check-droplet-status.ps1
# Checks the status of DigitalOcean droplets

param (
    [switch]$All
)

$logFile = "D:\cloud-init-ai-setup\status.log"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Output "$timestamp - $Message"
}

# Get droplet information
$droplets = doctl compute droplet list --format "ID,Name,PublicIPv4,Region" --no-header
if (-not $droplets) {
    Write-Log "No droplets found."
    exit 1
}

foreach ($droplet in $droplets) {
    $id, $name, $ip, $region = $droplet -split "\s+"

    if (-not $All -and $name -ne "ai-init-droplet") {
        continue
    }

    Write-Log "Checking droplet: $name (ID: $id, IP: $ip, Region: $region)"

    # Check SSH availability (timeout after 2 minutes)
    Write-Log "Checking SSH availability for $name..."
    $timeout = (Get-Date).AddMinutes(2)
    $sshAvailable = $false
    while ((Get-Date) -lt $timeout) {
        $sshTest = ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$ip "echo 'SSH test'" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SSH is available on $name"
            $sshAvailable = $true
            break
        }
        Start-Sleep -Seconds 10
    }

    if (-not $sshAvailable) {
        Write-Log "ERROR: SSH not available on $name after 2 minutes."
        continue
    }

    # Get system info
    Write-Log "Getting system info for $name..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$ip "uname -a; df -h /; free -h; uptime" 2>&1 | Tee-Object -FilePath $logFile -Append

    # Check setup directory
    Write-Log "Checking setup directory on $name..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$ip "ls -l /root/setup" 2>&1 | Tee-Object -FilePath $logFile -Append

    # Check setup logs
    Write-Log "Checking setup logs for $name..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$ip "cat /var/log/setup.log" 2>&1 | Tee-Object -FilePath $logFile -Append

    # Check credentials file
    Write-Log "Checking credentials file on $name..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$ip "cat /root/credentials.txt" 2>&1 | Tee-Object -FilePath $logFile -Append
}

Write-Log "Status check complete."
