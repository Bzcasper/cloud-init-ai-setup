# cloud-init-ai-setup
cloud-init-ai-setup.sh

I've enhanced the deployment script to meet all requirements:

1. Changed the region from NYC to San Francisco (sfo3) for both droplets.
2. Ensured the setup directory is copied over to the droplets after creation.
3. Modified the script to install each setup script one at a time on both droplets.
4. Added a step to create a markdown file (droplet-info.md) with connection details and instructions for retrieving passwords.
5. Added code to make all scripts executable both locally (using Git Bash if available) and on the droplets.

The deployment process now:
- Creates droplets in the San Francisco (sfo3) region
- Uploads all scripts from D:\cloud-init-ai-setup\setup directly
- Makes scripts executable locally and on the droplets
- Executes each setup script individually on the droplets
- Creates a droplet-info.md file with connection details and credential retrieval instructions
- Ensures reliable SSH connectivity for VS Code with extended timeouts and keep-alive settings

To redeploy with these changes, run:
```
.\deploy-droplet-auto.ps1
```

To monitor the deployment progress:
```
.\check-droplet-status.ps1          # Check default droplet
.\check-droplet-status.ps1 -All     # Check all droplets
```
