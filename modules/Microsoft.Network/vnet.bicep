param location string = resourceGroup().location
param tags object
param vnetConfiguration object
param subnetConfiguration object

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetConfiguration.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetConfiguration.range
      ]
    }
    subnets: [for snetInfo in items(subnetConfiguration): {
      name: '${snetInfo.value.name}'
      properties: {
        addressPrefix: '${snetInfo.value.range}'
      }
    }]
  }
}
