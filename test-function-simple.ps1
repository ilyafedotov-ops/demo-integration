# Test with direct vendor data (not wrapped)
$body = @{
    VendorAccount = "V-100045"
    Name = "Contoso Supplies GmbH"
    Currency = "EUR"
    CountryRegionId = "DE"
    Address = @{
        Street = "Musterstrasse 12"
        City = "Ulm"
        PostalCode = "89073"
    }
    Email = "ap@contoso-supplies.de"
    Phone = "+49 731 555123"
} | ConvertTo-Json -Depth 10

$uri = "https://demo-func-nfittwqa7bkom.azurewebsites.net/api/HttpIngest?code=YOUR_FUNCTION_KEY_HERE"

Write-Host "Testing Function App with direct vendor data..."
Write-Host "Payload: $body"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Write-Host "Success!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)"
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error Response Body: $responseBody" -ForegroundColor Yellow
    }
    if ($_.ErrorDetails) {
        Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
}
