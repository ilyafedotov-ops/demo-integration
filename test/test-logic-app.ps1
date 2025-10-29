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

$uri = "https://prod-246.westeurope.logic.azure.com:443/workflows/2903f138fd63498da803b70a6be4dec5/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=HhKSLAmaDfBb3vKJ7_Mp395mYnNZIXh3_NyFMxgSxHI"

Write-Host "Sending request to Logic App..."
Write-Host "Payload: $body"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Write-Host "Success!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
    exit 0
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)"
    }
    if ($_.ErrorDetails) {
        Write-Host "Response: $($_.ErrorDetails.Message)"
    }
    exit 1
}
