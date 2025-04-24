# Final version of install-obsidian.ps1
# Logs deployment details into your Obsidian vault

# 🛠️ CONFIGURATION
$vaultPath = "C:\Users\rober\Cloud-Drive\__Documents\Bobbys_Life\Trap_Stories\DigitalOcean"
$projectName = "ai-init-droplet"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$projectPath = Join-Path $vaultPath "Deployments\$projectName\$timestamp"

# 📁 Create timestamped deployment folder
New-Item -ItemType Directory -Path $projectPath -Force | Out-Null

# 📝 Write deployment note
$deploymentNote = @"
# Deployment Log: $projectName
**Deployed At:** $timestamp
**Machine:** Ubuntu 24.04 LTS
**Type:** s-2vcpu-4gb
**Region:** nyc3
**User:** root
**Cloud Init Script:** cloud-init-ai-setup.sh
**Wrapper:** cloud-init-wrapper.yml

---

## Quick Access Commands

- SSH: `ssh root@<your-droplet-ip>`
- Log: `/var/log/init-setup.log`

---

## Resources

- GitHub Repo: [bzcasper/cloud-init-ubuntu24](https://github.com/bzcasper/cloud-init-ubuntu24)
- Raw Script: [cloud-init-ai-setup.sh](https://raw.githubusercontent.com/bzcasper/cloud-init-ubuntu24/main/cloud-init-ai-setup.sh)

"@
Set-Content -Path "$projectPath\deployment-info.md" -Value $deploymentNote

# 🗃 Save local and remote init scripts
Copy-Item ".\cloud-init-wrapper.yml" -Destination "$projectPath\cloud-init-wrapper.yml" -Force

Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/bzcasper/cloud-init-ubuntu24/main/cloud-init-ai-setup.sh" `
    -OutFile "$projectPath\cloud-init-ai-setup.sh"

Write-Host "✅ Deployment logged to Obsidian vault:" -ForegroundColor Green
Write-Host "$projectPath" -ForegroundColor Yellow
