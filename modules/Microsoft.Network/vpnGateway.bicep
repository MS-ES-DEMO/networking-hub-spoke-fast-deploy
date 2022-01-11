param location string = resourceGroup().location
param name string
@description('Configuration of the public IPs associated with the VPN Gateway.')
@metadata({
  'format': '[ { name: string, publicIpId: resourceId, subnetId: resourceId}]'
  'restrictions': 'It should contain at least one element. If active-active configuration is enabled it should contain two.'
})
@minLength(1)
@maxLength(2)
param ipConfiguration array
param sku object = {
  name: 'VpnGw1'
  tier: 'VpnGw1'
}
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'
param enableBgp bool = true
param enableActiveActive bool = false

param bgpSettings object = {
  asn: 60510
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [for ipConfig in ipConfiguration: {
      name: ipConfig.name
      properties: {
        publicIPAddress: {
          id: ipConfig.publicIpId
        }
        subnet: {
          id: ipConfig.subnetId
        }
      }
    }]
    sku: sku
    enableBgp: enableBgp
    activeActive: enableActiveActive
    vpnType: vpnType
    bgpSettings: bgpSettings
  }
}

output id string = vpnGateway.id
