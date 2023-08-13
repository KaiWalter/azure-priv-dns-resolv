targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

param vmCustomData string
param adminUsername string
param adminPasswordOrKey string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
}

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {}

module resources './resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: resourceGroup
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    vmCustomData: vmCustomData
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
  }
}
