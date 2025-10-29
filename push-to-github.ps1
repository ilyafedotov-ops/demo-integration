# Push to GitHub with authentication
# This script pushes the local demo-Integration branch to GitHub

Write-Host "Pushing to GitHub repository..." -ForegroundColor Cyan

# Load token from .env file
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^GITHUB_TOKEN=(.+)$') {
            $token = $matches[1]
        }
    }
}

if (-not $token) {
    Write-Host "Error: GITHUB_TOKEN not found in .env file" -ForegroundColor Red
    exit 1
}

# Configure git remote with authentication
$repoUrl = "https://ilyafedotov-ops:$token@github.com/ilyafedotov-ops/demo-integration.git"
git remote set-url origin $repoUrl

Write-Host "Current branch:" -ForegroundColor Yellow
git branch --show-current

Write-Host "`nCommits to push:" -ForegroundColor Yellow
git log origin/demo-Integration..HEAD --oneline 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  (No upstream branch yet, will push all local commits)" -ForegroundColor Gray
    git log --oneline -5
}

Write-Host "`nPushing to origin/demo-Integration..." -ForegroundColor Cyan
git push -u origin demo-Integration

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: https://github.com/ilyafedotov-ops/demo-integration" -ForegroundColor Cyan
} else {
    Write-Host "`n✗ Push failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Error details above. Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Token doesn't have 'repo' scope - check at https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host "  2. Branch protection rules blocking the push" -ForegroundColor Gray
    Write-Host "  3. Network connectivity issues" -ForegroundColor Gray
}
