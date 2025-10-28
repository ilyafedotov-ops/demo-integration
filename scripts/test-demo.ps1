# Test Script for D365 Demo (PowerShell)
# This script performs end-to-end testing of the deployed demo

param(
    [string]$ResourceGroup = "rg-d365-demo",
    [string]$TenantId = "",
    [string]$ClientId = "",
    [string]$ClientSecret = ""
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"

Write-Host "Starting D365 Demo Smoke Tests..." -ForegroundColor $Yellow

try {
    # Get resource names
    Write-Host "Getting resource names..." -ForegroundColor $Yellow
    $apimName = az apim list --resource-group $ResourceGroup --query "[0].name" -o tsv
    $funcName = az functionapp list --resource-group $ResourceGroup --query "[0].name" -o tsv
    $logicAppName = az logic workflow list --resource-group $ResourceGroup --query "[0].name" -o tsv

    Write-Host "APIM: $apimName" -ForegroundColor Cyan
    Write-Host "Function: $funcName" -ForegroundColor Cyan
    Write-Host "Logic App: $logicAppName" -ForegroundColor Cyan

    # Test payload
    $vendorPayload = @{
        VendorAccount = "V-TEST-001"
        Name = "Test Vendor GmbH"
        Currency = "EUR"
        CountryRegionId = "DE"
        Address = @{
            Street = "Teststrasse 1"
            City = "Berlin"
            PostalCode = "10115"
        }
        Email = "test@vendor.de"
        Phone = "+49 30 123456"
    } | ConvertTo-Json -Depth 3

    # Test 1: Logic App Direct Call
    Write-Host "`nTest 1: Logic App Direct Call" -ForegroundColor $Yellow
    $logicAppUrl = az logic workflow show --resource-group $ResourceGroup --name $logicAppName --query "accessEndpoint" -o tsv

    $response = Invoke-RestMethod -Uri $logicAppUrl -Method Post -Body $vendorPayload -ContentType "application/json" -ErrorAction Stop
    Write-Host "✓ Logic App test passed" -ForegroundColor $Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan

} catch {
    Write-Host "✗ Logic App test failed: $($_.Exception.Message)" -ForegroundColor $Red
}

try {
    # Test 2: Function Direct Call
    Write-Host "`nTest 2: Function Direct Call" -ForegroundColor $Yellow
    $funcKey = az functionapp keys list --resource-group $ResourceGroup --name $funcName --query "functionKeys.default" -o tsv
    $funcUrl = "https://$funcName.azurewebsites.net/api/HttpIngest?code=$funcKey"

    $response = Invoke-RestMethod -Uri $funcUrl -Method Post -Body $vendorPayload -ContentType "application/json" -ErrorAction Stop
    Write-Host "✓ Function test passed" -ForegroundColor $Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan

} catch {
    Write-Host "✗ Function test failed: $($_.Exception.Message)" -ForegroundColor $Red
}

# Test 3: APIM Call (if JWT credentials provided)
if ($TenantId -and $ClientId -and $ClientSecret) {
    try {
        Write-Host "`nTest 3: APIM Call with JWT" -ForegroundColor $Yellow
        
        # Get JWT token
        $tokenBody = @{
            client_id = $ClientId
            client_secret = $ClientSecret
            scope = "api://$ClientId/.default"
            grant_type = "client_credentials"
        }
        
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method Post -Body $tokenBody -ErrorAction Stop
        $jwtToken = $tokenResponse.access_token
        
        if ($jwtToken) {
            $apimUrl = az apim show --resource-group $ResourceGroup --name $apimName --query "gatewayRegionalUrl" -o tsv
            
            $headers = @{
                "Authorization" = "Bearer $jwtToken"
                "Content-Type" = "application/json"
            }
            
            $response = Invoke-RestMethod -Uri "$apimUrl/vendor-ingest/vendors" -Method Post -Body $vendorPayload -Headers $headers -ErrorAction Stop
            Write-Host "✓ APIM test passed" -ForegroundColor $Green
            Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Failed to obtain JWT token" -ForegroundColor $Red
        }
    } catch {
        Write-Host "✗ APIM test failed: $($_.Exception.Message)" -ForegroundColor $Red
    }
} else {
    Write-Host "`nTest 3: APIM Call - Skipped (no JWT credentials)" -ForegroundColor $Yellow
}

# Test 4: Check Service Bus Queue
Write-Host "`nTest 4: Service Bus Queue Status" -ForegroundColor $Yellow
$sbNamespace = az servicebus namespace list --resource-group $ResourceGroup --query "[0].name" -o tsv
$queueName = "inbound"

$activeMessages = az servicebus queue show --resource-group $ResourceGroup --namespace-name $sbNamespace --name $queueName --query "messageCountDetails.activeMessageCount" -o tsv

Write-Host "Service Bus Queue '$queueName' active messages: $activeMessages" -ForegroundColor Cyan

if ([int]$activeMessages -gt 0) {
    Write-Host "✓ Service Bus has messages (processing working)" -ForegroundColor $Green
} else {
    Write-Host "! Service Bus queue is empty (may need time to process)" -ForegroundColor $Yellow
}

# Test 5: Check ADLS Gen2 Storage
Write-Host "`nTest 5: ADLS Gen2 Storage" -ForegroundColor $Yellow
$storageAccount = az storage account list --resource-group $ResourceGroup --query "[?contains(name, 'std')].name" -o tsv | Select-Object -First 1

if ($storageAccount) {
    $containerExists = az storage container exists --account-name $storageAccount --name "landing" --query "exists" -o tsv
    
    if ($containerExists -eq "true") {
        Write-Host "✓ ADLS Gen2 container 'landing' exists" -ForegroundColor $Green
        
        # List recent files
        $today = Get-Date -Format "yyyy/MM/dd"
        Write-Host "Checking for files in vendors/$today/" -ForegroundColor Cyan
        
        $fileCount = az storage blob list --account-name $storageAccount --container-name "landing" --prefix "vendors/$today/" --query "length(@)" -o tsv
        
        if ([int]$fileCount -gt 0) {
            Write-Host "✓ Found $fileCount files in ADLS Gen2" -ForegroundColor $Green
        } else {
            Write-Host "! No files found in ADLS Gen2 (may need time to process)" -ForegroundColor $Yellow
        }
    } else {
        Write-Host "✗ ADLS Gen2 container 'landing' not found" -ForegroundColor $Red
    }
} else {
    Write-Host "✗ ADLS Gen2 storage account not found" -ForegroundColor $Red
}

Write-Host "`nSmoke tests completed!" -ForegroundColor $Yellow
Write-Host "Check Application Insights for detailed logs and metrics." -ForegroundColor Cyan
