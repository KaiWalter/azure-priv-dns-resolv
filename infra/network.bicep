param location string
param resourceToken string
param tags object

param corpBaseAdress string = '10.0.0.0/19'
param spokeBaseAdress string = '10.32.0.0/19'
param hubBaseAddress string = '10.42.10.0/24'

resource vnetCorp 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-corp-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        corpBaseAdress
      ]
    }
    subnets: [
      {
        name: 'dns'
        properties: {
          addressPrefix: cidrSubnet(corpBaseAdress,21,0)
        }
      }
      {
        name: 'jump'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(corpBaseAdress,21,1),26,0) // 1st /26 range in 2nd /21 range block
        }
      }
    ]
  }
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-spoke-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeBaseAdress
      ]
    }
    subnets: [
      {
        name: 'jump'
        properties: {
          addressPrefix: cidrSubnet(spokeBaseAdress,26,0) // 1st /26 range block
        }
      }
    ]
  }
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-hub-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubBaseAddress
      ]
    }
    subnets: [
      {
        name: 'jump'
        properties: {
          addressPrefix: cidrSubnet(hubBaseAddress,26,0)
        }
      }
    ]
  }
}

resource nsgVm 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-vm-${resourceToken}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

output subnetCorpDnsId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetCorp.name, 'dns')
output vmNsgId string = nsgVm.id
