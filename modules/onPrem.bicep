param location string = resourceGroup().location
param tags object
param info object
@secure()
param vmAdminPassword string

var vms = info.vms
var vpnGateway = info.vpnGateway
// var localGateway = info.vpnGateway.localGateway
var ipConfig1Name = 'default'
var ipConfig2Name = 'activeActive'

resource VNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: info.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        info.range
      ]
    }
    subnets: [for subnet in info.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.range
      }
    }]
  }
}

// This would have to be substituted by a real NVA for more complex traffic
module VMswithNICs './VM+NICs.bicep' = [for vm in vms: {
  name: vm.name
  params: {
    vmInfo: vm
    vNet: VNet
    location: location
    adminPassword: vmAdminPassword
    tags: tags
  }
}]
// If using a real onPrem scenario, a Local Gateway would be configured instead of a VNet-to-VNet connection
/*
resource LocalGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: localGateway.publicIPName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource LocalGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: localGateway.name
  location: location
  tags: tags
  properties: {
    gatewayIpAddress: LocalGatewayPublicIP.properties.ipAddress
    localNetworkAddressSpace: {
      addressPrefixes: [
        localGateway.addressSpace
      ]
    }
  }
} */

resource VPNGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: vpnGateway.publicIPName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: []
}

resource VPNGatewayPublicIP2 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: vpnGateway.publicIP2Name
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: []
}

resource VPNGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: vpnGateway.name
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: ipConfig1Name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: VPNGatewayPublicIP.id
          }
          subnet: {
            id: resourceId(VNet.properties.subnets[0].type, VNet.name, vpnGateway.subnetName)
          }
        }
      }
      {
        name: ipConfig2Name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: VPNGatewayPublicIP2.id
          }
          subnet: {
            id: resourceId(VNet.properties.subnets[0].type, VNet.name, vpnGateway.subnetName)
          }
        }
      }
    ]
    activeActive: true
    enableBgp: true
  // Can't access ipConfigurationIds until they have been attached to the VPN Gateway. It works fine if run again afterwards, but not during first deployment.
  //   bgpSettings: {
  //     asn: 65510
  //     bgpPeeringAddresses: [
  //       {
  //         ipconfigurationId: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworkGateways/${vpnGateway.name}/ipConfigurations/${ipConfig1Name}' ///subscriptions/0d8f2360-c696-4129-a89c-c129419da2e9/resourceGroups/rg-network-fundamentals/providers/Microsoft.Network/virtualNetworkGateways/gw-vpn-onpremises/ipConfigurations/default
  //         customBgpIpAddresses: []
  //       }
  //       {
  //         ipconfigurationId: VPNGatewayPublicIP2.properties.ipConfiguration.id
  //         customBgpIpAddresses: []
  //       }
  //     ]
  //   }
  }
}
