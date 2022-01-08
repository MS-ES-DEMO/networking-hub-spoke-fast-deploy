
param location string = resourceGroup().location
param tags object
param name string 
param snetName string
param vnetName string
param vnetResourceGroupName string

param loadBalancerBackendAddressPools array = []


resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: snetName
  parent: vnet
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: empty(loadBalancerBackendAddressPools) ? [] : loadBalancerBackendAddressPools
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

