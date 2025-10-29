# Decode JWT token to see claims
$clientId = "5e973595-34cc-42b3-b290-857aeeab580a"
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientSecret = "YOUR_CLIENT_SECRET_HERE"
$scope = "api://757412f8-fe70-479c-afef-d4fe635a40ea/.default"

Write-Host "Acquiring token..." -ForegroundColor Yellow
$tokenBody = @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

Write-Host "`n=== JWT Token Claims ===" -ForegroundColor Cyan

# Decode header
$tokenParts = $accessToken.Split('.')
$headerPadded = $tokenParts[0]
while ($headerPadded.Length % 4 -ne 0) { $headerPadded += "=" }
$headerJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($headerPadded))
$header = $headerJson | ConvertFrom-Json

Write-Host "`nHeader:" -ForegroundColor Yellow
$header | ConvertTo-Json -Depth 5

# Decode payload
$payloadPadded = $tokenParts[1]
while ($payloadPadded.Length % 4 -ne 0) { $payloadPadded += "=" }
$payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payloadPadded))
$payload = $payloadJson | ConvertFrom-Json

Write-Host "`nPayload:" -ForegroundColor Yellow
$payload | ConvertTo-Json -Depth 5

Write-Host "`nKey Claims:" -ForegroundColor Cyan
Write-Host "  aud (audience): $($payload.aud)"
Write-Host "  iss (issuer): $($payload.iss)"
Write-Host "  appid: $($payload.appid)"
Write-Host "  roles: $($payload.roles -join ', ')"
Write-Host "  exp (expires): $([DateTimeOffset]::FromUnixTimeSeconds($payload.exp).LocalDateTime)"
