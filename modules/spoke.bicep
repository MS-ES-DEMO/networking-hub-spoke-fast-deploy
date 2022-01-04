param location string = resourceGroup().location
param rgName string = resourceGroup().name

@description('Name and range for spoke1 services vNet')
param info object
var name = info.name

var spoke1SnetsInfo = info.subnets
var deployCustomDnsOnSpoke1Vnet = info.deployCustomDns

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
