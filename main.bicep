targetScope = 'subscription'

// Global Parameters
@description('Azure region where the Resource Group and its resources will be deployed')
param location string
@description('Tags associated with all resources')
param tags object

param resourceGroupName string
param vnetNames object

var hubVNetName = vnetNames.hub
var onPremVNetName = vnetNames.onPrem
var spoke1VNetName = vnetNames.spoke1
var privateLinkVNetName = vnetNames.privateLink


resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module VNetHub 'modules/hub.bicep' = {
  name: hubVNetName
  scope: resourceGroup
  params: {
    name: hubVNetName
  }
}

module VNetOnPrem 'modules/onPrem.bicep' = {
  name: onPremVNetName
  scope: resourceGroup
  params: {
    name: hubVNetName
  }
}

module VNetSpoke1 'modules/spoke.bicep'= {
  name: spoke1VNetName
  scope: resourceGroup
  params: {
    name: hubVNetName
    spoke1VnetInfo: {}
    vmSpoke1: {}
    vmSpoke1AdminPassword: ''
  }
}

module VNetPrivateLink 'modules/privatelink.bicep' = {
  name: privateLinkVNetName
  scope: resourceGroup
  params: {
    name: hubVNetName
  }
}
