# deploy-droplet-auto.ps1
# Automates droplet deletion, creation, SSH setup, and VS Code configuration

# Step 1: Delete all existing droplets
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

# Step 2: Generate a new SSH key
Write-Output "Generating a new SSH key..."
ssh-keygen -t rsa -b 4096 -C "robertmcasper@gmail.com" -f "C:\Users\rober\.ssh\id_rsa_auto" -N "" -q

# Step 3: Add the SSH key to DigitalOcean
Write-Output "Adding SSH key to DigitalOcean..."
$publicKey = Get-Content -Path "C:\Users\rober\.ssh\id_rsa_auto.pub" -Raw
$keyName = "rober-auto-$(Get-Date -Format yyyyMMddHHmmss)"
$keyResponse = doctl compute ssh-key create $keyName --public-key "$publicKey" --format FingerPrint --no-header
$fingerprint = $keyResponse.Trim()
Write-Output "Added SSH key with fingerprint: $fingerprint"

# Step 4: Create new droplets with the SSH key
Write-Output "Creating new droplets..."
# Create ai-init-droplet
$initDroplet = doctl compute droplet create ai-init-droplet --region sfo3 --image ubuntu-24-04-x64 --size s-2vcpu-4gb --ssh-keys "$fingerprint" --wait --format PublicIPv4 --no-header
$initIp = $initDroplet.Trim()
Write-Output "Created ai-init-droplet with IP: $initIp"

# Create ai-kit
$kitDroplet = doctl compute droplet create ai-kit --region sfo3 --image ubuntu-24-04-x64 --size s-2vcpu-4gb --ssh-keys "$fingerprint" --wait --format PublicIPv4 --no-header
$kitIp = $kitDroplet.Trim()
Write-Output "Created ai-kit with IP: $kitIp"

# Step 5: Start the SSH agent and add the private key
Write-Output "Starting SSH agent and adding private key..."
Start-Service ssh-agent -ErrorAction SilentlyContinue
ssh-add "C:\Users\rober\.ssh\id_rsa_auto"

# Step 6: Test SSH access (optional, for logging)
Write-Output "Testing SSH access..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "echo 'SSH successful for ai-init-droplet'" 2>&1 | Write-Output
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "echo 'SSH successful for ai-kit'" 2>&1 | Write-Output

# Step 7: Update the SSH config file for VS Code
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

# Step 8: Copy setup directory to droplets (without installation)
Write-Output "Copying setup directory to droplets..."
Invoke-Expression "scp -i 'C:\Users\rober\.ssh\id_rsa_auto' -o StrictHostKeyChecking=no -r 'D:\cloud-init-ai-setup\setup' 'root@$initIp`:/root/setup'"
Invoke-Expression "scp -i 'C:\Users\rober\.ssh\id_rsa_auto' -o StrictHostKeyChecking=no -r 'D:\cloud-init-ai-setup\setup' 'root@$kitIp`:/root/setup'"
Write-Output "Setup directory copied to both droplets."

# Step 9: Make scripts executable on droplets
Write-Output "Making scripts executable on droplets..."
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$initIp "chmod -R +x /root/setup"
ssh -i "C:\Users\rober\.ssh\id_rsa_auto" -o StrictHostKeyChecking=no root@$kitIp "chmod -R +x /root/setup"
Write-Output "Scripts made executable on both droplets."

Write-Output "Deployment complete! Connect to droplets in VS Code using Remote-SSH extension."
Write-Output "Select 'ai-init-droplet' or 'ai-kit' from the Remote-SSH: Connect to Host menu."
Write-Output "Setup directory has been copied to /root/setup on each droplet. You can manually install it when ready."
