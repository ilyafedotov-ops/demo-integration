#!/usr/bin/env bash
# Quick Setup Script for D365 Demo with Pre-configured Credentials
# This script sets up the Azure AD app registration and deploys the demo

set -e

# Pre-configured credentials
SUBSCRIPTION_ID="9019cfb1-cb52-4c48-a0a8-727ad3933f34"
TENANT_ID="f8054917-dc24-4ea5-9363-fa27b4814bbe"
TENANT_DOMAIN="demoentraid123.onmicrosoft.com"
RESOURCE_GROUP="rg-d365-demo"
LOCATION="westeurope"

echo "🚀 D365 Integration Demo - Quick Setup"
echo "======================================"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Tenant: $TENANT_DOMAIN ($TENANT_ID)"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""

# Check if logged in
echo "Checking Azure CLI login status..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure CLI"
    echo "Please run: az login"
    exit 1
fi

# Set subscription
echo "Setting subscription..."
az account set --subscription $SUBSCRIPTION_ID

# Verify subscription
CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]; then
    echo "❌ Failed to set subscription"
    exit 1
fi
echo "✅ Subscription set successfully"

# Step 1: Create Azure AD App Registration
echo ""
echo "Step 1: Creating Azure AD App Registration..."
APP_ID=$(az ad app create --display-name "D365 Demo API" --sign-in-audience AzureADMyOrg --query "appId" -o tsv)
echo "✅ App ID: $APP_ID"

# Create service principal
az ad sp create --id $APP_ID > /dev/null
echo "✅ Service principal created"

# Generate scope ID
SCOPE_ID=$(uuidgen)

# Expose API scope
az ad app update --id $APP_ID --set api.oauth2PermissionScopes[0]="{
  \"adminConsentDescription\": \"Allow the application to access D365 Demo API\",
  \"adminConsentDisplayName\": \"Access D365 Demo API\",
  \"id\": \"$SCOPE_ID\",
  \"isEnabled\": true,
  \"type\": \"User\",
  \"userConsentDescription\": \"Allow the application to access D365 Demo API on your behalf\",
  \"userConsentDisplayName\": \"Access D365 Demo API\",
  \"value\": \"access_as_user\"
}" > /dev/null
echo "✅ API scope exposed"

# Create client secret
CLIENT_SECRET=$(az ad app credential reset --id $APP_ID --query "password" -o tsv)
echo "✅ Client secret created"

# Step 2: Deploy Infrastructure
echo ""
echo "Step 2: Deploying Infrastructure..."

# Update deployment script with actual values
sed -i "s/<your-app-client-id>/$APP_ID/g" scripts/deploy-one-liner.sh
sed -i "s/<your-d365-host-url>//g" scripts/deploy-one-liner.sh
sed -i "s/<your-d365-access-token>//g" scripts/deploy-one-liner.sh

# Run deployment
echo "Running deployment (this may take 5-10 minutes)..."
bash scripts/deploy-one-liner.sh

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo "App ID: $APP_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Audience: api://$APP_ID"
echo ""
echo "📋 Next Steps:"
echo "1. Test the deployment: bash scripts/test-demo.sh"
echo "2. Get APIM URL: az apim show -n <APIM_NAME> -g $RESOURCE_GROUP --query 'gatewayRegionalUrl' -o tsv"
echo "3. Get JWT token for testing:"
echo "   curl -X POST 'https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token' \\"
echo "     -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "     -d 'client_id=$APP_ID&client_secret=$CLIENT_SECRET&scope=api://$APP_ID/.default&grant_type=client_credentials'"
echo ""
echo "🧹 To cleanup: bash scripts/cleanup.sh"
