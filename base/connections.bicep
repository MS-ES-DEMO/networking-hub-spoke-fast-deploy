
param tags object
param location string = resourceGroup().location
param virtualNetworkGateway1Id string
param virtualNetworkGateway2Id string

param virtualNetworkHubName string
param virtualNetworkSpokeName string

@secure()
param sharedKey string

module hubToOnpremises '../modules/Microsoft.Network/vpnConnection.bicep' = {
  name: 'hubToOnpremisesVpnConnection-Deploy'
  params: {
    name: 'hubToOnpremisesVpnConnection'
    tags: tags
    location: location
    sharedKey: sharedKey
    virtualNetworkGateway1Id: virtualNetworkGateway1Id 
    virtualNetworkGateway2Id: virtualNetworkGateway2Id
  }
}


module onPremisesToHub '../modules/Microsoft.Network/vpnConnection.bicep' = {
  name: 'onPremisesToHubVpnConnection-Deploy'
  params: {
    name: 'onPremisesToHubVpnConnection'
    tags: tags
    location: location
    sharedKey: sharedKey
    virtualNetworkGateway1Id: virtualNetworkGateway2Id 
    virtualNetworkGateway2Id: virtualNetworkGateway1Id
  }
}

resource spoke1ToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${virtualNetworkSpokeName}/spoke1ToHubPeering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Networks/virtualNetworks', virtualNetworkHubName)
    }
  }
}

resource hubToSpoke1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${virtualNetworkHubName}/hubToSpoke1Peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Networks/virtualNetworks', virtualNetworkSpokeName)
    }
  }
}
