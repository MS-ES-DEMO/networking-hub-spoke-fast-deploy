targetScope = 'subscription'

@description('Azure region where the Resource Group and its resources will be deployed')
param location string
@description('Tags associated with all resources')
param tags object
@description('Resource group where all resources would be deployed')
param resourceGroupName string
@description('Deployment suffix associated with the actual deployment time')
param timeStamp string = utcNow()

@secure()
param adminPassword string

param hubVnetConfiguration object
param hubNvaVmConfiguration object
param hubBgpVmConfiguration object
param hubBastionConfiguration object
param hubFirewallConfiguration object
@secure()
param vpnSharedKey string

param onPremisesVnetConfiguration object
param onPremisesVmConfiguration object

param spoke1VnetConfiguration object
param spoke1VmConfiguration object
param spoke1StorageConfiguration object

param privateLinkVnetConfiguration object
param privateLinkVmConfiguration object
param privateLinkLoadBalancerConfiguration object

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
    firewallConfiguration: hubFirewallConfiguration
    adminPassword: adminPassword
    vmNvaConfiguration: hubNvaVmConfiguration
    vmBgpConfiguration: hubBgpVmConfiguration
  }
}

module onpremises 'base/onPremises.bicep' = {
  name: 'OnPremises-Deployment-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    vnetConfiguration: onPremisesVnetConfiguration
    subnetConfiguration: onPremisesVnetConfiguration.subnets
    adminPassword: adminPassword
    vmConfiguration: onPremisesVmConfiguration
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
    loadBalancerConfiguration: privateLinkLoadBalancerConfiguration
  }  
}

module vpnConnections 'base/connections.bicep' = {
  name: 'vpnConnections-Deploy-${timeStamp}'
  scope: resourceGroup
  params: {
    tags: tags
    virtualNetworkGateway1Id: hub.outputs.vpnGatewayId
    virtualNetworkGateway2Id: onpremises.outputs.vpnGatewayId
    sharedKey: vpnSharedKey
    virtualNetworkHubName: hubVnetConfiguration.name
    virtualNetworkSpokeName: spoke1VnetConfiguration.name
  }
}

module privateEndpoint 'base/privateEndpoint.bicep' = {
  scope: resourceGroup
  name: 'privateEndpointLinkService-Deploy-${timeStamp}'
  dependsOn: [
    spoke1
  ]
  params: {
    name: 'privateLink-app'
    privateLinkServiceId: privatelink.outputs.privateLinkServiceId
    vnetName : spoke1VnetConfiguration.name 
    subnetName: spoke1VnetConfiguration.Subnets.Backend.name
  }
} 
