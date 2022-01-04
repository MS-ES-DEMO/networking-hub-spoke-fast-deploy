param location string = resourceGroup().location
param rgName string = resourceGroup().name
param info object
var name = info.name

resource VNetHub 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
}
