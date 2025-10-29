# Diagnostic script to check app registration and create service principal if needed
$ErrorActionPreference = "Continue"

$clientId = "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"
$apiAppId = "757412f8-fe70-479c-afef-d4fe635a40ea"
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientSecret = "YOUR_CLIENT_SECRET_HERE"

Write-Host "`n=== Azure AD App Registration Diagnostics ===" -ForegroundColor Cyan

# Step 1: Try to get Graph token to query app info
Write-Host "`n[1/3] Attempting to query app information via Graph API..." -ForegroundColor Yellow

try {
    $graphTokenBody = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }
    
    $graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $graphTokenBody -ContentType "application/x-www-form-urlencoded"
    $graphToken = $graphTokenResponse.access_token
    
    Write-Host "[OK] Successfully acquired Graph API token with client app" -ForegroundColor Green
    Write-Host "  This means the client app ($clientId) IS registered in the tenant" -ForegroundColor Gray
    
    # Check if service principal exists
    Write-Host "`n[2/3] Checking service principal for client app..." -ForegroundColor Yellow
    try {
        $spInfo = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$clientId'" -Headers @{ Authorization = "Bearer $graphToken" } -Method Get
        
        if ($spInfo.value.Count -gt 0) {
            Write-Host "[OK] Service principal exists for client app" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Service principal does NOT exist for client app" -ForegroundColor Yellow
            Write-Host "  This might be causing authentication issues" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[WARN] Could not check service principal: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Check API app
    Write-Host "`n[3/3] Checking API app registration ($apiAppId)..." -ForegroundColor Yellow
    try {
        $apiInfo = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=appId eq '$apiAppId'" -Headers @{ Authorization = "Bearer $graphToken" } -Method Get
        
        if ($apiInfo.value.Count -gt 0) {
            $api = $apiInfo.value[0]
            Write-Host "[OK] API app registration found: $($api.displayName)" -ForegroundColor Green
            Write-Host "  App ID: $($api.appId)" -ForegroundColor Gray
            
            if ($api.identifierUris.Count -gt 0) {
                Write-Host "  Identifier URIs:" -ForegroundColor Gray
                foreach ($uri in $api.identifierUris) {
                    Write-Host "    - $uri" -ForegroundColor Gray
                }
            }
            
            # Check service principal for API app
            $apiSpInfo = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$apiAppId'" -Headers @{ Authorization = "Bearer $graphToken" } -Method Get
            
            if ($apiSpInfo.value.Count -gt 0) {
                Write-Host "[OK] Service principal exists for API app" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Service principal does NOT exist for API app" -ForegroundColor Yellow
                Write-Host "  Run: az ad sp create --id $apiAppId" -ForegroundColor Cyan
            }
        } else {
            Write-Host "[WARN] API app registration not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] Could not check API app: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[FAIL] Could not acquire Graph token" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorDetail = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details: $($errorDetail.error_description)" -ForegroundColor Red
    }
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. Ensure service principal exists for API app: az ad sp create --id $apiAppId" -ForegroundColor Yellow
Write-Host "2. Grant API permissions from client app to API app in Azure Portal" -ForegroundColor Yellow
Write-Host "3. Grant admin consent for the permissions" -ForegroundColor Yellow
