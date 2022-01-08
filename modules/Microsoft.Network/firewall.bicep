
param location string = resourceGroup().location
param tags object
param fwPolicyInfo object 
param name string
param fwPublicIpName string
param subnetId string


resource fwPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' existing = {
  name: fwPolicyInfo.name
}

resource fwPublicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' existing = {
  name: fwPublicIpName
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: name
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name:  'AZFW_VNet'
      tier: 'Premium'
    }
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: fwPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          publicIPAddress: {
            id: fwPublicIp.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
