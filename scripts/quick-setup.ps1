# Quick Setup Script for D365 Demo with Pre-configured Credentials (PowerShell)
# This script sets up the Azure AD app registration and deploys the demo

param(
    [switch]$SkipAppRegistration,
    [string]$AppId = "",
    [string]$ClientSecret = ""
)

# Pre-configured credentials
$SUBSCRIPTION_ID = "9019cfb1-cb52-4c48-a0a8-727ad3933f34"
$TENANT_ID = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$TENANT_DOMAIN = "demoentraid123.onmicrosoft.com"
$RESOURCE_GROUP = "rg-d365-demo"
$LOCATION = "westeurope"

Write-Host "🚀 D365 Integration Demo - Quick Setup" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Subscription: $SUBSCRIPTION_ID" -ForegroundColor Cyan
Write-Host "Tenant: $TENANT_DOMAIN ($TENANT_ID)" -ForegroundColor Cyan
Write-Host "Resource Group: $RESOURCE_GROUP" -ForegroundColor Cyan
Write-Host "Location: $LOCATION" -ForegroundColor Cyan
Write-Host ""

# Check if logged in
Write-Host "Checking Azure CLI login status..." -ForegroundColor Yellow
try {
    az account show | Out-Null
    Write-Host "✅ Logged in to Azure CLI" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in to Azure CLI" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
    exit 1
}

# Set subscription
Write-Host "Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SUBSCRIPTION_ID

# Verify subscription
$currentSub = az account show --query id -o tsv
if ($currentSub -ne $SUBSCRIPTION_ID) {
    Write-Host "❌ Failed to set subscription" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Subscription set successfully" -ForegroundColor Green

# Step 1: Create Azure AD App Registration (if not skipped)
if (-not $SkipAppRegistration) {
    Write-Host ""
    Write-Host "Step 1: Creating Azure AD App Registration..." -ForegroundColor Yellow
    
    $app = az ad app create --display-name "D365 Demo API" --sign-in-audience AzureADMyOrg | ConvertFrom-Json
    $APP_ID = $app.appId
    Write-Host "✅ App ID: $APP_ID" -ForegroundColor Green

    # Create service principal
    az ad sp create --id $APP_ID | Out-Null
    Write-Host "✅ Service principal created" -ForegroundColor Green

    # Generate scope ID
    $SCOPE_ID = [System.Guid]::NewGuid().ToString()

    # Expose API scope
    $scopeJson = @{
        adminConsentDescription = "Allow the application to access D365 Demo API"
        adminConsentDisplayName = "Access D365 Demo API"
        id = $SCOPE_ID
        isEnabled = $true
        type = "User"
        userConsentDescription = "Allow the application to access D365 Demo API on your behalf"
        userConsentDisplayName = "Access D365 Demo API"
        value = "access_as_user"
    } | ConvertTo-Json -Compress

    az ad app update --id $APP_ID --set "api.oauth2PermissionScopes[0]=$scopeJson" | Out-Null
    Write-Host "✅ API scope exposed" -ForegroundColor Green

    # Create client secret
    $secret = az ad app credential reset --id $APP_ID | ConvertFrom-Json
    $CLIENT_SECRET = $secret.password
    Write-Host "✅ Client secret created" -ForegroundColor Green
} else {
    if (-not $AppId -or -not $ClientSecret) {
        Write-Host "❌ AppId and ClientSecret required when skipping app registration" -ForegroundColor Red
        exit 1
    }
    $APP_ID = $AppId
    Write-Host "✅ Using existing App ID: $APP_ID" -ForegroundColor Green
}

# Step 2: Deploy Infrastructure
Write-Host ""
Write-Host "Step 2: Deploying Infrastructure..." -ForegroundColor Yellow

# Update deployment script with actual values
$deployScript = Get-Content "scripts/deploy-one-liner.ps1" -Raw
$deployScript = $deployScript -replace "<your-app-client-id>", $APP_ID
$deployScript = $deployScript -replace "<your-d365-host-url>", ""
$deployScript = $deployScript -replace "<your-d365-access-token>", ""
Set-Content "scripts/deploy-one-liner.ps1" $deployScript

# Run deployment
Write-Host "Running deployment (this may take 5-10 minutes)..." -ForegroundColor Yellow
& "scripts/deploy-one-liner.ps1"

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "App ID: $APP_ID" -ForegroundColor Cyan
Write-Host "Client Secret: $CLIENT_SECRET" -ForegroundColor Cyan
Write-Host "Audience: api://$APP_ID" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the deployment: .\scripts\test-demo.ps1 -TenantId '$TENANT_ID' -ClientId '$APP_ID' -ClientSecret '$CLIENT_SECRET'" -ForegroundColor White
Write-Host "2. Get APIM URL: az apim show -n [APIM_NAME] -g $RESOURCE_GROUP --query 'gatewayRegionalUrl' -o tsv" -ForegroundColor White
Write-Host "3. Get JWT token for testing:" -ForegroundColor White
Write-Host "   curl -X POST 'https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token' \`" -ForegroundColor White
Write-Host "     -H 'Content-Type: application/x-www-form-urlencoded' \`" -ForegroundColor White
Write-Host "     -d 'client_id=$APP_ID&client_secret=$CLIENT_SECRET&scope=api://$APP_ID/.default&grant_type=client_credentials'" -ForegroundColor White
Write-Host ""
Write-Host "To cleanup: .\scripts\cleanup.ps1" -ForegroundColor Yellow
