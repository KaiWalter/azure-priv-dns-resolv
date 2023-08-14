param location string
param resourceToken string
param tags object

param vmCustomData string
param adminUsername string
@secure()
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
module hubJump 'containergroup.bicep' = {
  name: 'hubJump'
  params: {
    location: location
    tags: tags
    name: 'hub-jump-${resourceToken}'
    subnetId: network.outputs.subnetHubJumpId
  }
}

module spokeJump 'containergroup.bicep' = {
  name: 'spokeJump'
  params: {
    location: location
    tags: tags
    name: 'spoke-jump-${resourceToken}'
    subnetId: network.outputs.subnetSpokeJumpId
  }
}

