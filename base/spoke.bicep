param tags object

param vnetConfiguration object
param subnetConfiguration object

param vmConfiguration object
@secure()
param adminPassword string

param storageConfiguration object

module vnet '../modules/Microsoft.Network/vnet.bicep' = {
  name: '${vnetConfiguration.name}-Deploy'
  params: {
    tags: tags
    vnetConfiguration: vnetConfiguration
    subnetConfiguration: subnetConfiguration
  }
}

module nicVmSpoke1 '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmConfiguration.nicName}-Deploy'
  dependsOn: [
    vnet
  ]
  params: {
    name: vmConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.Frontend.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
  }
}

module vmSpoke1 '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmConfiguration.name}-Deploy'
  dependsOn: [
    nicVmSpoke1
  ]
  params: {
    adminPassword: adminPassword
    adminUsername: vmConfiguration.adminUsername
    name: vmConfiguration.name
    nicName: vmConfiguration.nicName
    tags: tags
    vmSize: vmConfiguration.sku
  }
}

module storageSpoke1 '../modules/Microsoft.Storage/storageAccount.bicep' = {
  name: '${storageConfiguration.name}-Deploy'
  params: {
    name: storageConfiguration.name
    tags: tags
  }
}


var privateDnsZonesInfo = [
  {
    name: format('privatelink.blob.{0}', environment().suffixes.storage)
    vnetLinkName: 'vnet-link-blob-to-'
    vnetName: vmConfiguration.name
  }
]

module storageSpoke1Pe '../modules/Microsoft.Network/storagePrivateEndpoint.bicep' = {
  name: '${storageConfiguration.name}PrivateEndpoint-Deploy'
  dependsOn: [
    storageSpoke1
  ]
  params: {
    groupIds:'blob'
    name: storageConfiguration.privateEndpointName
    privateDnsZoneName: privateDnsZonesInfo[0].name
    sharedResourceGroupName: resourceGroup().name
    snetName: subnetConfiguration.Backend.name
    storageAccountName: storageConfiguration.name 
    tags: tags
    vnetName: vnetConfiguration.name
  }
}
