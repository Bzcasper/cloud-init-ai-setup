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
while (-not (Test-NetConnection -ComputerName $initIp -Port 22 -InformationLevel Quiet)) {
    Start-Sleep -Seconds 5
    Write-Output "Still waiting for SSH on ai-init-droplet..."
}

Write-Output "Waiting for SSH to become available on ai-kit..."
while (-not (Test-NetConnection -ComputerName $kitIp -Port 22 -InformationLevel Quiet)) {
    Start-Sleep -Seconds 5
    Write-Output "Still waiting for SSH on ai-kit..."
}

# Step 9: Test SSH access
Write-Output "Testing SSH access..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "echo 'SSH successful for ai-init-droplet'" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "echo 'SSH successful for ai-kit'" 2>&1 | Write-Output

# Step 10: Upload setup scripts to both droplets
Write-Output "Uploading setup scripts to droplets..."

# Create setup directory on droplets
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "mkdir -p /root/setup" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "mkdir -p /root/setup" 2>&1 | Write-Output

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

# Step 11: Make scripts executable and run main.sh
Write-Output "Making scripts executable and running main.sh on both droplets..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "chmod +x /root/setup/*.sh && /root/setup/main.sh > /var/log/init-setup.log 2>&1 &" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "chmod +x /root/setup/*.sh && /root/setup/main.sh > /var/log/init-setup.log 2>&1 &" 2>&1 | Write-Output

# Step 12: Update the SSH config file for VS Code
Write-Output "Configuring VS Code SSH access..."
Set-Content -Path "C:\Users\rober\.ssh\config" -Value @"
Host ai-init-droplet
    HostName $initIp
    User root
    IdentityFile C:\Users\rober\.ssh\id_rsa_auto

Host ai-kit
    HostName $kitIp
    User root
    IdentityFile C:\Users\rober\.ssh\id_rsa_auto
"@

Write-Output "Deployment complete! Connect to droplets in VS Code using Remote-SSH extension."
Write-Output "Select 'ai-init-droplet' or 'ai-kit' from the Remote-SSH: Connect to Host menu."
Write-Output ""
Write-Output "To monitor setup progress, run: ./check-droplet-status.ps1"
Write-Output "Or manually check logs with: ssh root@$initIp 'tail -f /var/log/init-setup.log'"
