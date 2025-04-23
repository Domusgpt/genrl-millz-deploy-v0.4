#!/bin/bash

# Full deployment script to run on a Linux system
# This script requires Azure CLI and GitHub CLI to be installed

set -e

# Variables - replace these with your own values if needed
SUBSCRIPTION_ID="15c9bc5f-3900-4d84-ab5c-4ee08edda86f"
AZURE_USERNAME="phillips.paul.email@gmail.com"
LOCATION="eastus"
RESOURCE_GROUP="rg-genrl-millz-deploy-v0.4-app"
ACR_NAME="acrgenrlmillz"
APP_SERVICE_PLAN="plan-genrl-millz-deploy-v0.4-app"
WEB_APP_NAME="app-genrl-millz-v0-4"
STORAGE_ACCOUNT="stgenrlmillzv04"
FILE_SHARE_NAME="data-share"
GITHUB_REPO="domusgpt/genrl-millz-deploy-v0.4"

echo "=== GEN-RL-MiLLzMaleficarum App v0.3 Full Deployment ==="
echo ""

# Install required tools if not present
if ! command -v az &> /dev/null; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh
fi

# Login to Azure
echo "Logging into Azure..."
az login --username $AZURE_USERNAME

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

# Login to GitHub and configure repository
echo "Logging into GitHub..."
gh auth login

# Configure GitHub repository
echo "Setting up GitHub repository..."
if ! gh repo view $GITHUB_REPO &> /dev/null; then
    echo "Creating GitHub repository..."
    gh repo create $GITHUB_REPO --public
fi

# Configure GitHub remote
git remote set-url origin https://github.com/$GITHUB_REPO.git || git remote add origin https://github.com/$GITHUB_REPO.git

# Add GitHub secrets
echo "Adding GitHub secrets..."
gh secret set ACR_LOGIN_SERVER --body "$ACR_LOGIN_SERVER" -R $GITHUB_REPO
gh secret set ACR_USERNAME --body "$ACR_USERNAME" -R $GITHUB_REPO
gh secret set ACR_PASSWORD --body "$ACR_PASSWORD" -R $GITHUB_REPO
gh secret set AZURE_WEBAPP_NAME --body "$WEB_APP_NAME" -R $GITHUB_REPO
gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body "$PUBLISH_PROFILE" -R $GITHUB_REPO

# Push to GitHub
echo "Pushing code to GitHub..."
git push -u origin master

echo ""
echo "==== DEPLOYMENT INFO ===="
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "Web App Name: $WEB_APP_NAME"
echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "Dashboard URL: https://$WEB_APP_NAME.azurewebsites.net/dashboard"
echo ""
echo "GitHub Repository: https://github.com/$GITHUB_REPO"
echo "GitHub Actions: https://github.com/$GITHUB_REPO/actions"
echo ""
echo "Deployment complete! The GitHub Actions workflow should now be building and deploying the application."
echo "Check the GitHub Actions tab for progress and the Web App URL for the deployed application."