# Simple Dead Letter Reprocessing Guide
Write-Host "`n=== Dead Letter Message Reprocessing ===" -ForegroundColor Cyan

# Check current status
Write-Host "`nChecking Service Bus status..." -ForegroundColor Yellow
$queueData = az servicebus queue show `
    -g rg-d365-demo-v2 `
    --namespace-name demo-sb-nfittwqa7bkom `
    -n inbound `
    -o json | ConvertFrom-Json

$deadLetterCount = $queueData.countDetails.deadLetterMessageCount
$activeCount = $queueData.countDetails.activeMessageCount

Write-Host "`nCurrent Status:" -ForegroundColor Cyan
Write-Host "  Active messages: $activeCount" -ForegroundColor Green
Write-Host "  Dead letter messages: $deadLetterCount" -ForegroundColor Yellow

if ($deadLetterCount -eq 0) {
    Write-Host "`n[INFO] No dead letter messages to reprocess!" -ForegroundColor Green
    exit 0
}

Write-Host "`n=== Reprocessing Options ===" -ForegroundColor Cyan

Write-Host "`nOption 1: Azure Portal (Easiest)" -ForegroundColor Yellow
Write-Host "  1. Open: https://portal.azure.com" -ForegroundColor White
Write-Host "  2. Go to: Service Bus Namespaces" -ForegroundColor White
Write-Host "  3. Select: demo-sb-nfittwqa7bkom" -ForegroundColor White
Write-Host "  4. Click: Queues" -ForegroundColor White
Write-Host "  5. Select: inbound" -ForegroundColor White
Write-Host "  6. Click: Service Bus Explorer (left menu)" -ForegroundColor White
Write-Host "  7. Select: Dead-letter tab" -ForegroundColor White
Write-Host "  8. Click: Peek from start" -ForegroundColor White
Write-Host "  9. Select all messages (or specific ones)" -ForegroundColor White
Write-Host "  10. Click: Resubmit selected messages" -ForegroundColor White
Write-Host "`n  This will move them back to the active queue for reprocessing." -ForegroundColor Green

Write-Host "`nOption 2: Clear and ignore (if old test messages)" -ForegroundColor Yellow
Write-Host "  If these are just old test messages from debugging," -ForegroundColor White
Write-Host "  you can leave them in dead letter or purge the queue." -ForegroundColor White

Write-Host "`nOption 3: Open Portal now" -ForegroundColor Yellow
$response = Read-Host "Open Azure Portal Service Bus Explorer now? (Y/N)"
if ($response -eq 'Y' -or $response -eq 'y') {
    $url = "https://portal.azure.com/#@/resource/subscriptions/9019cfb1-cb52-4c48-a0a8-727ad3933f34/resourceGroups/rg-d365-demo-v2/providers/Microsoft.ServiceBus/namespaces/demo-sb-nfittwqa7bkom/queues/inbound/explorer"
    Start-Process $url
    Write-Host "[OK] Opening browser..." -ForegroundColor Green
}

Write-Host "`n=== Recommendation ===" -ForegroundColor Cyan
Write-Host "Since the SbProcessor is now working, you can:" -ForegroundColor White
Write-Host "  1. Resubmit the $deadLetterCount dead letter messages from Portal" -ForegroundColor White
Write-Host "  2. They will be automatically processed and land in storage" -ForegroundColor White
Write-Host "  3. Or just leave them (they are old test messages from debugging)" -ForegroundColor White
