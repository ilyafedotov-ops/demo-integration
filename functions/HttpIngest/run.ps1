param($Request, $TriggerMetadata)

# -- Basic validation of required fields
$bodyRaw = $Request.Body

# If Body is already an object, use it directly; otherwise parse JSON
if ($bodyRaw -is [string]) {
    try { $payload = $bodyRaw | ConvertFrom-Json -Depth 20 } catch { $payload = $null }
} else {
    $payload = $bodyRaw
}

# Check if payload has data field (from Logic App) or direct fields
if ($payload.data) {
    $dataToValidate = $payload.data
} else {
    $dataToValidate = $payload
}

$required = @('VendorAccount','Name','Currency','CountryRegionId')
$missing  = @()
foreach($r in $required){ if(-not $dataToValidate.$r){ $missing += $r } }

if(-not $payload -or $missing.Count -gt 0){
  $msg = @{ error = "Invalid payload"; missing = $missing } | ConvertTo-Json
  Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = 400; Body = $msg })
  return
}

# -- Enrich (if payload came directly without Logic App)
if(-not $payload.meta){
  $payload = [pscustomobject]@{
    type    = "vendor"
    version = "1.0"
    data    = $dataToValidate
    meta    = @{
      source        = "function-http"
      receivedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
      messageId     = [guid]::NewGuid().ToString()
    }
  }
}

# -- Enqueue to Service Bus
Write-Host "============================================"
Write-Host "SENDING TO SERVICE BUS"
Write-Host "============================================"
Write-Host "Payload object type: $($payload.GetType().FullName)"
Write-Host "Payload: $($payload | ConvertTo-Json -Depth 3 -Compress)"

$sbMessage = $payload | ConvertTo-Json -Depth 20
Write-Host "Service Bus message type: $($sbMessage.GetType().FullName)"
Write-Host "Service Bus message length: $($sbMessage.Length) chars"
Write-Host "Service Bus message preview: $($sbMessage.Substring(0, [Math]::Min(200, $sbMessage.Length)))"
Write-Host "============================================"

Push-OutputBinding -Name sbOut -Value $sbMessage

# -- 202 Accepted
$resp = [HttpResponseContext]@{
  StatusCode = 202
  Body       = @{
    enqueued = $true
    id       = $payload.meta.messageId
  }
}
Push-OutputBinding -Name Response -Value $resp

Write-Host "Response sent: 202 Accepted, ID: $($payload.meta.messageId)"
