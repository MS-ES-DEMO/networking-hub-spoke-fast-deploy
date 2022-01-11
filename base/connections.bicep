
param tags object
param location string = resourceGroup().location
param virtualNetworkGateway1Id string
param virtualNetworkGateway2Id string

@secure()
param sharedKey string

resource hubToOnpremises 'Microsoft.Network/connections@2021-05-01' = {
  name: 'hubToOnpremisesVpnConnection'
  location: location
  tags: tags
  properties: {
    connectionType: 'Vnet2Vnet'
    sharedKey: sharedKey
    enableBgp: true
    virtualNetworkGateway1: {
      id: virtualNetworkGateway1Id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: virtualNetworkGateway2Id
      properties: {}
    }
  }
}

resource onPremisesToHub 'Microsoft.Network/connections@2021-05-01' = {
  name: 'onPremisesToHubVpnConnection'
  location: location
  tags: tags
  properties: {
    connectionType: 'Vnet2Vnet'
    sharedKey: sharedKey
    enableBgp: true
    virtualNetworkGateway1: {
      id: virtualNetworkGateway2Id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: virtualNetworkGateway1Id
      properties: {}
    }
  }
}

