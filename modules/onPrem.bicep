param location string = resourceGroup().location
param rgName string = resourceGroup().name
param info object

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

resource NetworkVirtualAppliances 'Microsoft.Network/networkVirtualAppliances@2021-05-01' = {
  name: info.vms.vmOnpremises.name
  location: location
  properties: {
    
  }
}
