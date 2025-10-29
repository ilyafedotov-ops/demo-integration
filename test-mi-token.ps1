# Test if managed identity can get storage token
try {
    $uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/"
    $response = Invoke-RestMethod -Uri $uri -Headers @{Metadata="true"} -Method GET -TimeoutSec 5
    Write-Host "[OK] Token acquired successfully" -ForegroundColor Green
    Write-Host "Token type: $($response.token_type)" -ForegroundColor Gray
    Write-Host "Expires: $($response.expires_on)" -ForegroundColor Gray
} catch {
    Write-Host "[FAIL] Could not get token: $($_.Exception.Message)" -ForegroundColor Red
}
