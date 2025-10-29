# Check and validate app registration using Microsoft Graph PowerShell
$ErrorActionPreference = "Stop"

Write-Host "`n=== Checking Entra ID App Registration ===" -ForegroundColor Cyan

# Check if Microsoft.Graph module is installed
Write-Host "`n[Step 1] Checking PowerShell modules..." -ForegroundColor Yellow
$graphModule = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
if (-not $graphModule) {
    Write-Host "[WARN] Microsoft.Graph module not installed" -ForegroundColor Yellow
    Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    Write-Host "[OK] Module installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Microsoft.Graph module found" -ForegroundColor Green
}

# Import modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

# Connect to Microsoft Graph
Write-Host "`n[Step 2] Connecting to Microsoft Graph..." -ForegroundColor Yellow
Write-Host "  Tenant: f8054917-dc24-4ea5-9363-fa27b4814bbe" -ForegroundColor Gray

try {
    Connect-MgGraph -TenantId "f8054917-dc24-4ea5-9363-fa27b4814bbe" -Scopes "Application.Read.All", "Directory.Read.All" -NoWelcome
    Write-Host "[OK] Connected to Microsoft Graph" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Could not connect: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check client app
Write-Host "`n[Step 3] Checking client app (4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d)..." -ForegroundColor Yellow
try {
    $clientApp = Get-MgApplication -Filter "appId eq ''4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d''" -ErrorAction SilentlyContinue
    
    if ($clientApp) {
        Write-Host "[OK] Client app found: $($clientApp.DisplayName)" -ForegroundColor Green
        Write-Host "  App ID: $($clientApp.AppId)" -ForegroundColor Gray
        Write-Host "  Object ID: $($clientApp.Id)" -ForegroundColor Gray
        
        # Check service principal
        $clientSp = Get-MgServicePrincipal -Filter "appId eq ''4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d''" -ErrorAction SilentlyContinue
        if ($clientSp) {
            Write-Host "[OK] Service principal exists" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Service principal does NOT exist - creating..." -ForegroundColor Yellow
            try {
                New-MgServicePrincipal -AppId "4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d"
                Write-Host "[OK] Service principal created" -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Could not create service principal: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "[FAIL] Client app NOT found in this tenant" -ForegroundColor Red
        Write-Host "  The app 4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d does not exist in tenant f8054917-dc24-4ea5-9363-fa27b4814bbe" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error checking client app: $($_.Exception.Message)" -ForegroundColor Red
}

# Check API app
Write-Host "`n[Step 4] Checking API app (757412f8-fe70-479c-afef-d4fe635a40ea)..." -ForegroundColor Yellow
try {
    $apiApp = Get-MgApplication -Filter "appId eq ''757412f8-fe70-479c-afef-d4fe635a40ea''" -ErrorAction SilentlyContinue
    
    if ($apiApp) {
        Write-Host "[OK] API app found: $($apiApp.DisplayName)" -ForegroundColor Green
        Write-Host "  App ID: $($apiApp.AppId)" -ForegroundColor Gray
        Write-Host "  Object ID: $($apiApp.Id)" -ForegroundColor Gray
        
        if ($apiApp.IdentifierUris.Count -gt 0) {
            Write-Host "  Identifier URIs:" -ForegroundColor Gray
            foreach ($uri in $apiApp.IdentifierUris) {
                Write-Host "    - $uri" -ForegroundColor Gray
            }
        } else {
            Write-Host "[WARN] No identifier URIs configured" -ForegroundColor Yellow
        }
        
        # Check app roles
        if ($apiApp.AppRoles.Count -gt 0) {
            Write-Host "  App Roles:" -ForegroundColor Gray
            foreach ($role in $apiApp.AppRoles) {
                Write-Host "    - $($role.DisplayName) (Value: $($role.Value))" -ForegroundColor Gray
            }
        } else {
            Write-Host "[WARN] No app roles defined" -ForegroundColor Yellow
        }
        
        # Check service principal
        $apiSp = Get-MgServicePrincipal -Filter "appId eq ''757412f8-fe70-479c-afef-d4fe635a40ea''" -ErrorAction SilentlyContinue
        if ($apiSp) {
            Write-Host "[OK] Service principal exists" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Service principal does NOT exist - creating..." -ForegroundColor Yellow
            try {
                New-MgServicePrincipal -AppId "757412f8-fe70-479c-afef-d4fe635a40ea"
                Write-Host "[OK] Service principal created" -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Could not create service principal: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "[FAIL] API app NOT found in this tenant" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error checking API app: $($_.Exception.Message)" -ForegroundColor Red
}

# List all app registrations to help identify correct ones
Write-Host "`n[Step 5] Listing all app registrations in tenant..." -ForegroundColor Yellow
try {
    $allApps = Get-MgApplication -Top 50 | Select-Object DisplayName, AppId, Id
    Write-Host "`nApp Registrations found:" -ForegroundColor Cyan
    foreach ($app in $allApps) {
        Write-Host "  - $($app.DisplayName)" -ForegroundColor Gray
        Write-Host "    App ID: $($app.AppId)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "[WARN] Could not list apps: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Review the output above to identify the correct app registration details." -ForegroundColor Yellow
Write-Host "If the client app was not found, you may need to use different credentials." -ForegroundColor Yellow

Disconnect-MgGraph
