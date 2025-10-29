# Test Mock D365 OData endpoint
$baseUrl = "https://demo-func-nfittwqa7bkom.azurewebsites.net/api/data/Vendors"

Write-Host "Testing Mock D365 OData Endpoint" -ForegroundColor Cyan
Write-Host "================================`n"

# Test GET (list vendors)
Write-Host "1. Testing GET /data/Vendors (List Vendors)" -ForegroundColor Yellow
try {
    $getResponse = Invoke-RestMethod -Uri $baseUrl -Method Get
    Write-Host "Success!" -ForegroundColor Green
    Write-Host "Found $($getResponse.value.Count) vendors:"
    $getResponse.value | Format-Table VendorAccount, Name, Currency, CountryRegionId -AutoSize
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. Testing POST /data/Vendors (Create Vendor)" -ForegroundColor Yellow
$newVendor = @{
    VendorAccount = "V-100099"
    Name = "Test Vendor Corp"
    Currency = "EUR"
    CountryRegionId = "FR"
    Address = @{
        Street = "123 Test Avenue"
        City = "Paris"
        PostalCode = "75001"
    }
    Email = "contact@testvendor.fr"
    Phone = "+33123456789"
} | ConvertTo-Json -Depth 10

try {
    $postResponse = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $newVendor -ContentType "application/json"
    Write-Host "Success!" -ForegroundColor Green
    Write-Host "Created Vendor:"
    $postResponse | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
