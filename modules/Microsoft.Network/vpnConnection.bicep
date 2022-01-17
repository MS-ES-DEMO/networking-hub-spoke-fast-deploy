param location string = resourceGroup().location
param tags object = {}
param name string
@secure()
param sharedKey string
param virtualNetworkGateway1Id string
param virtualNetworkGateway2Id string

param connectionType string = 'Vnet2Vnet'
param enableBgp bool = true

resource onPremisesToHub 'Microsoft.Network/connections@2021-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    connectionType: connectionType
    sharedKey: sharedKey
    enableBgp: enableBgp
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
