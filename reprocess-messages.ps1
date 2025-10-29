# Reprocess Dead Letter Messages - Simple Version
$ErrorActionPreference = "Continue"

Write-Host "`n=== Reprocessing 18 Dead Letter Messages ===" -ForegroundColor Cyan

# Get connection string
Write-Host "`nGetting Service Bus connection..." -ForegroundColor Yellow
$connString = az servicebus namespace authorization-rule keys list -g rg-d365-demo-v2 --namespace-name demo-sb-nfittwqa7bkom --name RootManageSharedAccessKey --query primaryConnectionString -o tsv

if (-not $connString) {
    Write-Host "[ERROR] Could not get connection string" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Connection string retrieved" -ForegroundColor Green

# Check if Azure.Messaging.ServiceBus is available
Write-Host "`nChecking for Azure Service Bus SDK..." -ForegroundColor Yellow
$module = Get-Module -ListAvailable -Name Azure.Messaging.ServiceBus -ErrorAction SilentlyContinue

if (-not $module) {
    Write-Host "Azure.Messaging.ServiceBus module not found." -ForegroundColor Yellow
    Write-Host "Installing module (this may take a minute)..." -ForegroundColor Gray
    try {
        Install-Module -Name Azure.Messaging.ServiceBus -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
        Write-Host "[OK] Module installed" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Could not install module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPlease reprocess manually via Azure Portal:" -ForegroundColor Yellow
        Write-Host "  1. Go to: https://portal.azure.com" -ForegroundColor White
        Write-Host "  2. Navigate to Service Bus queue: demo-sb-nfittwqa7bkom -> inbound" -ForegroundColor White
        Write-Host "  3. Service Bus Explorer -> Dead-letter tab -> Resubmit" -ForegroundColor White
        exit 1
    }
}

Write-Host "[OK] SDK available" -ForegroundColor Green

# Import and reprocess
Write-Host "`nReprocessing messages..." -ForegroundColor Yellow

try {
    Import-Module Azure.Messaging.ServiceBus
    
    $client = [Azure.Messaging.ServiceBus.ServiceBusClient]::new($connString)
    $dlqReceiver = $client.CreateReceiver("inbound", [Azure.Messaging.ServiceBus.ServiceBusReceiverOptions]@{ SubQueue = [Azure.Messaging.ServiceBus.SubQueue]::DeadLetter })
    $sender = $client.CreateSender("inbound")
    
    $count = 0
    $maxMessages = 20
    
    for ($i = 0; $i -lt $maxMessages; $i++) {
        try {
            $msg = $dlqReceiver.ReceiveMessageAsync([TimeSpan]::FromSeconds(3)).GetAwaiter().GetResult()
            
            if ($null -eq $msg) {
                Write-Host "`nNo more messages in dead letter queue" -ForegroundColor Gray
                break
            }
            
            # Create new message with same body
            $newMsg = [Azure.Messaging.ServiceBus.ServiceBusMessage]::new($msg.Body)
            
            # Send to active queue
            $sender.SendMessageAsync($newMsg).GetAwaiter().GetResult() | Out-Null
            
            # Complete from dead letter
            $dlqReceiver.CompleteMessageAsync($msg).GetAwaiter().GetResult() | Out-Null
            
            $count++
            Write-Host "  Resubmitted message $count" -ForegroundColor Green
            
        } catch {
            Write-Host "  Error on message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $dlqReceiver.CloseAsync().GetAwaiter().GetResult() | Out-Null
    $sender.CloseAsync().GetAwaiter().GetResult() | Out-Null
    $client.DisposeAsync().GetAwaiter().GetResult() | Out-Null
    
    Write-Host "`n=== Reprocessing Complete ===" -ForegroundColor Green
    Write-Host "Resubmitted: $count messages" -ForegroundColor Cyan
    Write-Host "They will now be processed by SbProcessor function automatically." -ForegroundColor Green
    
} catch {
    Write-Host "`n[ERROR] Reprocessing failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease use Azure Portal instead:" -ForegroundColor Yellow
    Write-Host "Opening portal..." -ForegroundColor Gray
    Start-Process "https://portal.azure.com/#@/resource/subscriptions/9019cfb1-cb52-4c48-a0a8-727ad3933f34/resourceGroups/rg-d365-demo-v2/providers/Microsoft.ServiceBus/namespaces/demo-sb-nfittwqa7bkom/queues/inbound/explorer"
    exit 1
}
