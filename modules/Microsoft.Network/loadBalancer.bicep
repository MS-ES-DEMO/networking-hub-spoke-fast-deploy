param location string = resourceGroup().location
param tags object = {}
param name string

param sku object
param backendAddressPools array 
param frontendIpConfigurations array 
param probes array 
param loadBalancingRules array 

resource lbPrivateLink 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: name
  tags: tags
  location: location
  sku: sku
  properties: {
    backendAddressPools: backendAddressPools
    frontendIPConfigurations: [for config in frontendIpConfigurations: {
      name: config.value.name
      properties: {
        privateIPAllocationMethod: config.value.allocationMethod
        subnet: {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', config.value.vnetName, config.value.subnetName)
        }
      }
    }]
    probes: [for probe in probes: {
      name: probe.name
      properties: {
        port: probe.port
        protocol: probe.protocol
      }
    }]
    loadBalancingRules: [for rule in loadBalancingRules: {
      name: rule.name
      properties: {
        frontendPort: rule.frontendPort
        backendPort: rule.backendPort
        protocol: rule.protocol
        frontendIPConfiguration: {
          id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', name, rule.frontendIPConfigurationName)
        }
        backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, rule.backendAddressPoolName)
        }
        probe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes', name, rule.probeName)
        }
      }
    }]
  }
}
