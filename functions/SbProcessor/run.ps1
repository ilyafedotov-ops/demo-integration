param($ServiceBusTrigger, $TriggerMetadata)

Write-Host "============================================"
Write-Host "SbProcessor triggered at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================"

# Parse message - handle both string and object
Write-Host "STEP 1: Parsing message..."
if ($ServiceBusTrigger -is [string]) {
    Write-Host "  Message is string, converting from JSON..."
    try { 
        $evt = $ServiceBusTrigger | ConvertFrom-Json -Depth 20 
        Write-Host "  [OK] Message parsed successfully" -ForegroundColor Green
    } 
    catch { 
        Write-Host "  [ERROR] Message is not valid JSON: $_" -ForegroundColor Red
        throw "Message is not valid JSON." 
    }
} else {
    Write-Host "  Message is already an object"
    $evt = $ServiceBusTrigger
}

Write-Host "  Type: $($evt.type), Vendor: $($evt.data.VendorAccount)"

Write-Host "`nSTEP 2: Reading configuration..."
$acctName = $env:DEMO_STORAGE_ACCOUNT
if(-not $acctName){ 
    Write-Host "  [ERROR] DEMO_STORAGE_ACCOUNT not set" -ForegroundColor Red
    throw "App setting DEMO_STORAGE_ACCOUNT is not set." 
}
$container = $env:DEMO_STORAGE_CONTAINER
if(-not $container){ $container = "landing" }

Write-Host "  Storage Account: $acctName" -ForegroundColor Gray
Write-Host "  Container: $container" -ForegroundColor Gray
Write-Host "  [OK] Configuration loaded" -ForegroundColor Green

# Get storage connection string
Write-Host "`nSTEP 3: Getting storage connection..."

# Debug: Show all DEMO_ variables
Write-Host "  DEBUG: Checking environment variables..." -ForegroundColor Gray
Get-ChildItem Env: | Where-Object { $_.Name -like "DEMO*" -or $_.Name -like "*STORAGE*" } | ForEach-Object {
    Write-Host "    $($_.Name) = $(if($_.Value.Length -gt 50){$_.Value.Substring(0,50)+'...'}else{$_.Value})" -ForegroundColor DarkGray
}

# Try multiple sources
$connString = $env:DEMO_STORAGE_CONNECTION
if(-not $connString){ 
    Write-Host "  DEMO_STORAGE_CONNECTION not found, trying AzureWebJobsStorage..." -ForegroundColor Yellow
    $connString = $env:AzureWebJobsStorage
}

if(-not $connString){ 
    Write-Host "  [ERROR] No storage connection string found" -ForegroundColor Red
    throw "No storage connection string available." 
}

Write-Host "  [OK] Connection string loaded (length: $($connString.Length) chars)" -ForegroundColor Green

# Build blob path: vendors/yyyy/MM/dd/{VendorAccount}-{ticks}.json
Write-Host "`nSTEP 4: Building blob path..."
$dtUtc = [DateTime]::UtcNow
$folder = "vendors/{0:yyyy/MM/dd}" -f $dtUtc
$fname  = "{0}-{1}.json" -f $evt.data.VendorAccount, $dtUtc.Ticks
$blobPath = "$folder/$fname"

Write-Host "  Folder: $folder" -ForegroundColor Gray
Write-Host "  Filename: $fname" -ForegroundColor Gray
Write-Host "  Full path: $blobPath" -ForegroundColor Gray
Write-Host "  [OK] Blob path created" -ForegroundColor Green

# Serialize content
Write-Host "`nSTEP 5: Serializing content..."
$content = $evt | ConvertTo-Json -Depth 20
$bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
Write-Host "  Content size: $($bytes.Length) bytes" -ForegroundColor Gray
Write-Host "  [OK] Content serialized" -ForegroundColor Green

# Upload using PowerShell with Shared Key authentication
Write-Host "`nSTEP 6: Uploading to blob storage..."
Write-Host "  Blob path: $blobPath" -ForegroundColor Gray

try {
    # Parse connection string
    $connParts = @{}
    $connString.Split(';') | ForEach-Object {
        if ($_ -match '(.+?)=(.+)') {
            $connParts[$matches[1]] = $matches[2]
        }
    }
    
    $storageAccount = $connParts['AccountName']
    $storageKey = $connParts['AccountKey']
    
    Write-Host "  Account: $storageAccount" -ForegroundColor Gray
    Write-Host "  Blob URL: https://$storageAccount.blob.core.windows.net/$container/$blobPath" -ForegroundColor Gray
    
    # Build REST API request with Shared Key auth
    $blobUrl = "https://$storageAccount.blob.core.windows.net/$container/$blobPath"
    $method = "PUT"
    $contentType = "application/json"
    $xmsDate = [DateTime]::UtcNow.ToString("R")
    $xmsVersion = "2021-08-06"
    $contentLength = $bytes.Length
    
    # Build canonical string for Shared Key signature
    $canonicalHeaders = "x-ms-blob-type:BlockBlob`nx-ms-date:$xmsDate`nx-ms-version:$xmsVersion"
    $canonicalResource = "/$storageAccount/$container/$blobPath"
    $stringToSign = "$method`n`n`n$contentLength`n`n$contentType`n`n`n`n`n`n`n$canonicalHeaders`n$canonicalResource"
    
    # Create signature
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.Key = [Convert]::FromBase64String($storageKey)
    $signature = [Convert]::ToBase64String($hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign)))
    
    # Build headers
    $headers = @{
        "x-ms-date" = $xmsDate
        "x-ms-version" = $xmsVersion
        "x-ms-blob-type" = "BlockBlob"
        "Content-Type" = $contentType
        "Content-Length" = $contentLength.ToString()
        "Authorization" = "SharedKey ${storageAccount}:${signature}"
    }
    
    Write-Host "  Sending PUT request..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri $blobUrl -Method Put -Headers $headers -Body $bytes -ErrorAction Stop
    
    Write-Host "  [SUCCESS] Blob uploaded successfully!" -ForegroundColor Green
    Write-Host "  Blob: $blobPath" -ForegroundColor Cyan
    
} catch {
    Write-Host "  [ERROR] Upload failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "  Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
    throw
}

Write-Host "`n============================================"
Write-Host "SbProcessor completed successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================"
