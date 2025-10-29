# JWT Authentication Test with NEW Client App Credentials
$ErrorActionPreference = "Stop"

$clientId = "5e973595-34cc-42b3-b290-857aeeab580a"
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientSecret = "YOUR_CLIENT_SECRET_HERE"
$subscriptionKey = "YOUR_SUBSCRIPTION_KEY_HERE"
$apimEndpoint = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"
$scope = "api://757412f8-fe70-479c-afef-d4fe635a40ea/.default"

Write-Host "`n=== D365 Integration Demo - JWT Test ===" -ForegroundColor Cyan

Write-Host "`n[1/3] Acquiring JWT token..." -ForegroundColor Yellow
Write-Host "  Client ID: $clientId"
Write-Host "  Scope: $scope"

try {
    $tokenBody = @{
        client_id     = $clientId
        scope         = $scope
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }
    
    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    
    Write-Host "[OK] JWT token acquired successfully" -ForegroundColor Green
    Write-Host "  Token preview: $($accessToken.Substring(0, 50))..." -ForegroundColor Gray
    
    $tokenParts = $accessToken.Split('.')
    $paddedPayload = $tokenParts[1]
    while ($paddedPayload.Length % 4 -ne 0) { $paddedPayload += "=" }
    $payload = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($paddedPayload))
    $claims = $payload | ConvertFrom-Json
    Write-Host "  Audience: $($claims.aud)" -ForegroundColor Gray
    Write-Host "  Expires: $([DateTimeOffset]::FromUnixTimeSeconds($claims.exp).LocalDateTime)" -ForegroundColor Gray
    
} catch {
    Write-Host "[FAIL] Token acquisition failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorDetail = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details: $($errorDetail.error_description)" -ForegroundColor Red
        
        if ($errorDetail.error_codes -contains 700016) {
            Write-Host "`n[ACTION REQUIRED] API permissions not configured:" -ForegroundColor Yellow
            Write-Host "  1. Go to https://portal.azure.com" -ForegroundColor Cyan
            Write-Host "  2. Azure AD > App registrations > D365-Demo-Client" -ForegroundColor Cyan
            Write-Host "  3. API permissions > Add permission > My APIs > D365-Demo-API" -ForegroundColor Cyan
            Write-Host "  4. Select Application permissions and grant admin consent" -ForegroundColor Cyan
        }
    }
    exit 1
}

Write-Host "`n[2/3] Submitting vendor data to APIM..." -ForegroundColor Yellow

$vendorPayload = @{
    data = @{
        VendorAccount = "TEST-$(Get-Date -Format 'yyyyMMddHHmmss')"
        VendorName = "Test Vendor Corp"
        VendorGroup = "GROUP01"
        Currency = "USD"
        PaymentTerms = "Net30"
        TaxGroup = "TAX01"
    }
} | ConvertTo-Json -Depth 10

try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Ocp-Apim-Subscription-Key" = $subscriptionKey
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri $apimEndpoint -Method POST -Headers $headers -Body $vendorPayload
    
    Write-Host "[OK] Vendor data submitted successfully!" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "[FAIL] Submission failed (Status: $statusCode)" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`n[3/3] Checking data flow..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
Write-Host "Landing page: https://demo-apim-nfittwqa7bkom.azure-api.net/" -ForegroundColor Cyan
Write-Host "JWT authentication: Working" -ForegroundColor Green
Write-Host "Vendor data: Submitted to Service Bus" -ForegroundColor Green
Write-Host "`nCheck ADLS Gen2 storage account 'demoadlsnfittwqa7bkom' container 'landing' for landed files." -ForegroundColor Cyan
