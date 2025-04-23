#!/bin/bash

set -e

# Load configuration
if [ -f "$(dirname "$0")/config.env" ]; then
  source "$(dirname "$0")/config.env"
fi

# Login to Azure
echo "Logging into Azure..."
az login --username $AZURE_USERNAME

# Set subscription
echo "Setting subscription..."
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Create resource group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $AZURE_LOCATION

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
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $AZURE_LOCATION --sku Standard_LRS

# Get storage account key
echo "Getting storage account key..."
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

# Create file share
echo "Creating file share..."
az storage share create --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY

# Create App Service plan
echo "Creating App Service plan..."
az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --location $AZURE_LOCATION --is-linux --sku B1

# Create Web App
echo "Creating Web App..."
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $WEB_APP_NAME --deployment-container-image-name nginx

# Configure Web App
echo "Configuring Web App..."
az webapp config container set --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --docker-custom-image-name nginx --docker-registry-server-url https://$ACR_LOGIN_SERVER

# Configure storage mount
echo "Configuring storage mount..."
az webapp config storage-account add --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME --custom-id data-mount --storage-type AzureFiles --share-name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --mount-path $DATA_MOUNT_PATH --access-key $STORAGE_KEY

# Get publish profile
echo "Getting publish profile..."
PUBLISH_PROFILE=$(az webapp deployment list-publishing-profiles --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --xml)

# Create GitHub secrets if gh CLI is available
if command -v gh &> /dev/null; then
  echo "Setting up GitHub repository and secrets..."
  
  # Create the repository if it doesn't exist
  gh repo create $GITHUB_REPO --public --source=. --push || echo "Repository already exists or could not be created"
  
  # Set GitHub secrets
  gh secret set ACR_LOGIN_SERVER -b"$ACR_LOGIN_SERVER" -R $GITHUB_REPO
  gh secret set ACR_USERNAME -b"$ACR_USERNAME" -R $GITHUB_REPO
  gh secret set ACR_PASSWORD -b"$ACR_PASSWORD" -R $GITHUB_REPO
  gh secret set AZURE_WEBAPP_NAME -b"$WEB_APP_NAME" -R $GITHUB_REPO
  gh secret set AZURE_WEBAPP_PUBLISH_PROFILE -b"$PUBLISH_PROFILE" -R $GITHUB_REPO
  
  echo "GitHub repository and secrets set up successfully!"
fi

echo ""
echo "==== DEPLOYMENT INFO ===="
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "ACR Username: $ACR_USERNAME"
echo "ACR Password: $ACR_PASSWORD (keep this secure)"
echo "Web App Name: $WEB_APP_NAME"
echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "Dashboard URL: https://$WEB_APP_NAME.azurewebsites.net/dashboard"
echo ""
echo "==== GITHUB SECRETS ===="
echo "Add these secrets to your GitHub repository:"
echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
echo "AZURE_WEBAPP_NAME: $WEB_APP_NAME"
echo "AZURE_WEBAPP_PUBLISH_PROFILE: <copy the XML content from above>"
echo ""

# Save credentials to a local file for reference
echo "Saving credentials to azure-credentials.txt..."
cat > azure-credentials.txt << EOF
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
AZURE_WEBAPP_NAME=$WEB_APP_NAME
STORAGE_ACCOUNT=$STORAGE_ACCOUNT
STORAGE_KEY=$STORAGE_KEY
EOF

echo "Credentials saved to azure-credentials.txt"
echo ""