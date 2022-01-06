param location string = resourceGroup().location
param tags object
param vmInfo object
param vNet object
@secure()
param adminPassword string
var nicsInfo = vmInfo.nics

resource NICs 'Microsoft.Network/networkInterfaces@2021-05-01' = [for nic in nicsInfo: {
  name: nic.name
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {

          subnet: {
            id: '/subscriptions/${vNet.subscriptionId}/resourceGroups/${vNet.resourceGroupName}/providers/${vNet.resourceId}/subnets/${nic.subnetName}'
          }
          primary: true
          privateIPAllocationMethod: contains(nic, 'privateIPAddress') && !empty(nic.privateIPAddress) ? 'Static' : 'Dynamic'
          privateIPAddress: contains(nic, 'privateIPAddress') && !empty(nic.privateIPAddress) ? nic.privateIPAddress : null
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
      networkInterfaces: [for i in range(0, length(nicsInfo)): {
        id: NICs[i].id
      }]
    }
  }
}

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = if ((contains(vmInfo, 'scriptToRun') && !empty(vmInfo.scriptToRun)) || (contains(vmInfo, 'scriptUri') && !empty(vmInfo.scriptUri))) {
  name: '${vmInfo.name}-runCommand'
  location: location
  tags: tags
  parent: VM
  properties: {
    // asyncExecution: true //Turn on to avoid the wait
    source: {
      script: (contains(vmInfo, 'scriptToRun') && !empty(vmInfo.scriptToRun)) ? vmInfo.scriptToRun : ''
      scriptUri: (contains(vmInfo, 'scriptUri') && !empty(vmInfo.scriptUri)) ? vmInfo.scriptUri : ''
    }
    timeoutInSeconds: (contains(vmInfo, 'timeoutInSeconds') && !empty(vmInfo.timeoutInSeconds)) ? vmInfo.timeoutInSeconds : null
  }
}
