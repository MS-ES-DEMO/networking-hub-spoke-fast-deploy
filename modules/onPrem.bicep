param location string = resourceGroup().location
param info object
@secure()
param vmOnPremAdminPassword string

resource VNetOnPrem 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: info.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        info.range
      ]
    }
    subnets: [for subnet in info.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.range
      }
    }]
  }
}

// This would have to be substituted by an NVA for more complex traffic
resource VMs 'Microsoft.Compute/virtualMachines@2021-07-01' = [for vm in items(info.vms): {
  location: location
  name: vm.value.name
  properties: {
    hardwareProfile: {
      vmSize: vm.value.sku
    }
    storageProfile: {
      imageReference: {
        publisher: '' //TO-DO
        sku: '' //TO-DO
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
        diskSizeGB: vm.value.osDiskSizeGB
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm.value.name
      adminUsername: vm.value.adminUsername
      adminPassword: vmOnPremAdminPassword
      allowExtensionOperations: true
      linuxConfiguration:{
        provisionVMAgent: true
      }
    }
    
    //TO-DO: Add network interfaces
  }
}]

resource VPNGateway 'Microsoft.Network/vpnGateways@2021-05-01' = {
  name: info.vpnGatewayName
  location: location
}
