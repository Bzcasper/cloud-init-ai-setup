# Deploy a DigitalOcean droplet with Cloud-Init on Ubuntu 24.04
# Make sure doctl.exe is in PATH and you're in the right directory

$script:ErrorActionPreference = "Stop"

# Authenticate if needed
Write-Host "Authenticating with DigitalOcean CLI..." -ForegroundColor Cyan
doctl auth init

# Define droplet parameters
$dropletName = "ai-init-droplet"
$region = "nyc3"
$image = "ubuntu-24-04-x64"
$size = "s-2vcpu-4gb"
$userDataFile = "cloud-init-wrapper.yml"
$setupDir = "setup"

# Make sure the wrapper file exists
if (-Not (Test-Path $userDataFile)) {
    Write-Error "Could not find $userDataFile in this directory."
    exit 1
}

# Make sure the setup directory exists with all necessary scripts
if (-Not (Test-Path $setupDir)) {
    Write-Error "Could not find $setupDir directory with setup scripts."
    exit 1
}

# Get SSH key IDs
$sshKeys = doctl compute ssh-key list --format ID --no-header
if (-not $sshKeys) {
    Write-Error "No SSH keys found in DigitalOcean. Add one first using 'doctl compute ssh-key create'"
    exit 1
}

# Deploy the droplet
Write-Host "Deploying droplet '$dropletName' in region '$region'..." -ForegroundColor Yellow
doctl compute droplet create $dropletName `
    --region $region `
    --image $image `
    --size $size `
    --ssh-keys $sshKeys `
    --user-data-file $userDataFile `
    --wait

Write-Host "`n✅ Deployment Complete!" -ForegroundColor Green
Write-Host "Use 'doctl compute droplet list' to see IP address"
Write-Host "Use 'doctl compute ssh $dropletName' to SSH into the droplet" -ForegroundColor Green
Write-Host "Use 'doctl compute ssh $dropletName --ssh-command \"sudo apt update && sudo apt upgrade -y\"' to update the droplet" -ForegroundColor Green
Write-Host "Note: Ensure setup scripts are manually uploaded to /root/setup/ on the droplet if cloud-init does not handle it automatically." -ForegroundColor Yellow
