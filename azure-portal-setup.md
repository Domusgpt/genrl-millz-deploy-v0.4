# Azure Portal Manual Setup Guide

If you prefer to set up the Azure resources manually through the portal, follow these steps:

## 1. Create Resource Group

1. Go to the [Azure Portal](https://portal.azure.com)
2. Search for "Resource groups"
3. Click "Create"
4. Enter the following details:
   - Subscription: Your subscription
   - Resource group name: `rg-genrl-millz-deploy-v0.4-app`
   - Region: East US
5. Click "Review + create", then "Create"

## 2. Create Storage Account and File Share

1. In the resource group, click "Create"
2. Search for "Storage account"
3. Click "Create"
4. Enter the following details:
   - Subscription: Your subscription
   - Resource group: `rg-genrl-millz-deploy-v0.4-app`
   - Storage account name: `stgenrlmillzv04`
   - Region: East US
   - Performance: Standard
   - Redundancy: Locally Redundant Storage (LRS)
5. Click "Review + create", then "Create"
6. Once created, go to the storage account
7. Click on "File shares" under "Data storage"
8. Click "File share"
9. Enter name: `data-share`
10. Click "Create"

## 3. Create Azure Container Registry

1. In the resource group, click "Create"
2. Search for "Container registry"
3. Click "Create"
4. Enter the following details:
   - Subscription: Your subscription
   - Resource group: `rg-genrl-millz-deploy-v0.4-app`
   - Registry name: `acrgenrlmillz`
   - Location: East US
   - SKU: Basic
5. Click "Review + create", then "Create"

## 4. Create App Service Plan and Web App

1. In the resource group, click "Create"
2. Search for "App Service Plan"
3. Click "Create"
4. Enter the following details:
   - Subscription: Your subscription
   - Resource group: `rg-genrl-millz-deploy-v0.4-app`
   - Name: `plan-genrl-millz-deploy-v0.4-app`
   - Operating System: Linux
   - Region: East US
   - Pricing plan: B1 Basic
5. Click "Review + create", then "Create"
6. Once created, in the resource group, click "Create"
7. Search for "Web App"
8. Click "Create"
9. Enter the following details:
   - Subscription: Your subscription
   - Resource group: `rg-genrl-millz-deploy-v0.4-app`
   - Name: `app-genrl-millz-v0-4`
   - Publish: Docker Container
   - Operating System: Linux
   - Region: East US
   - Linux Plan: `plan-genrl-millz-deploy-v0.4-app`
10. Click "Next: Docker"
11. Set the following:
    - Options: Single Container
    - Image Source: Azure Container Registry
    - Registry: `acrgenrlmillz`
    - Image: (this will be set by GitHub Actions)
    - Tag: (this will be set by GitHub Actions)
12. Click "Review + create", then "Create"

## 5. Configure Storage Mount for Web App

1. Go to your Web App: `app-genrl-millz-v0-4`
2. Click on "Configuration" under "Settings"
3. Click on "Path mappings" tab
4. Click "New Azure Storage Mount"
5. Enter the following details:
   - Name: `data-mount`
   - Storage Type: Azure Files
   - Storage Account: `stgenrlmillzv04`
   - Storage Account Key: (get from storage account > Access keys)
   - Share name: `data-share`
   - Mount path: `/home/data`
6. Click "OK", then "Save"

## 6. Get Publish Profile for GitHub Actions

1. Go to your Web App: `app-genrl-millz-v0-4`
2. Click on "Get publish profile" (download a file)
3. Open the downloaded file - this contains the XML needed for GitHub Actions

## 7. Configure GitHub Repository Secrets

1. Go to your GitHub repository: https://github.com/domusgpt/genrl-millz-deploy-v0.4
2. Go to "Settings" > "Secrets and variables" > "Actions"
3. Add the following secrets:
   - `ACR_LOGIN_SERVER`: `acrgenrlmillz.azurecr.io`
   - `ACR_USERNAME`: `acrgenrlmillz`
   - `ACR_PASSWORD`: (get from ACR > Access keys)
   - `AZURE_WEBAPP_NAME`: `app-genrl-millz-v0-4`
   - `AZURE_WEBAPP_PUBLISH_PROFILE`: (paste the entire XML content from the publish profile file)

## 8. Push Code to GitHub Repository

Push your code to the GitHub repository to trigger the GitHub Actions workflow that will build and deploy your application.