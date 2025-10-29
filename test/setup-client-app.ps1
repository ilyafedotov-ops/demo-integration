# Get API app details and create/configure client app
$ErrorActionPreference = "Stop"

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

Write-Host "`n=== Configuring D365 Demo Apps ===" -ForegroundColor Cyan

Connect-MgGraph -TenantId "f8054917-dc24-4ea5-9363-fa27b4814bbe" -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome

# Get API app details
Write-Host "`n[1/4] Getting API app details..." -ForegroundColor Yellow
$apiAppId = "757412f8-fe70-479c-afef-d4fe635a40ea"
$apiApp = Get-MgApplication -Filter "appId eq '$apiAppId'"

if ($apiApp) {
    Write-Host "[OK] API App: $($apiApp.DisplayName)" -ForegroundColor Green
    Write-Host "  App ID: $($apiApp.AppId)" -ForegroundColor Gray
    Write-Host "  Object ID: $($apiApp.Id)" -ForegroundColor Gray
    Write-Host "  Identifier URIs: $($apiApp.IdentifierUris -join ', ')" -ForegroundColor Gray
    
    # Check if service principal exists for API app
    $apiSp = Get-MgServicePrincipal -Filter "appId eq '$apiAppId'" -ErrorAction SilentlyContinue
    if (-not $apiSp) {
        Write-Host "[INFO] Creating service principal for API app..." -ForegroundColor Yellow
        $apiSp = New-MgServicePrincipal -AppId $apiAppId
        Write-Host "[OK] Service principal created" -ForegroundColor Green
    } else {
        Write-Host "[OK] Service principal exists" -ForegroundColor Green
    }
}

# Check for existing client apps
Write-Host "`n[2/4] Checking for D365 client app..." -ForegroundColor Yellow
$clientApp = Get-MgApplication -Filter "displayName eq 'D365-Demo-Client'" -ErrorAction SilentlyContinue

if (-not $clientApp) {
    Write-Host "[INFO] Client app not found, creating new one..." -ForegroundColor Yellow
    
    # Create client app
    $clientAppParams = @{
        DisplayName = "D365-Demo-Client"
        SignInAudience = "AzureADMyOrg"
    }
    
    try {
        $clientApp = New-MgApplication @clientAppParams
        Write-Host "[OK] Client app created: $($clientApp.DisplayName)" -ForegroundColor Green
        Write-Host "  App ID: $($clientApp.AppId)" -ForegroundColor Cyan
        Write-Host "  Object ID: $($clientApp.Id)" -ForegroundColor Gray
        
        # Create service principal
        $clientSp = New-MgServicePrincipal -AppId $clientApp.AppId
        Write-Host "[OK] Service principal created" -ForegroundColor Green
        
    } catch {
        Write-Host "[FAIL] Could not create client app: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Client app found: $($clientApp.DisplayName)" -ForegroundColor Green
    Write-Host "  App ID: $($clientApp.AppId)" -ForegroundColor Cyan
    Write-Host "  Object ID: $($clientApp.Id)" -ForegroundColor Gray
}

# Create client secret
Write-Host "`n[3/4] Creating client secret..." -ForegroundColor Yellow
$passwordCred = @{
    displayName = "Demo Secret $(Get-Date -Format 'yyyy-MM-dd')"
    endDateTime = (Get-Date).AddYears(1)
}

try {
    $secret = Add-MgApplicationPassword -ApplicationId $clientApp.Id -PasswordCredential $passwordCred
    Write-Host "[OK] Client secret created" -ForegroundColor Green
    Write-Host "  Secret ID: $($secret.KeyId)" -ForegroundColor Gray
    Write-Host "  Secret Value: $($secret.SecretText)" -ForegroundColor Cyan
    Write-Host "  IMPORTANT: Save this secret value now - it will not be shown again!" -ForegroundColor Yellow
} catch {
    Write-Host "[WARN] Could not create secret: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[INFO] You may need to create the secret manually in Azure Portal" -ForegroundColor Yellow
    $secret = $null
}

# Grant API permissions
Write-Host "`n[4/4] Next steps for API permissions..." -ForegroundColor Yellow
Write-Host "You need to manually grant API permissions in Azure Portal:" -ForegroundColor Yellow
Write-Host "  1. Go to https://portal.azure.com" -ForegroundColor Cyan
Write-Host "  2. Azure AD > App registrations > D365-Demo-Client > API permissions" -ForegroundColor Cyan
Write-Host "  3. Add permission > My APIs > D365-Demo-API" -ForegroundColor Cyan
Write-Host "  4. Select Application permissions > Add" -ForegroundColor Cyan
Write-Host "  5. Click 'Grant admin consent for [Tenant]'" -ForegroundColor Cyan

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
Write-Host "`nUse these credentials:" -ForegroundColor Cyan
Write-Host "Tenant ID: f8054917-dc24-4ea5-9363-fa27b4814bbe"
Write-Host "Client ID: $($clientApp.AppId)"
if ($secret) {
    Write-Host "Client Secret: $($secret.SecretText)"
}
Write-Host "API Audience: api://757412f8-fe70-479c-afef-d4fe635a40ea"
Write-Host "Subscription Key: YOUR_SUBSCRIPTION_KEY_HERE"

# Save credentials to file
$credContent = @"
# D365 Demo Credentials - Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Tenant ID: f8054917-dc24-4ea5-9363-fa27b4814bbe
Client ID: $($clientApp.AppId)
"@

if ($secret) {
    $credContent += "`nClient Secret: $($secret.SecretText)"
}

$credContent += @"

API Audience: api://757412f8-fe70-479c-afef-d4fe635a40ea
Subscription Key: YOUR_SUBSCRIPTION_KEY_HERE
APIM Endpoint: https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors

IMPORTANT: Complete API permissions configuration in Azure Portal before testing!
"@

$credContent | Out-File -FilePath "C:\Users\fedot\OneDrive\Work\Demo\Projektanfrage182914-Integration-Engineer\CREDENTIALS.txt" -Encoding UTF8
Write-Host "`nCredentials saved to: CREDENTIALS.txt" -ForegroundColor Green

Disconnect-MgGraph
