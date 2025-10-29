# Get API app details and create/configure client app
$ErrorActionPreference = "Stop"

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

Write-Host "`n=== Configuring D365 Demo Apps ===" -ForegroundColor Cyan

Connect-MgGraph -TenantId "f8054917-dc24-4ea5-9363-fa27b4814bbe" -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome

# Get API app details
Write-Host "`n[1/4] Getting API app details..." -ForegroundColor Yellow
$apiApp = Get-MgApplication -Filter "appId eq ''757412f8-fe70-479c-afef-d4fe635a40ea''"

if ($apiApp) {
    Write-Host "[OK] API App: $($apiApp.DisplayName)" -ForegroundColor Green
    Write-Host "  App ID: $($apiApp.AppId)" -ForegroundColor Gray
    Write-Host "  Object ID: $($apiApp.Id)" -ForegroundColor Gray
    Write-Host "  Identifier URIs: $($apiApp.IdentifierUris -join '', '')" -ForegroundColor Gray
    
    # Check if service principal exists for API app
    $apiSp = Get-MgServicePrincipal -Filter "appId eq ''757412f8-fe70-479c-afef-d4fe635a40ea''" -ErrorAction SilentlyContinue
    if (-not $apiSp) {
        Write-Host "[INFO] Creating service principal for API app..." -ForegroundColor Yellow
        $apiSp = New-MgServicePrincipal -AppId "757412f8-fe70-479c-afef-d4fe635a40ea"
        Write-Host "[OK] Service principal created" -ForegroundColor Green
    } else {
        Write-Host "[OK] Service principal exists" -ForegroundColor Green
    }
}

# Check for existing client apps
Write-Host "`n[2/4] Checking for D365 client app..." -ForegroundColor Yellow
$clientApp = Get-MgApplication -Filter "displayName eq ''D365-Demo-Client''" -ErrorAction SilentlyContinue

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
    displayName = "Demo Secret $(Get-Date -Format ''yyyy-MM-dd'')"
    endDateTime = (Get-Date).AddYears(1)
}

try {
    $secret = Add-MgApplicationPassword -ApplicationId $clientApp.Id -PasswordCredential $passwordCred
    Write-Host "[OK] Client secret created" -ForegroundColor Green
    Write-Host "  Secret ID: $($secret.KeyId)" -ForegroundColor Gray
    Write-Host "  Secret Value: $($secret.SecretText)" -ForegroundColor Cyan
    Write-Host "  IMPORTANT: Save this secret value now - it won''t be shown again!" -ForegroundColor Yellow
} catch {
    Write-Host "[FAIL] Could not create secret: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[INFO] You may need to create the secret manually in Azure Portal" -ForegroundColor Yellow
}

# Grant API permissions
Write-Host "`n[4/4] Configuring API permissions..." -ForegroundColor Yellow
Write-Host "[INFO] You need to manually grant API permissions in Azure Portal:" -ForegroundColor Yellow
Write-Host "  1. Go to App registrations > D365-Demo-Client > API permissions" -ForegroundColor Cyan
Write-Host "  2. Add permission > My APIs > D365-Demo-API" -ForegroundColor Cyan
Write-Host "  3. Select Application permissions > Add" -ForegroundColor Cyan
Write-Host "  4. Click ''Grant admin consent''" -ForegroundColor Cyan

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
Write-Host "`nClient App Credentials:" -ForegroundColor Cyan
Write-Host "  Tenant ID: f8054917-dc24-4ea5-9363-fa27b4814bbe" -ForegroundColor White
Write-Host "  Client ID: $($clientApp.AppId)" -ForegroundColor White
if ($secret) {
    Write-Host "  Client Secret: $($secret.SecretText)" -ForegroundColor White
}
Write-Host "  API Audience: api://757412f8-fe70-479c-afef-d4fe635a40ea" -ForegroundColor White
Write-Host "  Subscription Key: YOUR_SUBSCRIPTION_KEY_HERE" -ForegroundColor White

# Save credentials to file
$credFile = @"
# D365 Demo Credentials - $(Get-Date -Format ''yyyy-MM-dd HH:mm'')

`$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
`$clientId = "$($clientApp.AppId)"
`$clientSecret = "$($secret.SecretText)"
`$subscriptionKey = "YOUR_SUBSCRIPTION_KEY_HERE"
`$apiAudience = "api://757412f8-fe70-479c-afef-d4fe635a40ea"
`$apimEndpoint = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"
"@

$credFile | Out-File -FilePath "credentials.txt" -Encoding UTF8
Write-Host "`nCredentials saved to: credentials.txt" -ForegroundColor Green

Disconnect-MgGraph
