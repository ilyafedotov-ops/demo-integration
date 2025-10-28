# 🧪 D365 Integration Demo - Testing Guide

## Deployed Resources

**Resource Group**: rg-d365-demo-v2  
**Function App**: demo-func-nfittwqa7bkom  
**Logic App**: demo-la-nfittwqa7bkom  
**APIM**: demo-apim-nfittwqa7bkom  
**Service Bus**: demo-sb-nfittwqa7bkom  
**Storage (ADLS Gen2)**: demodatanfittwqa

## Test 1: Function App Direct Call

Test the HttpIngest function directly:

```powershell
# Test payload
$body = @{
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
} | ConvertTo-Json

# Call the function
$response = Invoke-RestMethod `
    -Uri "https://demo-func-nfittwqa7bkom.azurewebsites.net/api/HttpIngest?code=YOUR_FUNCTION_KEY_HERE" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

Write-Host "Response:" -ForegroundColor Green
$response | ConvertTo-Json
```

**Expected Result**: HTTP 202 with `{ "enqueued": true, "id": "guid" }`

## Test 2: Logic App Workflow

Get the Logic App callback URL and test it:

```powershell
# Get the Logic App endpoint from Azure Portal:
# 1. Navigate to Logic App: demo-la-nfittwqa7bkom
# 2. Go to "Logic app designer"
# 3. Click on the "manual" trigger
# 4. Copy the "HTTP POST URL"

# Then test with the same payload as above
$logicAppUrl = "PASTE_LOGIC_APP_URL_HERE"

$response = Invoke-RestMethod `
    -Uri $logicAppUrl `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

Write-Host "Response:" -ForegroundColor Green
$response | ConvertTo-Json
```

## Test 3: Verify Service Bus Queue

Check if messages are being queued:

```powershell
# Check queue message count
az servicebus queue show `
    --resource-group rg-d365-demo-v2 `
    --namespace-name demo-sb-nfittwqa7bkom `
    --name inbound `
    --query "countDetails.activeMessageCount" `
    -o tsv
```

**Expected Result**: Number should increase after sending messages

## Test 4: Verify ADLS Gen2 Data Landing

Check if data is being written to storage:

```powershell
# List blobs in the landing container
az storage blob list `
    --account-name demodatanfittwqa `
    --container-name landing `
    --prefix "vendors/" `
    --query "[].name" `
    -o table

# Or use Azure Portal:
# 1. Navigate to Storage Account: demodatanfittwqa
# 2. Go to "Containers"
# 3. Click on "landing"
# 4. Navigate to vendors/YYYY/MM/DD/
# 5. You should see JSON files like: V-TEST-001-{ticks}.json
```

**Expected Result**: JSON files in format `vendors/YYYY/MM/DD/VendorAccount-ticks.json`

## Test 5: Verify Function Logs

Check Application Insights for function execution logs:

```powershell
# Get recent function invocations
az monitor app-insights metrics show `
    --app demo-appi-nfittwqa7bkom `
    --resource-group rg-d365-demo-v2 `
    --metric requests/count `
    --aggregation count

# Or use Azure Portal:
# 1. Navigate to Function App: demo-func-nfittwqa7bkom
# 2. Go to "Functions" → "HttpIngest" or "SbProcessor"
# 3. Click "Monitor"
# 4. View execution logs and traces
```

## Test 6: End-to-End Data Flow

Complete data flow test:

```powershell
# 1. Send request to Function
Write-Host "Step 1: Sending request to Function..." -ForegroundColor Cyan
$response = Invoke-RestMethod `
    -Uri "https://demo-func-nfittwqa7bkom.azurewebsites.net/api/HttpIngest?code=YOUR_FUNCTION_KEY_HERE" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

Write-Host "✓ Message enqueued. ID: $($response.id)" -ForegroundColor Green

# 2. Wait for processing
Write-Host "`nStep 2: Waiting for processing..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# 3. Check Service Bus (should be processed = 0 active messages)
Write-Host "`nStep 3: Checking Service Bus..." -ForegroundColor Cyan
$messageCount = az servicebus queue show `
    --resource-group rg-d365-demo-v2 `
    --namespace-name demo-sb-nfittwqa7bkom `
    --name inbound `
    --query "countDetails.activeMessageCount" `
    -o tsv

Write-Host "Active messages in queue: $messageCount" -ForegroundColor $(if($messageCount -eq 0){"Green"}else{"Yellow"})

# 4. Check ADLS Gen2 for the file
Write-Host "`nStep 4: Checking ADLS Gen2..." -ForegroundColor Cyan
$today = Get-Date -Format "yyyy/MM/dd"
$blobs = az storage blob list `
    --account-name demodatanfittwqa `
    --container-name landing `
    --prefix "vendors/$today" `
    --query "[].name" `
    -o json | ConvertFrom-Json

if ($blobs.Count -gt 0) {
    Write-Host "✓ Found $($blobs.Count) file(s) in ADLS Gen2" -ForegroundColor Green
    $blobs | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
} else {
    Write-Host "⚠ No files found yet. May need more time to process." -ForegroundColor Yellow
}

Write-Host "`n✅ End-to-end test complete!" -ForegroundColor Green
```

## Test 7: Load Test (Optional)

Send multiple requests to test throughput:

```powershell
Write-Host "Starting load test..." -ForegroundColor Cyan

$results = 1..10 | ForEach-Object -Parallel {
    $body = @{
        VendorAccount = "V-LOAD-$_"
        Name = "Load Test Vendor $_"
        Currency = "EUR"
        CountryRegionId = "DE"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod `
            -Uri $using:functionUrl `
            -Method Post `
            -ContentType "application/json" `
            -Body $body
        
        [PSCustomObject]@{
            Request = $_
            Status = "Success"
            ID = $response.id
        }
    } catch {
        [PSCustomObject]@{
            Request = $_
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
} -ThrottleLimit 5

$results | Format-Table
Write-Host "Successful: $($results | Where-Object Status -eq 'Success' | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
```

## Troubleshooting

### Issue: Function returns 500 error
**Solution**: Check Application Insights logs for detailed error messages

### Issue: No data in ADLS Gen2
**Solution**: 
1. Verify RBAC permissions on storage account
2. Check Function logs for SbProcessor errors
3. Ensure managed identity is properly configured

### Issue: Service Bus messages piling up
**Solution**:
1. Check if SbProcessor function is running
2. Verify Service Bus connection string in Function App settings
3. Check for errors in Application Insights

### Issue: Logic App not triggering
**Solution**:
1. Verify the callback URL is correct
2. Check Logic App run history in Azure Portal
3. Ensure payload matches the expected schema

## Performance Metrics

**Expected Performance**:
- Function response time: < 500ms
- Service Bus processing: < 2 seconds per message
- ADLS Gen2 write: < 1 second per file
- End-to-end latency: < 5 seconds

## Next Steps

1. **Add Azure AD JWT validation** to APIM
2. **Configure rate limiting** on APIM
3. **Set up monitoring alerts** for failures
4. **Configure auto-scaling** if needed
5. **Add D365 F&O real endpoint** for production

## Resources

- **Azure Portal**: https://portal.azure.com
- **Application Insights**: Search for "demo-appi-nfittwqa7bkom"
- **Function App**: Search for "demo-func-nfittwqa7bkom"
- **Logic App**: Search for "demo-la-nfittwqa7bkom"
