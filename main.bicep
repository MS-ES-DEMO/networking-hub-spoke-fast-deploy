targetScope = 'subscription'

@description('Azure region where the Resource Group and its resources will be deployed')
param location string
@description('Tags associated with all resources')
param tags object
param resourceGroupName string

param timeStamp string = utcNow()

@secure()
param adminPassword string

param hubVnetConfiguration object
param onPremisesVnetConfiguration object

param spoke1VnetConfiguration object
param spoke1VmConfiguration object
param spoke1StorageConfiguration object

param privateLinkVnetConfiguration object
param privateLinkVmConfiguration object

param hubBastionConfiguration object

@description('Azure Firewall configuration parameters')
param firewallConfiguration object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module hub 'base/hub.bicep' = {
  name: 'Hub-Deployment-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    vnetConfiguration: hubVnetConfiguration
    subnetConfiguration: hubVnetConfiguration.subnets
    bastionName: hubBastionConfiguration.name
    firewallConfiguration: firewallConfiguration
  }
}

module onpremises 'base/onPremises.bicep' = {
  name: 'OnPremises-Deployment-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    vnetConfiguration: onPremisesVnetConfiguration
    subnetConfiguration: onPremisesVnetConfiguration.subnets
  }
}

module spoke1 'base/spoke.bicep' = {
  name: 'Spoke1-Deployment-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    vnetConfiguration: spoke1VnetConfiguration
    subnetConfiguration: spoke1VnetConfiguration.subnets
    vmConfiguration: spoke1VmConfiguration
    adminPassword: adminPassword
    storageConfiguration: spoke1StorageConfiguration
  }
}

module privatelink 'base/privatelink.bicep' = {
  name: 'PrivateLink-Deployment-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    vnetConfiguration: privateLinkVnetConfiguration
    subnetConfiguration: privateLinkVnetConfiguration.subnets
    adminPassword: adminPassword
    vmConfiguration: privateLinkVmConfiguration
  } 
}


