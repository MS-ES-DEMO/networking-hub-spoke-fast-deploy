
param location string = resourceGroup().location
param tags object = {}
param name string

param sku object = {
  name: 'Standard'
  tier: 'Regional'
}
param zones array = []
@allowed([
  'Static'
  'Dynamic'
])
param allocationMethod string = 'Static'

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  zones: zones
  properties: {
    publicIPAllocationMethod: allocationMethod
    ipTags: []
  }
}

output id string = publicIp.id
