#!/bin/bash

# Script to run in Azure Cloud Shell which already has Azure CLI installed
# To use:
# 1. Go to https://shell.azure.com
# 2. Select Bash
# 3. Paste this entire script and run it

set -e

# Variables - replace these with your own values if needed
SUBSCRIPTION_ID="15c9bc5f-3900-4d84-ab5c-4ee08edda86f"
LOCATION="eastus"
RESOURCE_GROUP="rg-genrl-millz-deploy-v0.4-app"
ACR_NAME="acrgenrlmillz"
APP_SERVICE_PLAN="plan-genrl-millz-deploy-v0.4-app"
WEB_APP_NAME="app-genrl-millz-v0-4"
STORAGE_ACCOUNT="stgenrlmillzv04"
FILE_SHARE_NAME="data-share"
GITHUB_REPO="domusgpt/genrl-millz-deploy-v0.4"

# Clone repository
echo "Cloning repository..."
git clone https://github.com/$GITHUB_REPO.git
cd $(basename $GITHUB_REPO)

# Set subscription
echo "Setting subscription..."
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Get ACR credentials
echo "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query "loginServer" -o tsv)

# Create storage account
echo "Creating storage account..."
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS

# Get storage account key
echo "Getting storage account key..."
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

# Create file share
echo "Creating file share..."
az storage share create --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY

# Create App Service plan
echo "Creating App Service plan..."
az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --location $LOCATION --is-linux --sku B1

# Create Web App
echo "Creating Web App..."
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $WEB_APP_NAME --deployment-container-image-name nginx

# Configure Web App
echo "Configuring Web App..."
az webapp config container set --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --docker-custom-image-name nginx --docker-registry-server-url https://$ACR_LOGIN_SERVER

# Configure storage mount
echo "Configuring storage mount..."
az webapp config storage-account add --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME --custom-id data-mount --storage-type AzureFiles --share-name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --mount-path /home/data --access-key $STORAGE_KEY

# Get publish profile
echo "Getting publish profile..."
PUBLISH_PROFILE=$(az webapp deployment list-publishing-profiles --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --xml)

echo ""
echo "==== GITHUB SECRETS ====="
echo "You need to add these secrets to your GitHub repository:"
echo ""
echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
echo "AZURE_WEBAPP_NAME: $WEB_APP_NAME"
echo ""
echo "For AZURE_WEBAPP_PUBLISH_PROFILE, use the content below (copy all of it):"
echo ""
echo $PUBLISH_PROFILE
echo ""
echo "==== DEPLOYMENT INFO ===="
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "Web App Name: $WEB_APP_NAME"
echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "Dashboard URL: https://$WEB_APP_NAME.azurewebsites.net/dashboard"
echo ""
echo "Azure resources created successfully! Now add the GitHub secrets shown above to:"
echo "https://github.com/$GITHUB_REPO/settings/secrets/actions"