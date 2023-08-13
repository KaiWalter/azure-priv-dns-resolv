param location string
param resourceToken string
param tags object

param vmCustomData string
param adminUsername string
param adminPasswordOrKey string

module network './network.bicep' = {
  name: 'network'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

module vmCorpDns './corp-dns-vm.bicep' = {
  name: 'vmCorpDns'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    vmCustomData: vmCustomData
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    subnetId: network.outputs.subnetCorpDnsId
    nsgId: network.outputs.vmNsgId
  }
}
