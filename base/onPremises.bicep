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

module vpnPublicIp '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'gw-vpn-onpremise-pip-Deploy'
  params: {
    location: resourceGroup().location
    tags: tags
    name: 'gw-vpn-onpremise-pip'
    allocationMethod: 'Dynamic'
    sku: {
      name: 'Basic'
      tier: 'Regional'
    }
  }
}

module vpnGateway '../modules/Microsoft.Network/vpnGateway.bicep' = {
  name: 'gw-vpn-onprem-Deploy'
  params: {
    ipConfiguration: [
      {
        'name': 'ipConfiguration1'
        'publicIpId': vpnPublicIp.outputs.id
        'subnetId': resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.GatewaySubnet.name)
      }
    ]
    name: 'gw-vpn-onprem'
    location: resourceGroup().location
    vpnType: 'RouteBased'
  }
}

module nicVmOnpremises '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmConfiguration.nicName}-Deploy'
  dependsOn: [
    vnet
  ]
  params: {
    name: vmConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.NetworkVirtualAppliances.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
  }
}

module vmOnpremises '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmConfiguration.name}-Deploy'
  dependsOn: [
    nicVmOnpremises
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

output vpnGatewayId string = vpnGateway.outputs.id
