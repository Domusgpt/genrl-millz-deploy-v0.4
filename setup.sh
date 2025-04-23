#!/bin/bash

# Main setup script that orchestrates the entire deployment

# Load configuration
if [ -f "$(dirname "$0")/config.env" ]; then
  source "$(dirname "$0")/config.env"
fi

echo "=== GEN-RL-MiLLzMaleficarum App v0.3 Setup ==="
echo ""

# Step 1: Set up GitHub repository
echo "Step 1: Setting up GitHub repository"
if [ -f "$(dirname "$0")/github-setup.sh" ]; then
  bash "$(dirname "$0")/github-setup.sh"
else
  echo "GitHub setup script not found. Please create the repository manually."
fi
echo ""

# Step 2: Deploy Azure resources
echo "Step 2: Deploying Azure resources"
if command -v az &> /dev/null; then
  if [ -f "$(dirname "$0")/azure-deploy.sh" ]; then
    bash "$(dirname "$0")/azure-deploy.sh"
  else
    echo "Azure deployment script not found."
  fi
else
  echo "Azure CLI not installed. Please follow the manual setup guide:"
  echo "$(dirname "$0")/azure-portal-setup.md"
fi
echo ""

echo "Setup completed!"
echo ""
echo "Please check the status report for next steps:"
echo "$(dirname "$0")/STATUS_REPORT_20250422_v0.3.md"
echo ""