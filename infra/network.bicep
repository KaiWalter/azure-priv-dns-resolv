param location string
param resourceToken string
param tags object

@description('name of the subnet that will be used for private resolver outbound endpoint')
param outboundSubnet string = 'dns'

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param targetDNS array = [
  {
    ipaddress: '10.0.0.4'
    port: 53
  }
]

@description('name of the forwarding rule name')
param forwardingRuleName string = 'acmecorpnet'

@description('the target domain name for the forwarding ruleset')
param domainName string = 'acme-corp.net.'

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
          addressPrefix: cidrSubnet(corpBaseAdress, 21, 0)
        }
      }
      {
        name: 'jump'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(corpBaseAdress, 21, 1), 26, 0) // 1st /26 range in 2nd /21 range block
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
        name: outboundSubnet
        properties: {
          addressPrefix: cidrSubnet(hubBaseAddress, 26, 1)
          delegations: [
            {
              name: 'microsoft.network.dnsresolver'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: 'jump'
        properties: {
          addressPrefix: cidrSubnet(hubBaseAddress, 26, 0)
          delegations: [
            {
              name: 'microsoft.containerinstance'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
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
          addressPrefix: cidrSubnet(spokeBaseAdress, 26, 0) // 1st /26 range block
          delegations: [
            {
              name: 'microsoft.containerinstance'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
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

// hub virtual network and spoke virtual network are peered
resource peerHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'hub-to-spoke'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
  }
}

resource peerSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'spoke-to-hub'
  parent: vnetSpoke
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

// hub virtual network and corporate virtual network are peered
resource peerHubCorporate 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'hub-to-corp'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetCorp.id
    }
  }
}

resource peerCorporateHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'corp-to-hub'
  parent: vnetCorp
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

// DNS resolver sample : https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-bicep?tabs=CLI

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: 'dns-priv-${resourceToken}'
  location: location
  properties: {
    virtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  name: outboundSubnet
  location: location
  properties: {
    subnet: {
      id: '${vnetHub.id}/subnets/${outboundSubnet}'
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: 'dns-fwdrule-${resourceToken}'
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverSpokeLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: fwruleSet
  name: 'vnet-spoke-link'
  properties: {
    virtualNetwork: {
      id: vnetSpoke.id
    }
  }
}

resource resolverHubLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: fwruleSet
  name: 'vnet-hub-link'
  properties: {
    virtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: fwruleSet
  name: forwardingRuleName
  properties: {
    domainName: domainName
    targetDnsServers: targetDNS
  }
}

output subnetCorpDnsId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetCorp.name, 'dns')
output subnetHubJumpId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetHub.name, 'jump')
output subnetSpokeJumpId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetSpoke.name, 'jump')
output vmNsgId string = nsgVm.id
