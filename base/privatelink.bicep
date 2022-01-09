param tags object

param vnetConfiguration object
param subnetConfiguration object

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

resource lbPrivateLink 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: 'lb-privatelink'
  tags: tags
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }  
  dependsOn: [
    vnet
  ]
  properties: {
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendId'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.PrivateLinkNat.name)
          }
        }
      }
    ]
    probes: [
      {
        name: 'HTTP-80'
        properties: {
          port: 80
          protocol: 'Tcp'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'HTTP-80'
        properties: {
          frontendPort: 80
          backendPort: 80
          protocol: 'Tcp'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'lb-privatelink', 'frontendId')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-privatelink', 'backendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb-privatelink', 'HTTP-80')
          }
        }
      }
    ]
  }
}

module nicVmPrivateLink '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmConfiguration.nicName}-Deploy'
  params: {
    name: vmConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.PrivateLinkWorkload.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
    loadBalancerBackendAddressPools: lbPrivateLink.properties.backendAddressPools
  }
}

resource privateLink 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: 'privateLink-app'
  location: resourceGroup().location
  dependsOn: [
    vnet
  ]
  tags: tags
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: lbPrivateLink.properties.frontendIPConfigurations[0].id
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
            id: lbPrivateLink.properties.frontendIPConfigurations[0].properties.subnet.id
          }
        }
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



