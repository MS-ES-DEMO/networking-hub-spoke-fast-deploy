
param location string = resourceGroup().location
param tags object
param fwPolicyInfo object 


resource fwPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: fwPolicyInfo.name
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    intrusionDetection: {
      mode: 'Alert'
    }
    snat: {
      privateRanges: fwPolicyInfo.snatRanges
    }
  }
}

