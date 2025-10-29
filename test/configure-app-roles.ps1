# Configure API app with app roles and grant permissions to client
$ErrorActionPreference = "Stop"

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

Write-Host "`n=== Configuring API App Roles and Permissions ===" -ForegroundColor Cyan

Connect-MgGraph -TenantId "f8054917-dc24-4ea5-9363-fa27b4814bbe" -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -NoWelcome

$apiAppId = "757412f8-fe70-479c-afef-d4fe635a40ea"
$clientAppId = "5e973595-34cc-42b3-b290-857aeeab580a"

# Get API app
Write-Host "`n[1/3] Getting API app..." -ForegroundColor Yellow
$apiApp = Get-MgApplication -Filter "appId eq '$apiAppId'"
Write-Host "[OK] API App: $($apiApp.DisplayName)" -ForegroundColor Green

# Check if app roles exist
if ($apiApp.AppRoles.Count -eq 0) {
    Write-Host "`n[2/3] Creating app role..." -ForegroundColor Yellow
    
    $appRole = @{
        AllowedMemberTypes = @("Application")
        Description = "Access to D365 Integration API"
        DisplayName = "API.Access"
        Id = [Guid]::NewGuid().ToString()
        IsEnabled = $true
        Value = "API.Access"
    }
    
    $appRoles = @($appRole)
    
    try {
        Update-MgApplication -ApplicationId $apiApp.Id -AppRoles $appRoles
        Write-Host "[OK] App role created: API.Access" -ForegroundColor Green
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "[FAIL] Could not create app role: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Refresh app data
    $apiApp = Get-MgApplication -Filter "appId eq '$apiAppId'"
} else {
    Write-Host "[OK] App roles already exist" -ForegroundColor Green
    foreach ($role in $apiApp.AppRoles) {
        Write-Host "  - $($role.DisplayName) (Value: $($role.Value))" -ForegroundColor Gray
    }
}

# Get service principals
Write-Host "`n[3/3] Granting app role to client..." -ForegroundColor Yellow
$apiSp = Get-MgServicePrincipal -Filter "appId eq '$apiAppId'"
$clientSp = Get-MgServicePrincipal -Filter "appId eq '$clientAppId'"

if ($apiApp.AppRoles.Count -gt 0 -and $apiSp -and $clientSp) {
    $appRoleId = $apiApp.AppRoles[0].Id
    
    # Check if assignment already exists
    $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $clientSp.Id -ErrorAction SilentlyContinue | Where-Object { $_.AppRoleId -eq $appRoleId }
    
    if (-not $existingAssignment) {
        try {
            $assignment = @{
                PrincipalId = $clientSp.Id
                ResourceId = $apiSp.Id
                AppRoleId = $appRoleId
            }
            
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $clientSp.Id -BodyParameter $assignment
            Write-Host "[OK] App role assigned to client app" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Could not assign role: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[OK] App role already assigned" -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] Could not grant permissions - missing app roles or service principals" -ForegroundColor Yellow
}

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
Write-Host "Wait 1-2 minutes for changes to propagate, then run: .\test-with-new-creds.ps1" -ForegroundColor Cyan

Disconnect-MgGraph
