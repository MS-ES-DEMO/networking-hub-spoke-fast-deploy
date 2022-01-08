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
  name: 'gw-vpn-onpremises'
  location: resourceGroup().location
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
