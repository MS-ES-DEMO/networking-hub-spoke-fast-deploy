param tags object
 
param vnetConfiguration object
param subnetConfiguration object

param bastionName string

@description('Azure Firewall configuration parameters')
param firewallConfiguration object

var fwPublicIpName = firewallConfiguration.ipName
var firewallName = firewallConfiguration.name

var fwPolicyInfo = firewallConfiguration.policy
var appRuleCollectionGroupName = firewallConfiguration.appCollectionRules.name
var appRulesInfo = firewallConfiguration.appCollectionRules.rulesInfo

var networkRuleCollectionGroupName = firewallConfiguration.networkCollectionRules.name
var networkRulesInfo = firewallConfiguration.networkCollectionRules.rulesInfo

param vmConfiguration object
@secure()
param adminPassword string

module vnet '../modules/Microsoft.Network/vnet.bicep' = {
  name: vnetConfiguration.name
  params: {
    tags: tags
    vnetConfiguration: vnetConfiguration
    subnetConfiguration: subnetConfiguration
  }
}


module bastion '../modules/Microsoft.Network/bastion.bicep' = {
  name: 'bastionResources_Deploy'
  dependsOn: [
    vnet
  ]
  params: {
    name: bastionName
    tags: tags
    vnetName: vnetConfiguration.name
    vnetResourceGroupName: resourceGroup().name
    location: resourceGroup().location
  }
}


module fwPolicyResources '../modules/Microsoft.Network/fwPolicy.bicep' = {
  name: 'fwPolicyResources_Deploy'
  params: {
    location: resourceGroup().location
    tags: tags
    fwPolicyInfo: fwPolicyInfo
  }
}

module fwAppRulesResources '../modules/Microsoft.Network/fwRules.bicep' = {
  name: 'fwAppRulesResources_Deploy'
  dependsOn: [
    fwPolicyResources
  ]
  params: {
    fwPolicyName: fwPolicyInfo.name
    ruleCollectionGroupName: appRuleCollectionGroupName
    rulesInfo: appRulesInfo
  }
}

module fwNetworkRulesResources '../modules/Microsoft.Network/fwRules.bicep' = {
  name: 'fwNetworkRulesResources_Deploy'
  dependsOn: [
    fwPolicyResources
    fwAppRulesResources
  ]
  params: {
    fwPolicyName: fwPolicyInfo.name
    ruleCollectionGroupName: networkRuleCollectionGroupName
    rulesInfo: networkRulesInfo
  }
}

module fwPublicIpResources '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'fwPublicIpResources_Deploy'
  params: {
    location: resourceGroup().location
    tags: tags
    name: fwPublicIpName
  }

}

module firewallResources '../modules/Microsoft.Network/firewall.bicep' = {
  name: 'firewallResources_Deploy'
  dependsOn: [
    fwPublicIpResources
    fwPolicyResources
    fwAppRulesResources
    fwNetworkRulesResources
    vnet
  ]
  params: {
    location: resourceGroup().location
    tags: tags
    name: firewallName
    fwPolicyInfo: fwPolicyInfo
    fwPublicIpName: fwPublicIpName
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.AzureFirewall.name)
  }
}




module nicVmNva '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmConfiguration.nicName}-Deploy'
  params: {
    name: vmConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.NetworkVirtualAppliances.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
  }
}

module vmNva '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmConfiguration.name}-Deploy'
  dependsOn: [
    nicVmNva
  ]
  params: {
    adminPassword: adminPassword
    adminUsername: vmConfiguration.adminUsername
    name: vmConfiguration.name
    nicName: vmConfiguration.nicName
    tags: tags
    vmSize: vmConfiguration.sku
  }
}


resource vpnPublicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'gw-vpn-hub-pip'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: 'gw-vpn-hub'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfiguration'
        properties: {
          publicIPAddress: {
            id: vpnPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.Gateway.name)
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    enableBgp: true
    vpnType: 'RouteBased'
    bgpSettings: {
      asn: 60511
    }
  }
}

module routerServerPublicIp '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'routerServerPip-Deploy'
  params: {
    name: 'routeServerPip'
    tags: tags
  }
}

resource routeServer 'Microsoft.Network/virtualHubs@2021-05-01' = {
  name: 'routeServer'
  location: resourceGroup().location
  dependsOn: [
    vnet
  ]
  tags: tags
  properties: {
    sku: 'Standard'
  }
  
}

resource routeServerIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2021-05-01' = {
  name: 'ipConfiguration'
  parent: routeServer
  properties: {
    privateIPAllocationMethod: 'Dynamic'
    publicIPAddress: {
      id: resourceId('Microsoft.Network/publicIpAddresses', 'routeServerPip')
    }
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.RouteServer.name)
    }
  }
}

resource routeServerBgpConnection 'Microsoft.Network/virtualHubs/bgpConnections@2021-05-01' = {
  name: 'bgpConfiguration'
  parent: routeServer
  properties: {
    peerAsn: 60505
  }
}
