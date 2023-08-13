param location string
param resourceToken string
param tags object

param subnetId string
param nsgId string

param vmCustomData string
param adminUsername string
param adminPasswordOrKey string

param authenticationType string = 'sshPublicKey'

var vmName = 'vm-corp-dns-${resourceToken}'
var publicIPAddressName = '${vmName}-ip'
var networkInterfaceName = '${vmName}-nic'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIPAddressName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: vmName
    }
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-minimal-lunar'
        sku: 'minimal-23_04'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      customData: base64(vmCustomData)
      linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration)
    }
  }
}

output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
