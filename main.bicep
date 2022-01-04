targetScope = 'subscription'

@description('Azure region where the Resource Group and its resources will be deployed')
param location string
@description('Tags associated with all resources')
param tags object
param resourceGroupName string
param hubVNetInfo object
param onPremVNetInfo object
param spoke1VNetInfo object
param privateLinkVNetInfo object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module VNetHub 'modules/hub.bicep' = {
  scope: resourceGroup
  name: hubVNetInfo.name
  params: {
    info: hubVNetInfo
  }
}

module VNetOnPrem 'modules/onPrem.bicep' = {
  scope: resourceGroup
  name: onPremVNetInfo.name
  params: {
    info: onPremVNetInfo
  }
}

module VNetSpoke1 'modules/spoke.bicep' = {
  scope: resourceGroup
  name: spoke1VNetInfo.name
  params: {
    info: spoke1VNetInfo
    vmSpoke1: {}
    vmSpoke1AdminPassword: ''
  }
}

module VNetPrivateLink 'modules/privatelink.bicep' = {
  scope: resourceGroup
  name: privateLinkVNetInfo.name
  params: {
    info: privateLinkVNetInfo
  }
}
