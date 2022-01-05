param (
  [string]
  $location = "westeurope",
  [string] 
  $templateFile = ".\main.bicep",
  [string]
  $parameterFile = "parameters.json",
  [string] 
  $deploymentPrefix='Network-Fundamentals'
  )

$deploymentName = "$deploymentPrefix-$(New-Guid)"

az deployment sub create -l $location -n $deploymentName --template-file $templateFile --parameters $parameterFile
