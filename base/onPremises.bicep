param tags object

param vnetConfiguration object
param subnetConfiguration object

module vnet '../modules/Microsoft.Network/vnet.bicep' = {
  name: vnetConfiguration.name
  params: {
    tags: tags
    vnetConfiguration: vnetConfiguration
    subnetConfiguration: subnetConfiguration
  }
}
