# Test with detailed error handling
$clientId = "5e973595-34cc-42b3-b290-857aeeab580a"
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientSecret = "YOUR_CLIENT_SECRET_HERE"
$subscriptionKey = "YOUR_SUBSCRIPTION_KEY_HERE"
$apimEndpoint = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"
$scope = "api://757412f8-fe70-479c-afef-d4fe635a40ea/.default"

Write-Host "`n=== Testing with Detailed Error Handling ===" -ForegroundColor Cyan

# Get token
$tokenBody = @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token
Write-Host "[OK] JWT token acquired" -ForegroundColor Green

# Submit data with detailed error
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

Write-Host "`nPayload being sent:" -ForegroundColor Yellow
Write-Host $vendorPayload -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Ocp-Apim-Subscription-Key" = $subscriptionKey
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-WebRequest -Uri $apimEndpoint -Method POST -Headers $headers -Body $vendorPayload -UseBasicParsing
    
    Write-Host "`n[OK] Success! Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    
} catch {
    Write-Host "`n[FAIL] Request failed" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    
    $responseStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($responseStream)
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response Body: $responseBody" -ForegroundColor Red
}
