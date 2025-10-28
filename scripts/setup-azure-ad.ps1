# Azure AD App Registration Setup for D365 Demo
# This script creates the necessary Azure AD app registration for JWT validation

Write-Host "Creating Azure AD App Registration for D365 Demo..." -ForegroundColor Green

# Create app registration
Write-Host "Creating app registration..." -ForegroundColor Yellow
$app = az ad app create --display-name "D365 Demo API" --sign-in-audience AzureADMyOrg | ConvertFrom-Json
$APP_ID = $app.appId
Write-Host "App ID: $APP_ID" -ForegroundColor Cyan

# Create service principal
Write-Host "Creating service principal..." -ForegroundColor Yellow
az ad sp create --id $APP_ID | Out-Null

# Generate a UUID for the scope
$SCOPE_ID = [System.Guid]::NewGuid().ToString()

# Expose API scope
Write-Host "Exposing API scope..." -ForegroundColor Yellow
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

# Create client secret
Write-Host "Creating client secret..." -ForegroundColor Yellow
$secret = az ad app credential reset --id $APP_ID | ConvertFrom-Json
$CLIENT_SECRET = $secret.password

# Use provided tenant ID
$TENANT_ID = "DE353337165"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Azure AD App Registration Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Tenant ID: $TENANT_ID" -ForegroundColor Cyan
Write-Host "App ID (Client ID): $APP_ID" -ForegroundColor Cyan
Write-Host "Client Secret: $CLIENT_SECRET" -ForegroundColor Cyan
Write-Host "Audience: api://$APP_ID" -ForegroundColor Cyan
Write-Host ""
Write-Host "Update your deployment scripts with these values:" -ForegroundColor Yellow
Write-Host "  `$TENANT='$TENANT_ID'" -ForegroundColor White
Write-Host "  `$APP='$APP_ID'" -ForegroundColor White
Write-Host ""
Write-Host "To get a test JWT token, use:" -ForegroundColor Yellow
Write-Host "curl -X POST `"https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token`" \`" -ForegroundColor White
Write-Host "  -H `"Content-Type: application/x-www-form-urlencoded`" \`" -ForegroundColor White
Write-Host "  -d `"client_id=$APP_ID&client_secret=$CLIENT_SECRET&scope=api://$APP_ID/.default&grant_type=client_credentials`"" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Green
