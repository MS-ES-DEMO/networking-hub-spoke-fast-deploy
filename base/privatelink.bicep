param tags object

param vnetConfiguration object
param subnetConfiguration object
param loadBalancerConfiguration object
param vmConfiguration object
@secure()
param adminPassword string

module vnet '../modules/Microsoft.Network/vnet.bicep' = {
  name: vnetConfiguration.name
  params: {
    tags: tags
    vnetConfiguration: vnetConfiguration
    subnetConfiguration: subnetConfiguration
  }
}

module lbPrivateLink '../modules/Microsoft.Network/loadBalancer.bicep' = {
  name: 'lbPrivateLink-Deployment'
  dependsOn: [
    vnet
  ]
  params: {
    name: loadBalancerConfiguration.name
    sku: loadBalancerConfiguration.sku
    backendAddressPools: loadBalancerConfiguration.backendAddressPools
    frontendIpConfigurations: items(loadBalancerConfiguration.frontendIpConfigurations)
    loadBalancingRules: loadBalancerConfiguration.loadBalancingRules
    probes: loadBalancerConfiguration.probes
  }
}

resource privateLink 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: 'privateLink-app'
  location: resourceGroup().location
  dependsOn: [
    vnet
    lbPrivateLink
  ]
  tags: tags
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerConfiguration.name, loadBalancerConfiguration.frontendIpConfigurations.frontendIp1.name)
      }
    ]
    ipConfigurations: [
      {
        name: 'snet-provider-default-1'
        properties: {
          primary: false
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.PrivateLinkNat.name)
          }
        }
      }
    ]
  }
}

module nicVmPrivateLink '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmConfiguration.nicName}-Deploy'
  dependsOn: [
    vnet
    lbPrivateLink
  ]
  params: {
    name: vmConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.PrivateLinkWorkload.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
    loadBalancerBackendAddressPools: [
      {
        'name': loadBalancerConfiguration.backendAddressPools[0].name
        'id': resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerConfiguration.name, loadBalancerConfiguration.backendAddressPools[0].name)
      }
    ]
  }
}

module vmPrivateLink '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmConfiguration.name}-Deploy'
  dependsOn: [
    nicVmPrivateLink
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


output privateLinkServiceId string = privateLink.id
