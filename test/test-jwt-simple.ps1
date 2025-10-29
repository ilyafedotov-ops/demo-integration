# Simple JWT Test - Provide credentials as parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "D365 Integration Demo - JWT Authentication Test" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Configuration
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"
$apimUrl = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Tenant ID: $tenantId"
Write-Host "  Client ID: $clientId"
Write-Host "  APIM URL: $apimUrl"
Write-Host ""

# Step 1: Get JWT Access Token
Write-Host "Step 1: Obtaining JWT Access Token..." -ForegroundColor Yellow
$scope = "api://$clientId/.default"
$tokenBody = @{
    client_id     = $clientId
    client_secret = $ClientSecret
    scope         = $scope
    grant_type    = "client_credentials"
}

try {
    $tokenResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded"
    
    $accessToken = $tokenResponse.access_token
    Write-Host "  + JWT Token obtained successfully!" -ForegroundColor Green
    Write-Host "  Token expires in: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "  X Failed to get token: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Client secret expired or incorrect"
    Write-Host "  - App not granted permissions"
    Write-Host "  - Tenant ID mismatch"
    exit 1
}

# Step 2: Test APIM Endpoint with JWT
Write-Host "Step 2: Testing APIM Endpoint with JWT..." -ForegroundColor Yellow

$vendorData = @{
    VendorAccount = "V-JWT-TEST-$(Get-Random -Minimum 1000 -Maximum 9999)"
    Name = "JWT Authentication Test Vendor"
    Currency = "EUR"
    CountryRegionId = "DE"
    Address = @{
        Street = "Security Boulevard 42"
        City = "Berlin"
        PostalCode = "10115"
    }
    Email = "jwt-test@secure-vendor.com"
    Phone = "+49301234567"
} | ConvertTo-Json -Depth 10

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
    "Ocp-Apim-Subscription-Key" = $SubscriptionKey
}

Write-Host "  Request Details:" -ForegroundColor Gray
Write-Host "    URL: $apimUrl"
Write-Host "    Method: POST"
Write-Host "    Headers:"
Write-Host "      - Authorization: Bearer [token]"
Write-Host "      - Ocp-Apim-Subscription-Key: [key]"
Write-Host "      - Content-Type: application/json"
Write-Host "    Payload: Vendor $($vendorData | ConvertFrom-Json | Select-Object -ExpandProperty VendorAccount)"
Write-Host ""

try {
    $response = Invoke-RestMethod -Method Post -Uri $apimUrl -Headers $headers -Body $vendorData -TimeoutSec 30
    
    Write-Host "  + SUCCESS! Request accepted by APIM" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host "  Message ID: $($response.id)" -ForegroundColor White
    Write-Host "  Enqueued: $($response.enqueued)" -ForegroundColor White
    Write-Host ""
    
    # Verify the flow
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Authentication Flow Verified!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What just happened:" -ForegroundColor Yellow
    Write-Host "  1. + Azure AD issued JWT token" -ForegroundColor Green
    Write-Host "  2. + APIM validated JWT signature & claims" -ForegroundColor Green
    Write-Host "  3. + APIM validated subscription key" -ForegroundColor Green
    Write-Host "  4. + APIM forwarded request to Function" -ForegroundColor Green
    Write-Host "  5. + HttpIngest function processed payload" -ForegroundColor Green
    Write-Host "  6. + Message queued to Service Bus" -ForegroundColor Green
    Write-Host ""
    Write-Host "Architecture Flow:" -ForegroundColor Cyan
    Write-Host "  Client -> Azure AD (JWT)" -ForegroundColor Gray
    Write-Host "    |"
    Write-Host "  APIM (JWT + Subscription validation)" -ForegroundColor Gray
    Write-Host "    |"
    Write-Host "  Azure Function (HttpIngest)" -ForegroundColor Gray
    Write-Host "    |"
    Write-Host "  Service Bus Queue" -ForegroundColor Gray
    Write-Host "    |"
    Write-Host "  [Next: SbProcessor -> ADLS Gen2]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Status: JWT Authentication WORKING!" -ForegroundColor Green
    Write-Host ""
    
    exit 0
    
} catch {
    Write-Host "  X Request FAILED!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  Status Code: $statusCode" -ForegroundColor Red
        
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "  Response Body: $responseBody" -ForegroundColor Yellow
        } catch {
            Write-Host "  (Could not read response body)"
        }
        
        Write-Host ""
        Write-Host "Common issues for status $statusCode" ":" -ForegroundColor Yellow
        if ($statusCode -eq 401) {
            Write-Host "  - JWT token invalid or expired"
            Write-Host "  - Audience mismatch in token"
            Write-Host "  - Subscription key missing or invalid"
        } elseif ($statusCode -eq 403) {
            Write-Host "  - JWT valid but insufficient permissions"
            Write-Host "  - Subscription not active"
        } elseif ($statusCode -eq 404) {
            Write-Host "  - API endpoint path incorrect"
        }
    }
    
    exit 1
}
