param location string = resourceGroup().location
param tags object = {}

param vmName string
param commandToExecute string

param typeHandlerVersion string = '2.1'
param autoUpgradeMinorVersion bool = false
param enableAutomaticUpgrade bool = false


resource customScript 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${vmName}/customScriptExtensionLinux'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: typeHandlerVersion
    autoUpgradeMinorVersion: autoUpgradeMinorVersion
    enableAutomaticUpgrade: enableAutomaticUpgrade
    protectedSettings: {
      commandToExecute: commandToExecute
    }
  }
}
