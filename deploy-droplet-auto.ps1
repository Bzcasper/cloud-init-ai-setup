# deploy-droplet-auto.ps1
# Automates droplet deletion, creation, SSH setup, and VS Code configuration
# Enhanced version with San Francisco region and local setup script integration

# Set error action preference to stop on errors
$script:ErrorActionPreference = "Stop"

# Define paths and configuration
$setupDir = "D:\cloud-init-ai-setup\setup"
$userDataFile = "cloud-init-wrapper.yml"
$region = "sfo3"  # San Francisco region
$image = "ubuntu-24-04-x64"
$size = "s-2vcpu-4gb"  # Increased resources for better performance

# Step 1: Validate setup directory exists
Write-Output "Validating setup directory..."
if (-Not (Test-Path $setupDir)) {
    Write-Error "Setup directory not found at $setupDir. Please check the path and try again."
    exit 1
}

# Step 2: Validate cloud-init wrapper file exists
Write-Output "Validating cloud-init wrapper file..."
if (-Not (Test-Path $userDataFile)) {
    Write-Error "Cloud-init wrapper file not found at $userDataFile. Please check the path and try again."
    exit 1
}

# Step 3: Delete all existing droplets
Write-Output "Deleting all existing droplets..."
$droplets = doctl compute droplet list --format ID --no-header
if ($droplets) {
    foreach ($id in $droplets) {
        doctl compute droplet delete $id -f
        Write-Output "Deleted droplet with ID: $id"
    }
}
else {
    Write-Output "No droplets found to delete."
}

# Step 4: Generate a new SSH key
Write-Output "Generating a new SSH key..."
ssh-keygen -t rsa -b 4096 -C "robertmcasper@gmail.com" -f "C:\Users\rober\.ssh\id_rsa_auto" -N "" -q

# Step 5: Add the SSH key to DigitalOcean
Write-Output "Adding SSH key to DigitalOcean..."
$publicKey = Get-Content -Path "C:\Users\rober\.ssh\id_rsa_auto.pub" -Raw
$keyName = "rober-auto-$(Get-Date -Format yyyyMMddHHmmss)"
$keyResponse = doctl compute ssh-key create $keyName --public-key "$publicKey" --format FingerPrint --no-header
$fingerprint = $keyResponse.Trim()
Write-Output "Added SSH key with fingerprint: $fingerprint"

# Step 6: Create new droplets with the SSH key
Write-Output "Creating new droplets in San Francisco region ($region)..."

# Create ai-init-droplet
$initDroplet = doctl compute droplet create ai-init-droplet `
    --region $region `
    --image $image `
    --size $size `
    --ssh-keys "$fingerprint" `
    --user-data-file $userDataFile `
    --wait `
    --format PublicIPv4 `
    --no-header
$initIp = $initDroplet.Trim()
Write-Output "Created ai-init-droplet with IP: $initIp"

# Create ai-kit
$kitDroplet = doctl compute droplet create ai-kit `
    --region $region `
    --image $image `
    --size $size `
    --ssh-keys "$fingerprint" `
    --user-data-file $userDataFile `
    --wait `
    --format PublicIPv4 `
    --no-header
$kitIp = $kitDroplet.Trim()
Write-Output "Created ai-kit with IP: $kitIp"

# Step 7: Start the SSH agent and add the private key
Write-Output "Starting SSH agent and adding private key..."
Start-Service ssh-agent -ErrorAction SilentlyContinue
ssh-add "C:\Users\rober\.ssh\id_rsa_auto"

# Step 8: Wait for SSH to become available on both droplets
Write-Output "Waiting for SSH to become available on ai-init-droplet..."
$timeoutSeconds = 300  # 5 minutes timeout
$startTime = Get-Date
while (-not (Test-NetConnection -ComputerName $initIp -Port 22 -InformationLevel Quiet)) {
    if (((Get-Date) - $startTime).TotalSeconds -gt $timeoutSeconds) {
        Write-Error "Timeout waiting for SSH on ai-init-droplet. Please check the droplet status manually."
        exit 1
    }
    Start-Sleep -Seconds 10
    Write-Output "Still waiting for SSH on ai-init-droplet... (Elapsed: $((Get-Date) - $startTime).TotalSeconds seconds)"
}

Write-Output "Waiting for SSH to become available on ai-kit..."
$startTime = Get-Date
while (-not (Test-NetConnection -ComputerName $kitIp -Port 22 -InformationLevel Quiet)) {
    if (((Get-Date) - $startTime).TotalSeconds -gt $timeoutSeconds) {
        Write-Error "Timeout waiting for SSH on ai-kit. Please check the droplet status manually."
        exit 1
    }
    Start-Sleep -Seconds 10
    Write-Output "Still waiting for SSH on ai-kit... (Elapsed: $((Get-Date) - $startTime).TotalSeconds seconds)"
}

