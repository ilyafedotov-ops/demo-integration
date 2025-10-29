# Check dead letter messages using Service Bus SDK
$namespaceName = "demo-sb-nfittwqa7bkom"
$queueName = "inbound"
$resourceGroup = "rg-d365-demo-v2"

Write-Host "Getting dead letter queue information..."

# Get the dead letter queue properties
$queue = az servicebus queue show `
    --resource-group $resourceGroup `
    --namespace-name $namespaceName `
    --name $queueName `
    --query "{activeMessages:countDetails.activeMessageCount, deadLetterMessages:countDetails.deadLetterMessageCount}" `
    -o json | ConvertFrom-Json

Write-Host "Dead Letter Messages: $($queue.deadLetterMessages)"

# Try to peek dead letter messages using REST API
$connStr = az servicebus namespace authorization-rule keys list `
    --resource-group $resourceGroup `
    --namespace-name $namespaceName `
    --name RootManageSharedAccessKey `
    --query "primaryConnectionString" -o tsv

Write-Host "Connection String obtained"
Write-Host "Note: Azure CLI doesn't support reading dead letter messages directly."
Write-Host "Recommendation: Use Azure Portal > Service Bus > Queue > Dead-letter tab to view messages"
