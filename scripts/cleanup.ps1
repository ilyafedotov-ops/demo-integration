# Cleanup Script for D365 Demo (PowerShell)
# This script removes all resources created by the demo

param(
    [string]$ResourceGroup = "rg-d365-demo",
    [switch]$Force
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"

Write-Host "⚠️  WARNING: This will delete ALL resources in the resource group!" -ForegroundColor $Red
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor $Yellow
Write-Host ""
Write-Host "This includes:" -ForegroundColor $Yellow
Write-Host "- Azure API Management" -ForegroundColor White
Write-Host "- Logic Apps" -ForegroundColor White
Write-Host "- Azure Functions" -ForegroundColor White
Write-Host "- Service Bus" -ForegroundColor White
Write-Host "- Storage Accounts (ADLS Gen2)" -ForegroundColor White
Write-Host "- Application Insights" -ForegroundColor White
Write-Host "- Key Vault" -ForegroundColor White
Write-Host "- All associated data" -ForegroundColor White
Write-Host ""

if (-not $Force) {
    $confirmation = Read-Host "Type 'DELETE' to confirm"
    
    if ($confirmation -ne "DELETE") {
        Write-Host "Deletion cancelled." -ForegroundColor $Green
        exit 0
    }
}

Write-Host "Deleting resource group: $ResourceGroup" -ForegroundColor $Yellow

# Delete the entire resource group
az group delete --name $ResourceGroup --yes --no-wait

Write-Host "✓ Deletion initiated successfully!" -ForegroundColor $Green
Write-Host "Note: Deletion may take several minutes to complete." -ForegroundColor $Yellow
Write-Host "You can check the status with: az group show --name $ResourceGroup" -ForegroundColor Cyan