# Step 9: Test SSH access
Write-Output "Testing SSH access..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "echo 'SSH successful for ai-init-droplet'" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "echo 'SSH successful for ai-kit'" 2>&1 | Write-Output

# Step 9.1: Ensure SSH service is running on droplets
Write-Output "Ensuring SSH service is running on ai-init-droplet..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "systemctl restart sshd" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "systemctl status sshd" 2>&1 | Write-Output

Write-Output "Ensuring SSH service is running on ai-kit..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "systemctl restart sshd" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "systemctl status sshd" 2>&1 | Write-Output

# Step 10: Upload setup scripts to both droplets
Write-Output "Uploading setup scripts to droplets..."

# Create setup directory on droplets
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "mkdir -p /root/setup" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "mkdir -p /root/setup" 2>&1 | Write-Output

# Make scripts executable locally
Write-Output "Making scripts executable locally..."
Get-ChildItem -Path "$setupDir\*.sh" | ForEach-Object {
    $scriptPath = $_.FullName
    Write-Output "Setting executable flag on $scriptPath..."
    # Use git bash or similar to set executable flag on Windows if available
    if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
        & "C:\Program Files\Git\bin\bash.exe" -c "chmod +x '$scriptPath'"
    }
}

# Upload all setup scripts to ai-init-droplet
Write-Output "Uploading setup scripts to ai-init-droplet..."
Get-ChildItem -Path "$setupDir\*.sh" | ForEach-Object {
    $scriptName = $_.Name
    Write-Output "Uploading $scriptName..."
    scp -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no "$setupDir\$scriptName" "root@${initIp}:/root/setup/$scriptName"
}

# Upload all setup scripts to ai-kit
Write-Output "Uploading setup scripts to ai-kit..."
Get-ChildItem -Path "$setupDir\*.sh" | ForEach-Object {
    $scriptName = $_.Name
    Write-Output "Uploading $scriptName..."
    scp -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no "$setupDir\$scriptName" "root@${kitIp}:/root/setup/$scriptName"
}

# Step 11: Make scripts executable and run each script one at a time
Write-Output "Making scripts executable and running each script one at a time on both droplets..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "chmod +x /root/setup/*.sh" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "chmod +x /root/setup/*.sh" 2>&1 | Write-Output

Write-Output "Running scripts on ai-init-droplet..."
$scripts = Get-ChildItem -Path "$setupDir\*.sh" | Sort-Object Name
foreach ($script in $scripts) {
    $scriptName = $script.Name
    Write-Output "Running $scriptName on ai-init-droplet..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "/root/setup/$scriptName >> /var/log/init-setup.log 2>&1" 2>&1 | Write-Output
}

Write-Output "Running scripts on ai-kit..."
foreach ($script in $scripts) {
    $scriptName = $script.Name
    Write-Output "Running $scriptName on ai-kit..."
    ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "/root/setup/$scriptName >> /var/log/init-setup.log 2>&1" 2>&1 | Write-Output
}

# Step 12: Update the SSH config file for VS Code
Write-Output "Configuring VS Code SSH access..."
Set-Content -Path "C:\Users\rober\.ssh\config" -Value @"
Host ai-init-droplet
    HostName $initIp
    User root
    IdentityFile C:\Users\rober\.ssh\id_rsa_auto
    ServerAliveInterval 60
    ServerAliveCountMax 10
    TCPKeepAlive yes

Host ai-kit
    HostName $kitIp
    User root
    IdentityFile C:\Users\rober\.ssh\id_rsa_auto
    ServerAliveInterval 60
    ServerAliveCountMax 10
    TCPKeepAlive yes
"@

Write-Output "Deployment complete! Connect to droplets in VS Code using Remote-SSH extension."
Write-Output "Select 'ai-init-droplet' or 'ai-kit' from the Remote-SSH: Connect to Host menu."
Write-Output ""
Write-Output "To monitor setup progress, run: ./check-droplet-status.ps1"
Write-Output "Or manually check logs with: ssh root@$initIp 'tail -f /var/log/init-setup.log'"

# Step 13: Create a markdown file with droplet information and credentials
Write-Output "Creating droplet-info.md with connection details and credentials..."
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Set-Content -Path "droplet-info.md" -Value @"
# Droplet Information
Generated on: $timestamp

## ai-init-droplet
- IP Address: $initIp
- Region: $region
- SSH User: root
- SSH Key: C:\Users\rober\.ssh\id_rsa_auto

## ai-kit
- IP Address: $kitIp
- Region: $region
- SSH User: root
- SSH Key: C:\Users\rober\.ssh\id_rsa_auto

## Credentials
- Note: Passwords for services will be available in /root/credentials.txt on each droplet after setup completes.
- To retrieve credentials, use: ssh root@$initIp 'cat /root/credentials.txt'

## Connection Instructions
1. Open VS Code
2. Use the Remote-SSH extension
3. Select 'ai-init-droplet' or 'ai-kit' from the Connect to Host menu
"@
Write-Output "droplet-info.md created with connection details."
