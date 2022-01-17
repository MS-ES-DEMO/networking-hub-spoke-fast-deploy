param tags object

param vnetConfiguration object
param subnetConfiguration object

param vmNvaConfiguration object
param vmBgpConfiguration object
@secure()
param adminPassword string

param bastionName string

param firewallConfiguration object
var firewallName = firewallConfiguration.name
var firewallPublicIpName = firewallConfiguration.ipName
var firewallPolicyInfo = firewallConfiguration.policy
var appRuleCollectionGroupName = firewallConfiguration.appCollectionRules.name
var appRulesInfo = firewallConfiguration.appCollectionRules.rulesInfo
var networkRuleCollectionGroupName = firewallConfiguration.networkCollectionRules.name
var networkRulesInfo = firewallConfiguration.networkCollectionRules.rulesInfo

param timeStamp string = utcNow()

// Networking

module vnet '../modules/Microsoft.Network/vnet.bicep' = {
  name: '${vnetConfiguration.name}-Deploy-${timeStamp}'
  params: {
    tags: tags
    vnetConfiguration: vnetConfiguration
    subnetConfiguration: subnetConfiguration
  }
}

// Azure Bastion

module bastion '../modules/Microsoft.Network/bastion.bicep' = {
  name: 'bastionResources-Deploy-${timeStamp}'
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

// Azure Firewall

module fwPolicyResources '../modules/Microsoft.Network/fwPolicy.bicep' = {
  name: 'fwPolicyResources-Deploy-${timeStamp}'
  params: {
    location: resourceGroup().location
    tags: tags
    fwPolicyInfo: firewallPolicyInfo
  }
}

module fwAppRulesResources '../modules/Microsoft.Network/fwRules.bicep' = {
  name: 'fwAppRulesResources-Deploy-${timeStamp}'
  dependsOn: [
    fwPolicyResources
  ]
  params: {
    fwPolicyName: firewallPolicyInfo.name
    ruleCollectionGroupName: appRuleCollectionGroupName
    rulesInfo: appRulesInfo
  }
}

module fwNetworkRulesResources '../modules/Microsoft.Network/fwRules.bicep' = {
  name: 'fwNetworkRulesResources-Deploy-${timeStamp}'
  dependsOn: [
    fwPolicyResources
    fwAppRulesResources
  ]
  params: {
    fwPolicyName: firewallPolicyInfo.name
    ruleCollectionGroupName: networkRuleCollectionGroupName
    rulesInfo: networkRulesInfo
  }
}

module fwPublicIpResources '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'fwPublicIpResources-Deploy-${timeStamp}'
  params: {
    location: resourceGroup().location
    tags: tags
    name: firewallPublicIpName
  }
}

module firewallResources '../modules/Microsoft.Network/firewall.bicep' = {
  name: 'firewallResources-Deploy-${timeStamp}'
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
    fwPolicyInfo: firewallPolicyInfo
    fwPublicIpName: firewallPublicIpName
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.AzureFirewall.name)
  }
}

// QUAGGA VM

module nicVmBgp '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmBgpConfiguration.nicName}-Deploy-${timeStamp}'
  dependsOn: [
    vnet
    nicVmNva
  ]
  params: {
    name: vmBgpConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.NetworkVirtualAppliances.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
  }
}

module vmBgp '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmBgpConfiguration.name}-Deploy-${timeStamp}'
  dependsOn: [
    nicVmBgp
  ]
  params: {
    adminPassword: adminPassword
    adminUsername: vmBgpConfiguration.adminUsername
    name: vmBgpConfiguration.name
    nicName: vmBgpConfiguration.nicName
    tags: tags
    vmSize: vmBgpConfiguration.sku
  }
}

module extensionBgp '../modules/Microsoft.Compute/customScriptExtension.bicep' = {
  name: 'extensionBgp-Deploy'
  dependsOn: [
    vmBgp
  ]
  params: {
    commandToExecute: 'sh quagga-config.sh'
    fileUris: [
      'https://saresourcesdeployjosef.blob.core.windows.net/resources/quagga-config.sh'
    ]
    vmName: vmBgpConfiguration.name
  }

}

// NVA VM

module nicVmNva '../modules/Microsoft.Network/nic.bicep' = {
  name: '${vmNvaConfiguration.nicName}-Deploy-${timeStamp}'
  dependsOn: [
    vnet
  ]
  params: {
    name: vmNvaConfiguration.nicName
    tags: tags
    snetName: subnetConfiguration.NetworkVirtualAppliances.name
    vnetResourceGroupName: resourceGroup().name
    vnetName: vnetConfiguration.name
  }
}

module vmNva '../modules/Microsoft.Compute/vm.bicep' = {
  name: '${vmNvaConfiguration.name}-Deploy-${timeStamp}'
  dependsOn: [
    nicVmBgp
  ]
  params: {
    adminPassword: adminPassword
    adminUsername: vmNvaConfiguration.adminUsername
    name: vmNvaConfiguration.name
    nicName: vmNvaConfiguration.nicName
    tags: tags
    vmSize: vmNvaConfiguration.sku
  }
}


// VPN

module vpnPublicIp1 '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'gw-vpn-hub-pip1-Deploy-${timeStamp}'
  params: {
    name: 'gw-vpn-hub-pip1'
    tags: tags
  }
}

module vpnPublicIp2 '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'gw-vpn-hub-pip2-Deploy-${timeStamp}'
  params: {
    name: 'gw-vpn-hub-pip2'
    tags: tags
  }
}

module vpnGateway '../modules/Microsoft.Network/vpnGateway.bicep' = {
  name: 'gw-vpn-hub-Deploy-${timeStamp}'
  dependsOn: [
    vnet
  ]
  params: {
    name: 'gw-vpn-hub'
    enableActiveActive: true
    bgpSettings: {
      'asn': 60509
    }
    ipConfiguration: [
      {
        'name': 'ipConfiguration1'
        'publicIpId': vpnPublicIp1.outputs.id
        'subnetId': resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.Gateway.name)
      }
      {
        'name': 'ipConfiguration2'
        'publicIpId': vpnPublicIp2.outputs.id
        'subnetId': resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConfiguration.name, subnetConfiguration.Gateway.name)
      }
    ]
  }
}

// Route Server

module routerServerPublicIp '../modules/Microsoft.Network/publicIp.bicep' = {
  name: 'routerServerPip-Deploy-${timeStamp}'
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
    vpnGateway
  ]
  tags: tags
  properties: {
    sku: 'Standard'
  }
}

resource routeServerIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2021-05-01' = {
  name: 'ipConfiguration'
  parent: routeServer
  dependsOn: [
    vpnGateway
  ]
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

resource routeServerConnection 'Microsoft.Network/virtualHubs/bgpConnections@2021-05-01' = {
  name: 'vm-bgphub'
  parent: routeServer
  dependsOn: [
    routeServerIpConfig
  ]
  properties: {
    peerAsn: 65001
    peerIp: nicVmBgp.outputs.privateIp
  }
}


output vpnGatewayId string = vpnGateway.outputs.id
