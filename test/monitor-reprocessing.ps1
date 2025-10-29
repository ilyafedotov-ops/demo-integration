# Monitor Message Reprocessing in Real-Time
Write-Host "`n=== Monitoring Service Bus Reprocessing ===" -ForegroundColor Cyan
Write-Host "Watching for messages being reprocessed..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring`n" -ForegroundColor Gray

$previousDeadLetter = 18
$previousActive = 0
$startTime = Get-Date

while ($true) {
    try {
        # Get current queue stats
        $queueData = az servicebus queue show -g rg-d365-demo-v2 --namespace-name demo-sb-nfittwqa7bkom -n inbound -o json 2>$null | ConvertFrom-Json
        
        if ($queueData) {
            $currentDeadLetter = $queueData.countDetails.deadLetterMessageCount
            $currentActive = $queueData.countDetails.activeMessageCount
            
            $timestamp = Get-Date -Format "HH:mm:ss"
            
            # Check if anything changed
            if ($currentDeadLetter -ne $previousDeadLetter -or $currentActive -ne $previousActive) {
                $dlChange = $previousDeadLetter - $currentDeadLetter
                $activeChange = $currentActive - $previousActive
                
                Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
                Write-Host "Dead Letter: $currentDeadLetter " -NoNewline -ForegroundColor $(if ($dlChange -gt 0) { "Green" } else { "Yellow" })
                Write-Host "(-$dlChange) | " -NoNewline -ForegroundColor Green
                Write-Host "Active: $currentActive " -NoNewline -ForegroundColor $(if ($activeChange -ne 0) { "Cyan" } else { "White" })
                
                if ($activeChange -gt 0) {
                    Write-Host "(+$activeChange) " -NoNewline -ForegroundColor Cyan
                }
                
                Write-Host "→ Reprocessing..." -ForegroundColor Yellow
                
                $previousDeadLetter = $currentDeadLetter
                $previousActive = $currentActive
            }
            
            # Check if all done
            if ($currentDeadLetter -eq 0 -and $currentActive -eq 0) {
                Write-Host "`n[SUCCESS] All messages reprocessed!" -ForegroundColor Green
                Write-Host "Checking storage for files..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
                
                $conn = az storage account show-connection-string -g rg-d365-demo-v2 -n demodatanfittwqa -o tsv
                $blobs = az storage blob list --account-name demodatanfittwqa --container-name landing --prefix vendors/ --connection-string $conn -o json 2>$null | ConvertFrom-Json
                
                if ($blobs) {
                    Write-Host "[SUCCESS] $($blobs.Count) total files in storage!" -ForegroundColor Green
                }
                
                $elapsed = (Get-Date) - $startTime
                Write-Host "`nTotal time: $($elapsed.TotalSeconds) seconds" -ForegroundColor Gray
                break
            }
        }
        
        Start-Sleep -Seconds 2
        
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

Write-Host "`nMonitoring complete." -ForegroundColor Cyan
