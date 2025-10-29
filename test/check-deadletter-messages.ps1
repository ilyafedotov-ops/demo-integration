# Peek at dead letter messages to see error details
$sbConnString = "CONNSTRING_PLACEHOLDER"
$queueName = "inbound"

Add-Type -AssemblyName "System.ServiceModel"
$null = [Reflection.Assembly]::LoadWithPartialName("Microsoft.ServiceBus")

Write-Host "Note: This requires Azure.Messaging.ServiceBus module" -ForegroundColor Yellow
Write-Host "Install with: Install-Module -Name Az.ServiceBus" -ForegroundColor Gray
Write-Host "`nTo view dead letter messages in Azure Portal:" -ForegroundColor Cyan
Write-Host "1. Go to: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Navigate to: Service Bus Namespaces > demo-sb-nfittwqa7bkom > Queues > inbound" -ForegroundColor White
Write-Host "3. Click 'Service Bus Explorer' in left menu" -ForegroundColor White
Write-Host "4. Select 'Dead-letter' tab" -ForegroundColor White
Write-Host "5. Click 'Peek from start' to see message details" -ForegroundColor White
Write-Host "6. Look for 'DeadLetterReason' and 'DeadLetterErrorDescription' properties" -ForegroundColor White
