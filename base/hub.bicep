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
