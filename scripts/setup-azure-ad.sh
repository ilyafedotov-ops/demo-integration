#!/usr/bin/env bash
# Azure AD App Registration Setup for D365 Demo
# This script creates the necessary Azure AD app registration for JWT validation

set -e

echo "Creating Azure AD App Registration for D365 Demo..."

# Create app registration
echo "Creating app registration..."
APP_ID=$(az ad app create --display-name "D365 Demo API" --sign-in-audience AzureADMyOrg --query "appId" -o tsv)
echo "App ID: $APP_ID"

# Create service principal
echo "Creating service principal..."
az ad sp create --id $APP_ID > /dev/null

# Generate a UUID for the scope
SCOPE_ID=$(uuidgen)

# Expose API scope
echo "Exposing API scope..."
az ad app update --id $APP_ID --set api.oauth2PermissionScopes[0]="{
  \"adminConsentDescription\": \"Allow the application to access D365 Demo API\",
  \"adminConsentDisplayName\": \"Access D365 Demo API\",
  \"id\": \"$SCOPE_ID\",
  \"isEnabled\": true,
  \"type\": \"User\",
  \"userConsentDescription\": \"Allow the application to access D365 Demo API on your behalf\",
  \"userConsentDisplayName\": \"Access D365 Demo API\",
  \"value\": \"access_as_user\"
}"

# Create client secret
echo "Creating client secret..."
CLIENT_SECRET=$(az ad app credential reset --id $APP_ID --query "password" -o tsv)

# Use provided tenant ID
TENANT_ID="DE353337165"

echo ""
echo "=========================================="
echo "Azure AD App Registration Complete!"
echo "=========================================="
echo "Tenant ID: $TENANT_ID"
echo "App ID (Client ID): $APP_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Audience: api://$APP_ID"
echo ""
echo "Update your deployment scripts with these values:"
echo "  TENANT_ID=\"$TENANT_ID\""
echo "  APP_ID=\"$APP_ID\""
echo ""
echo "To get a test JWT token, use:"
echo "curl -X POST \"https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token\" \\"
echo "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "  -d \"client_id=$APP_ID&client_secret=$CLIENT_SECRET&scope=api://$APP_ID/.default&grant_type=client_credentials\""
echo "=========================================="
