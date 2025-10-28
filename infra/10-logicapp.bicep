param prefix string = 'd365demo'
param location string = resourceGroup().location
param functionBaseUrl string
param functionKey string
param d365HostUrl string = ''
param d365AccessToken string = ''

var laName = '${prefix}-la-${uniqueString(resourceGroup().id)}'
var definition = json(loadTextContent('../logicapp/logicapp.vendor.ingest.definition.json'))

resource lawf 'Microsoft.Logic/workflows@2019-05-01' = {
  name: laName
  location: location
  properties: {
    state: 'Enabled'
    definition: definition
    parameters: {
      functionBaseUrl: { value: functionBaseUrl }
      functionKey: { value: functionKey }
      d365HostUrl: { value: d365HostUrl }
      d365AccessToken: { value: d365AccessToken }
    }
  }
}

output logicAppName string = lawf.name
