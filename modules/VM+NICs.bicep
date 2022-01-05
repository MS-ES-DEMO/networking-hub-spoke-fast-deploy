param location string = resourceGroup().location
param tags object
param vmInfo object
param vNet object
@secure()
param adminPassword string

resource NICs 'Microsoft.Network/networkInterfaces@2021-05-01' = [for nic in vmInfo.nics: {
  name: nic.nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vNet.id}/subnets/${nic.subnetName}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}]

resource VM 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  location: location
  name: vmInfo.name
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmInfo.sku
    }
    storageProfile: {
      imageReference: { //TO-DO: Make more flexible
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: vmInfo.osType
        createOption: vmInfo.createOption
        diskSizeGB: vmInfo.osDiskSizeGB
        managedDisk: {
          storageAccountType: vmInfo.osDiskType
        }
      }
    }
    osProfile: {
      computerName: vmInfo.name
      adminUsername: vmInfo.adminUsername
      adminPassword: adminPassword
      allowExtensionOperations: true
      linuxConfiguration: {
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [for i in range(0, length(vmInfo.nics)): {
        id: NICs[i].id
      }]
    }
  }
}
