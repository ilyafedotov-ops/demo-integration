param prefix string = 'd365demo'
param location string = resourceGroup().location

var suffix = uniqueString(resourceGroup().id)

//
// Observability
//
resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${prefix}-law-${suffix}'
  location: location
  properties: {
    retentionInDays: 30
    features: { enableLogAccessUsingOnlyResourcePermissions: true }
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: '${prefix}-appi-${suffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: la.id
  }
}

//
// Key Vault (RBAC)
//
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${prefix}-kv-${suffix}'
  location: location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: { name: 'standard', family: 'A' }
    softDeleteRetentionInDays: 7
  }
}

//
// Storage: data lake (ADLS Gen2) and runtime (Functions host)
//
resource stdata 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('${prefix}std${substring(suffix, 0, 8)}')
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource stapp 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('${prefix}app${substring(suffix, 0, 8)}')
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

var stappKeys = listKeys(stapp.id, '2023-01-01')
var stappConn = 'DefaultEndpointsProtocol=https;AccountName=${stapp.name};AccountKey=${stappKeys.keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

//
// Service Bus (Standard) + queue
//
resource sb 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: '${prefix}-sb-${suffix}'
  location: location
  sku: { name: 'Standard', tier: 'Standard' }
}

resource sbq 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: '${sb.name}/inbound'
  properties: {
    maxDeliveryCount: 10
    deadLetteringOnMessageExpiration: true
  }
}

//
// APIM (Consumption) with MI
//
resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: '${prefix}-apim-${suffix}'
  location: location
  sku: { name: 'Consumption', capacity: 0 }
  identity: { type: 'SystemAssigned' }
  properties: {
    publisherEmail: 'admin@demoentraid123.onmicrosoft.com'
    publisherName: 'Demo'
  }
}

//
// Function App on Flex Consumption (Linux), PowerShell
//
resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: '${prefix}-plan-${suffix}'
  location: location
  sku: { name: 'Y1', tier: 'Dynamic', capacity: 0 }
  kind: 'functionapp'
  properties: { reserved: true }
}

resource func 'Microsoft.Web/sites@2024-04-01' = {
  name: '${prefix}-func-${suffix}'
  location: location
  kind: 'functionapp'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'powershell' }
        { name: 'AzureWebJobsStorage', value: stappConn }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
        { name: 'AzureWebJobsServiceBus__fullyQualifiedNamespace', value: '${sb.name}.servicebus.windows.net' }
        { name: 'APPINSIGHTS_INSTRUMENTATIONKEY', value: appi.properties.InstrumentationKey }
        { name: 'DEMO_STORAGE_ACCOUNT', value: stdata.name }
        { name: 'DEMO_STORAGE_CONTAINER', value: 'landing' }
      ]
    }
  }
}

//
// RBAC for MI: Service Bus + Data Lake
//
resource roleSbSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(func.id, 'sb-sender')
  scope: sb
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
    principalId: func.identity.principalId
  }
}

resource roleSbReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(func.id, 'sb-receiver')
  scope: sb
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
    principalId: func.identity.principalId
  }
}

resource roleBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(func.id, 'blob-contrib')
  scope: stdata
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: func.identity.principalId
  }
}

output apimName string = apim.name
output funcName string = func.name
output funcHostName string = '${func.name}.azurewebsites.net'
output serviceBusQueue string = sbq.name
output dataStorageName string = stdata.name
