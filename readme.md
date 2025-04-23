# GEN-RL-MiLLzMaleficarum Azure App (v0.3)

A Node.js application for content management with persistent storage in Azure.

## Prerequisites

- Azure subscription
- GitHub account
- Docker installed (for local testing)

## Repository Structure

- `server.js` - Express.js server application
- `Dockerfile` - Container configuration
- `public/` - Frontend files
- `data/` - Local data directory (mapped to Azure File Share in production)
- `.github/workflows/main.yml` - CI/CD pipeline configuration

## Deployment

### Automated Deployment

Run the provided deployment script to set up all required Azure resources:

```bash
./azure-deploy.sh
```

This will create:
- Resource Group
- Azure Container Registry
- Storage Account with File Share
- App Service Plan
- Web App configured for container deployment

### Manual Setup

1. Create Azure resources:
   - Resource Group: `rg-genrl-millz-deploy-v0.4-app`
   - Azure Container Registry
   - Storage Account with File Share `data-share`
   - App Service Plan: `plan-genrl-millz-deploy-v0.4-app`
   - Web App with container support

2. Configure GitHub Secrets:
   - `ACR_LOGIN_SERVER`
   - `ACR_USERNAME`
   - `ACR_PASSWORD`
   - `AZURE_WEBAPP_NAME`
   - `AZURE_WEBAPP_PUBLISH_PROFILE`

3. Push to the GitHub repository to trigger deployment

## Local Development

```bash
# Install dependencies
npm install

# Start server
npm start
```

The application will be available at http://localhost:8080

## Dashboard

Access the dashboard at `/dashboard` to upload JSON data files for the application.

## Data Structure

The application uses a JSON structure stored in `/home/data/current_magazine_data.json` with the following format:

```json
{
  "cycleNumber": 0,
  "transmissionDate": "YYYY-MM-DD",
  "layoutConfiguration": {
    "templateName": "standard-grid",
    "featuredVisualTargetId": "main-content-id",
    "moduleOrder": ["module-id-1", "module-id-2"]
  },
  "mainContent": [
    {
      "type": "directive",
      "id": "module-id-1",
      "title": "Content Title",
      "content": "<p>HTML content...</p>"
    }
  ],
  "footerMantra": "Footer text",
  "styleOverrides": {}
}
```