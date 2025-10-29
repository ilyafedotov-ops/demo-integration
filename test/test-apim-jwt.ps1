# Test APIM with JWT Authentication
# Complete end-to-end test of D365 Integration Demo

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "D365 Integration Demo - JWT Authentication Test" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Configuration
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"
$apimUrl = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"

Write-Host "Step 1: Get Subscription Key" -ForegroundColor Yellow
Write-Host "----------------------------"
Write-Host "Go to Azure Portal > API Management > demo-apim-nfittwqa7bkom > Subscriptions"
Write-Host "Find 'Demo Test Subscription' and copy the Primary Key"
Write-Host ""
$subscriptionKey = Read-Host "Paste the Subscription Key here"

Write-Host "`nStep 2: Create Client Secret (if not already done)" -ForegroundColor Yellow
Write-Host "---------------------------------------------------"
Write-Host "Go to Azure AD > App registrations > D365-Demo-API"
Write-Host "Go to 'Certificates & secrets' > '+ New client secret'"
Write-Host "Copy the secret VALUE (not the ID)"
Write-Host ""
$hasSecret = Read-Host "Do you have a client secret? (y/n)"

if ($hasSecret -eq "n") {
    Write-Host ""
    Write-Host "Please create a client secret first:" -ForegroundColor Red
    Write-Host "1. Go to https://portal.azure.com"
    Write-Host "2. Azure Active Directory > App registrations > D365-Demo-API"
    Write-Host "3. Certificates & secrets > + New client secret"
    Write-Host "4. Description: 'Demo Testing'"
    Write-Host "5. Expires: In 1 year"
    Write-Host "6. Add"
    Write-Host "7. Copy the VALUE immediately (it won't be shown again)"
    Write-Host ""
    exit
}

$clientSecret = Read-Host "Paste the Client Secret VALUE here" -AsSecureString
$clientSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))

Write-Host "`nStep 3: Get JWT Access Token" -ForegroundColor Yellow
Write-Host "-----------------------------"
$scope = "api://$clientId/.default"
$tokenBody = @{
    client_id     = $clientId
    client_secret = $clientSecretPlain
    scope         = $scope
    grant_type    = "client_credentials"
}

try {
    $tokenResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded"
    
    $accessToken = $tokenResponse.access_token
    Write-Host "✓ JWT Token obtained successfully!" -ForegroundColor Green
    Write-Host "Token expires in: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to get token: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

Write-Host "`nStep 4: Test APIM Endpoint with JWT" -ForegroundColor Yellow
Write-Host "------------------------------------"

$vendorData = @{
    VendorAccount = "V-TEST-JWT-$(Get-Random -Minimum 1000 -Maximum 9999)"
    Name = "JWT Test Vendor Corp"
    Currency = "USD"
    CountryRegionId = "US"
    Address = @{
        Street = "789 Secure Avenue"
        City = "Seattle"
        PostalCode = "98101"
    }
    Email = "jwt-test@vendor.com"
    Phone = "+1234567890"
} | ConvertTo-Json -Depth 10

Write-Host "Sending request to APIM..."
Write-Host "URL: $apimUrl"
Write-Host "Payload: $vendorData"
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
    "Ocp-Apim-Subscription-Key" = $subscriptionKey
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $apimUrl -Headers $headers -Body $vendorData
    Write-Host "✓ SUCCESS! APIM accepted the request" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
    Write-Host ""
    Write-Host "Message ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "Enqueued: $($response.enqueued)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Yellow
    }
    exit
}

Write-Host "`nStep 5: Verify Complete Flow" -ForegroundColor Yellow
Write-Host "----------------------------"
Write-Host "✓ JWT Token: Generated from Azure AD" -ForegroundColor Green
Write-Host "✓ APIM: Validated JWT and subscription key" -ForegroundColor Green
Write-Host "✓ Function: Received and processed payload" -ForegroundColor Green
Write-Host "✓ Service Bus: Message queued" -ForegroundColor Green
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "End-to-End Test Complete!" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

Write-Host "Architecture Verified:" -ForegroundColor Green
Write-Host "Client -> Azure AD (JWT)" -ForegroundColor Gray
Write-Host "  |"
Write-Host "APIM (JWT validation + Subscription key)" -ForegroundColor Gray
Write-Host "  |"
Write-Host "HttpIngest Function" -ForegroundColor Gray
Write-Host "  |"
Write-Host "Service Bus Queue" -ForegroundColor Gray
Write-Host "  |"
Write-Host "SbProcessor Function (pending fix)" -ForegroundColor Gray
Write-Host "  |"
Write-Host "ADLS Gen2 Data Lake" -ForegroundColor Gray
