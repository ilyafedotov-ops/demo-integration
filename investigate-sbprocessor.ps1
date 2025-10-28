# Try to invoke SbProcessor directly to see the error
Write-Host "Checking Function App status..."

$funcAppName = "demo-func-nfittwqa7bkom"
$resourceGroup = "rg-d365-demo-v2"

# Get function details
Write-Host "Getting SbProcessor function details..."
$funcDetails = az functionapp function show `
    --name $funcAppName `
    --resource-group $resourceGroup `
    --function-name SbProcessor `
    --query "{name:name, invokeUrlTemplate:invokeUrlTemplate}" `
    -o json | ConvertFrom-Json

Write-Host "Function: $($funcDetails.name)"

# Check app settings
Write-Host "`nChecking required app settings..."
$settings = az functionapp config appsettings list `
    --name $funcAppName `
    --resource-group $resourceGroup `
    --query "[?contains(name, 'DEMO_') || contains(name, 'ServiceBus')].{name:name, hasValue:value != ''}" `
    -o json | ConvertFrom-Json

$settings | Format-Table -AutoSize

Write-Host "`nNote: SbProcessor issues usually caused by:"
Write-Host "1. Missing Az PowerShell modules (check requirements.psd1)"
Write-Host "2. Managed Identity permissions (needs Storage Blob Data Contributor)"
Write-Host "3. Service Bus connection string not configured"
Write-Host "4. Cold start timeout"

# Let's try to manually trigger a test message to see logs
Write-Host "`nSending test message to Service Bus to trigger SbProcessor..."

# Create a properly formatted test message
$testMessage = @{
    type = "vendor"
    version = "1.0"
    data = @{
        VendorAccount = "V-TEST-001"
        Name = "Test Vendor"
        Currency = "USD"
        CountryRegionId = "US"
        Address = @{
            Street = "123 Test St"
            City = "TestCity"
            PostalCode = "12345"
        }
        Email = "test@example.com"
        Phone = "+1234567890"
    }
    meta = @{
        source = "manual-test"
        receivedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        messageId = [guid]::NewGuid().ToString()
    }
} | ConvertTo-Json -Depth 10

Write-Host "Test message created"
Write-Host "`nRecommendation: Check Azure Portal for function execution logs or enable Application Insights query"
