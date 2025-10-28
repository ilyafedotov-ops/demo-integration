param($ServiceBusTrigger, $TriggerMetadata)

Write-Host "SbProcessor triggered"

# Parse message - handle both string and object
if ($ServiceBusTrigger -is [string]) {
    try { $evt = $ServiceBusTrigger | ConvertFrom-Json -Depth 20 } 
    catch { 
        Write-Host "ERROR: Message is not valid JSON: $_"
        throw "Message is not valid JSON." 
    }
} else {
    $evt = $ServiceBusTrigger
}

Write-Host "Message parsed. Type: $($evt.type), Vendor: $($evt.data.VendorAccount)"

$acctName = $env:DEMO_STORAGE_ACCOUNT
if(-not $acctName){ 
    Write-Host "ERROR: DEMO_STORAGE_ACCOUNT not set"
    throw "App setting DEMO_STORAGE_ACCOUNT is not set." 
}
$container = $env:DEMO_STORAGE_CONTAINER
if(-not $container){ $container = "landing" }

Write-Host "Storage: $acctName, Container: $container"

# Get managed identity token for Storage
$tokenResponse = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" `
    -Headers @{Metadata="true"} -Method GET

$token = $tokenResponse.access_token
Write-Host "Got managed identity token"

# Build blob path: vendors/yyyy/MM/dd/{VendorAccount}-{ticks}.json
$dtUtc = [DateTime]::UtcNow
$folder = "vendors/{0:yyyy/MM/dd}" -f $dtUtc
$fname  = "{0}-{1}.json" -f $evt.data.VendorAccount, $dtUtc.Ticks
$blobPath = "$folder/$fname"

Write-Host "Blob path: $blobPath"

# Serialize content
$content = $evt | ConvertTo-Json -Depth 20
$bytes = [System.Text.Encoding]::UTF8.GetBytes($content)

# Upload using REST API
$uploadUri = "https://${acctName}.blob.core.windows.net/${container}/${blobPath}"
$headers = @{
    "Authorization" = "Bearer $token"
    "x-ms-version" = "2021-08-06"
    "x-ms-blob-type" = "BlockBlob"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $uploadUri -Method Put -Headers $headers -Body $bytes
    Write-Host "Successfully uploaded blob: $blobPath"
} catch {
    Write-Host "ERROR uploading blob: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
    throw
}

Write-Host "SbProcessor completed successfully"
