# Monitoring and Alerting Configuration for D365 Demo
# This file contains Azure Monitor alert rules for the demo

param(
    [string]$ResourceGroup = "rg-d365-demo",
    [string]$Location = "westeurope"
)

# Create action group for notifications
$actionGroupName = "d365-demo-alerts"
$emailAddress = "admin@demoentraid123.onmicrosoft.com"  # Demo admin email

Write-Host "Creating action group..." -ForegroundColor Yellow
az monitor action-group create `
    --name $actionGroupName `
    --resource-group $ResourceGroup `
    --location $Location `
    --short-name "D365Demo" `
    --email-receivers name="Admin" email-address=$emailAddress

Write-Host "Creating action group..." -ForegroundColor Yellow
az monitor action-group create `
    --name $actionGroupName `
    --resource-group $ResourceGroup `
    --location $Location `
    --short-name "D365Demo" `
    --email-receivers name="Admin" email-address=$emailAddress

# Get resource IDs
$funcAppId = az functionapp show --resource-group $ResourceGroup --name (az functionapp list --resource-group $ResourceGroup --query "[0].name" -o tsv) --query "id" -o tsv
$logicAppId = az logic workflow show --resource-group $ResourceGroup --name (az logic workflow list --resource-group $ResourceGroup --query "[0].name" -o tsv) --query "id" -o tsv
$apimId = az apim show --resource-group $ResourceGroup --name (az apim list --resource-group $ResourceGroup --query "[0].name" -o tsv) --query "id" -o tsv

# Alert 1: Function App Errors
Write-Host "Creating Function App error alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "Function App Errors" `
    --resource-group $ResourceGroup `
    --scopes $funcAppId `
    --condition "count 'exceptions' > 5" `
    --description "Alert when Function App has more than 5 exceptions" `
    --evaluation-frequency 5m `
    --window-size 15m `
    --severity 2 `
    --action $actionGroupName

# Alert 2: Logic App Failures
Write-Host "Creating Logic App failure alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "Logic App Failures" `
    --resource-group $ResourceGroup `
    --scopes $logicAppId `
    --condition "count 'runs_failed' > 3" `
    --description "Alert when Logic App has more than 3 failed runs" `
    --evaluation-frequency 5m `
    --window-size 15m `
    --severity 2 `
    --action $actionGroupName

# Alert 3: APIM High Response Time
Write-Host "Creating APIM response time alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "APIM High Response Time" `
    --resource-group $ResourceGroup `
    --scopes $apimId `
    --condition "avg 'duration' > 5000" `
    --description "Alert when APIM average response time exceeds 5 seconds" `
    --evaluation-frequency 5m `
    --window-size 15m `
    --severity 3 `
    --action $actionGroupName

# Alert 4: Service Bus Queue Depth
Write-Host "Creating Service Bus queue depth alert..." -ForegroundColor Yellow
$sbNamespace = az servicebus namespace list --resource-group $ResourceGroup --query "[0].name" -o tsv
$sbId = az servicebus namespace show --resource-group $ResourceGroup --name $sbNamespace --query "id" -o tsv

az monitor metrics alert create `
    --name "Service Bus Queue Depth" `
    --resource-group $ResourceGroup `
    --scopes $sbId `
    --condition "avg 'active_messages' > 100" `
    --description "Alert when Service Bus queue has more than 100 active messages" `
    --evaluation-frequency 5m `
    --window-size 15m `
    --severity 2 `
    --action $actionGroupName

Write-Host "Monitoring alerts configured successfully!" -ForegroundColor Green
Write-Host "Alerts will be sent to: admin@demoentraid123.onmicrosoft.com" -ForegroundColor Cyan
