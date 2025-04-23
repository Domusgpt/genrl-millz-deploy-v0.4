#!/bin/bash

# Load configuration
if [ -f "$(dirname "$0")/config.env" ]; then
  source "$(dirname "$0")/config.env"
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI not installed. Please install it first:"
  echo "https://cli.github.com/manual/installation"
  exit 1
fi

# Login to GitHub
echo "Logging into GitHub..."
echo $GITHUB_TOKEN | gh auth login --with-token

# Create repository if it doesn't exist
echo "Creating GitHub repository if it doesn't exist..."
gh repo create $GITHUB_REPO --public --source=. --push || echo "Repository already exists or could not be created"

# Check if we need to create the repo without source
if [ $? -ne 0 ]; then
  echo "Trying to create repo without source..."
  gh repo create $GITHUB_REPO --public || echo "Repository already exists"
  
  # Configure git and push
  git remote set-url origin https://$GITHUB_TOKEN@github.com/$GITHUB_REPO.git
  git push -u origin master
fi

echo "GitHub repository setup complete. URL: https://github.com/$GITHUB_REPO"