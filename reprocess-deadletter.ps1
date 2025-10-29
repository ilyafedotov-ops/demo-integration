# Reprocess Dead Letter Messages
$ErrorActionPreference = "Stop"

Write-Host "`n=== Dead Letter Message Reprocessing ===" -ForegroundColor Cyan

# Configuration
$resourceGroup = "rg-d365-demo-v2"
$namespace = "demo-sb-nfittwqa7bkom"
$queueName = "inbound"

# Get connection string
Write-Host "`n[1/4] Getting Service Bus connection string..." -ForegroundColor Yellow
$connString = az servicebus namespace authorization-rule keys list `
    -g $resourceGroup `
    --namespace-name $namespace `
    --name RootManageSharedAccessKey `
    --query primaryConnectionString -o tsv

Write-Host "[OK] Connection string retrieved" -ForegroundColor Green

# Check dead letter count
Write-Host "`n[2/4] Checking dead letter queue..." -ForegroundColor Yellow
$queueInfo = az servicebus queue show `
    -g $resourceGroup `
    --namespace-name $namespace `
    -n $queueName `
    -o json | ConvertFrom-Json

$deadLetterCount = $queueInfo.countDetails.deadLetterMessageCount
Write-Host "Dead letter messages: $deadLetterCount" -ForegroundColor Cyan

if ($deadLetterCount -eq 0) {
    Write-Host "[INFO] No dead letter messages to reprocess" -ForegroundColor Green
    exit 0
}

Write-Host "`n[3/4] Installing Azure Service Bus module (if needed)..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name Azure.Messaging.ServiceBus)) {
    Write-Host "Installing Azure.Messaging.ServiceBus module..." -ForegroundColor Gray
    Install-Module -Name Azure.Messaging.ServiceBus -Scope CurrentUser -Force -AllowClobber
    Write-Host "[OK] Module installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Module already installed" -ForegroundColor Green
}

Write-Host "`n[4/4] Reprocessing messages..." -ForegroundColor Yellow

try {
    # Parse connection string
    $connParts = @{}
    $connString.Split(';') | ForEach-Object {
        if ($_ -match '^(.+?)=(.+)$') {
            $connParts[$matches[1]] = $matches[2]
        }
    }
    
    $endpoint = $connParts['Endpoint'].Replace('sb://', '').Replace('/', '')
    $sasKeyName = $connParts['SharedAccessKeyName']
    $sasKey = $connParts['SharedAccessKey']
    
    Write-Host "Endpoint: $endpoint" -ForegroundColor Gray
    Write-Host "Queue: $queueName" -ForegroundColor Gray
    Write-Host "Dead letter count: $deadLetterCount" -ForegroundColor Gray
    
    # Create Service Bus client
    $client = New-Object Azure.Messaging.ServiceBus.ServiceBusClient($connString)
    
    # Create receivers for dead letter and sender for main queue
    $deadLetterReceiver = $client.CreateReceiver($queueName, [Azure.Messaging.ServiceBus.ServiceBusReceiverOptions]@{
        SubQueue = [Azure.Messaging.ServiceBus.SubQueue]::DeadLetter
    })
    
    $sender = $client.CreateSender($queueName)
    
    $reprocessedCount = 0
    $failedCount = 0
    
    Write-Host "`nReprocessing messages (max 100)..." -ForegroundColor Cyan
    
    for ($i = 0; $i -lt [Math]::Min($deadLetterCount, 100); $i++) {
        try {
            # Receive message from dead letter queue
            $message = $deadLetterReceiver.ReceiveMessageAsync([TimeSpan]::FromSeconds(5)).GetAwaiter().GetResult()
            
            if ($null -eq $message) {
                Write-Host "No more messages available" -ForegroundColor Gray
                break
            }
            
            Write-Host "  Processing message $($i+1)..." -ForegroundColor Gray
            
            # Create new message with same body
            $newMessage = New-Object Azure.Messaging.ServiceBus.ServiceBusMessage($message.Body)
            
            # Copy application properties
            foreach ($prop in $message.ApplicationProperties.Keys) {
                $newMessage.ApplicationProperties[$prop] = $message.ApplicationProperties[$prop]
            }
            
            # Send to main queue
            $sender.SendMessageAsync($newMessage).GetAwaiter().GetResult()
            
            # Complete (remove) from dead letter queue
            $deadLetterReceiver.CompleteMessageAsync($message).GetAwaiter().GetResult()
            
            $reprocessedCount++
            Write-Host "  ✓ Message $($i+1) resubmitted" -ForegroundColor Green
            
        } catch {
            $failedCount++
            Write-Host "  ✗ Message $($i+1) failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Close connections
    $deadLetterReceiver.CloseAsync().GetAwaiter().GetResult()
    $sender.CloseAsync().GetAwaiter().GetResult()
    $client.DisposeAsync().GetAwaiter().GetResult()
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Reprocessed: $reprocessedCount messages" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "Failed: $failedCount messages" -ForegroundColor Red
    }
    Write-Host "`nMessages have been moved back to the active queue." -ForegroundColor Green
    Write-Host "They will be processed by the SbProcessor function automatically." -ForegroundColor Green
    
} catch {
    Write-Host "`n[ERROR] Reprocessing failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nAlternative: Use Azure Portal" -ForegroundColor Yellow
    Write-Host "1. Go to: https://portal.azure.com" -ForegroundColor White
    Write-Host ("2. Navigate to: Service Bus -> {0} -> Queues -> {1}" -f $namespace, $queueName) -ForegroundColor White
    Write-Host "3. Click Service Bus Explorer" -ForegroundColor White
    Write-Host "4. Go to Dead-letter tab" -ForegroundColor White
    Write-Host "5. Select messages and click Resubmit" -ForegroundColor White
    exit 1
}
