param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"

Write-Host "Testing JWT Token Acquisition..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Tenant ID: $tenantId"
Write-Host "  Client ID: $clientId"
Write-Host "  Token Endpoint: https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
Write-Host ""

$scope = "api://$clientId/.default"
$tokenBody = @{
    client_id     = $clientId
    client_secret = $ClientSecret
    scope         = $scope
    grant_type    = "client_credentials"
}

Write-Host "Request Parameters:" -ForegroundColor Cyan
Write-Host "  client_id: $clientId"
Write-Host "  scope: $scope"
Write-Host "  grant_type: client_credentials"
Write-Host "  client_secret: [PROVIDED]"
Write-Host ""

try {
    Write-Host "Sending request to Azure AD..." -ForegroundColor Yellow
    $tokenResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded" `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Host "SUCCESS! Token obtained" -ForegroundColor Green
    Write-Host ""
    Write-Host "Token Details:" -ForegroundColor Cyan
    Write-Host "  Token Type: $($tokenResponse.token_type)"
    Write-Host "  Expires In: $($tokenResponse.expires_in) seconds"
    Write-Host "  Scope: $($tokenResponse.scope)"
    Write-Host ""
    
    # Decode JWT to show claims
    $token = $tokenResponse.access_token
    $tokenParts = $token.Split('.')
    if ($tokenParts.Count -eq 3) {
        $payload = $tokenParts[1]
        # Add padding if needed
        while ($payload.Length % 4 -ne 0) { $payload += "=" }
        $payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
        $claims = $payloadJson | ConvertFrom-Json
        
        Write-Host "JWT Claims:" -ForegroundColor Cyan
        Write-Host "  Issuer (iss): $($claims.iss)"
        Write-Host "  Audience (aud): $($claims.aud)"
        Write-Host "  App ID (appid): $($claims.appid)"
        Write-Host "  Tenant ID (tid): $($claims.tid)"
        Write-Host "  Issued At: $(Get-Date -Date ((Get-Date -Date "1970-01-01").AddSeconds($claims.iat)))"
        Write-Host "  Expires At: $(Get-Date -Date ((Get-Date -Date "1970-01-01").AddSeconds($claims.exp)))"
        Write-Host ""
    }
    
    Write-Host "Token is valid and can be used for APIM!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "FAILED to get token" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host "  Message: $($_.Exception.Message)"
    
    if ($_.ErrorDetails.Message) {
        try {
            $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host ""
            Write-Host "Azure AD Error Response:" -ForegroundColor Yellow
            Write-Host "  Error: $($errorObj.error)"
            Write-Host "  Description: $($errorObj.error_description)"
            Write-Host ""
            
            if ($errorObj.error -eq "invalid_client") {
                Write-Host "Troubleshooting 'invalid_client':" -ForegroundColor Cyan
                Write-Host "  - Client secret is wrong or expired"
                Write-Host "  - Client ID doesn't match the secret"
                Write-Host "  - Secret not yet propagated (wait 1-2 minutes)"
                Write-Host ""
                Write-Host "Solution:" -ForegroundColor Green
                Write-Host "  1. Go to Azure Portal"
                Write-Host "  2. Azure AD > App registrations > D365-Demo-API"
                Write-Host "  3. Certificates & secrets"
                Write-Host "  4. Create NEW client secret"
                Write-Host "  5. Copy the VALUE immediately"
                Write-Host "  6. Wait 1 minute, then retry"
            } elseif ($errorObj.error -eq "invalid_scope") {
                Write-Host "Troubleshooting 'invalid_scope':" -ForegroundColor Cyan
                Write-Host "  - App doesn't have exposed API configured"
                Write-Host "  - Scope format incorrect"
                Write-Host ""
                Write-Host "Solution:" -ForegroundColor Green
                Write-Host "  1. Azure AD > App registrations > D365-Demo-API"
                Write-Host "  2. Expose an API"
                Write-Host "  3. Add scope: access_as_user"
            }
        } catch {
            Write-Host "  Raw Error: $($_.ErrorDetails.Message)"
        }
    }
    
    exit 1
}
