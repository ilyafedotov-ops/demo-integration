param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"

Write-Host "Testing with Microsoft Graph scope instead..." -ForegroundColor Yellow
Write-Host ""

# Try with Microsoft Graph scope instead
$scope = "https://graph.microsoft.com/.default"

$tokenBody = @{
    client_id     = $clientId
    client_secret = $ClientSecret
    scope         = $scope
    grant_type    = "client_credentials"
}

try {
    Write-Host "Requesting token with scope: $scope" -ForegroundColor Cyan
    $tokenResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded"
    
    Write-Host ""
    Write-Host "SUCCESS! Token obtained from Azure AD" -ForegroundColor Green
    Write-Host ""
    Write-Host "This proves:" -ForegroundColor Cyan
    Write-Host "  + Tenant ID is correct: $tenantId" -ForegroundColor Green
    Write-Host "  + Client ID is correct: $clientId" -ForegroundColor Green
    Write-Host "  + Client Secret is valid" -ForegroundColor Green
    Write-Host ""
    Write-Host "The issue is that the app doesn't have 'Expose an API' configured." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To fix this, you need to:" -ForegroundColor Yellow
    Write-Host "1. Go to Azure Portal > Azure AD > App registrations > D365-Demo-API"
    Write-Host "2. Click 'Expose an API' in the left menu"
    Write-Host "3. Click '+ Add a scope'"
    Write-Host "4. Accept the default Application ID URI: api://$clientId"
    Write-Host "5. Add scope:"
    Write-Host "   - Scope name: access_as_user"
    Write-Host "   - Who can consent: Admins and users"
    Write-Host "   - Admin consent display name: Access D365 Demo API"
    Write-Host "   - Admin consent description: Allow access to D365 Demo API"
    Write-Host "   - State: Enabled"
    Write-Host "6. Save"
    Write-Host ""
    Write-Host "After that, run the original test again."
    
} catch {
    Write-Host ""
    Write-Host "Still failed - this might be a different issue" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
    
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Azure AD Error: $($errorObj.error)"
        Write-Host "Description: $($errorObj.error_description)"
    }
}
