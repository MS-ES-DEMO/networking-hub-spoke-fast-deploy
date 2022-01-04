param location string = resourceGroup().location
param rgName string = resourceGroup().name
param name string


@description('Name and range for spoke1 services vNet')
param spoke1VnetInfo object

var spoke1SnetsInfo = spoke1VnetInfo.subnets
var deployCustomDnsOnSpoke1Vnet = spoke1VnetInfo.deployCustomDns

@description('Spoke1\'s  configuration details')
param vmSpoke1 object

var vmSpoke1Name = vmSpoke1.name
var vmSpoke1Size = vmSpoke1.sku
var spoke1NicName = vmSpoke1.nicName
var vmSpoke1AdminUsername = vmSpoke1.adminUsername

@description('Admin password for Spoke1 VM')
@secure()
param vmSpoke1AdminPassword string

resource VNetSpoke1 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
}
