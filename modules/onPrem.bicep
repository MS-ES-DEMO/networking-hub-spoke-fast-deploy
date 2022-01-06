param location string = resourceGroup().location
param tags object
param info object
@secure()
param vmOnPremAdminPassword string

var vms = info.vms
var vpnGateway = info.vpnGateway

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

// This would have to be substituted by an NVA for more complex traffic
module VMswithNICs './VM+NICs.bicep' = [for vm in vms: {
  name: vm.name
  params: {
    vmInfo: vm
    vNet: VNet
    location: location
    adminPassword: vmOnPremAdminPassword
    tags: tags
  }
}]

resource PublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: vpnGateway.publicIPName
  location: location
  tags:tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// resource VPNGateway 'Microsoft.Network/vpnGateways@2021-05-01' = {
//   name: info.vpnGatewayName
//   location: location
//   dependsOn: [
//     VNet
//   ]
// }
