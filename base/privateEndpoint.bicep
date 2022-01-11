param location string = resourceGroup().location
param tags object = {}

param name string
param privateLinkServiceId string
param subnetName string
param vnetName string


resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: privateLinkServiceId
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
  }
}
