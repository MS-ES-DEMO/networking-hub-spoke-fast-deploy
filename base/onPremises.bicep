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

resource vpnPublicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'gw-vpn-onpremise-pip'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: 'gw-vpn-onprem'
  location: resourceGroup().location
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfiguration'
        properties: {
          publicIPAddress: {
            id: vpnPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.GatewaySubnet.name)
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    enableBgp: true
    vpnType: 'RouteBased'
    bgpSettings: {
      asn: 60510
    }
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


output vpnGatewayId string = vpnGateway.id
