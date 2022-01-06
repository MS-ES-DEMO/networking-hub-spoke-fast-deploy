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
$date = $((Get-Date -UFormat "%Y-%m-%dT%H-%M-%S_%ZZ").Replace("+",""))
$deploymentName = "$deploymentPrefix-$($date)"

az deployment sub create -l $location -n $deploymentName --template-file $templateFile --parameters $parameterFile
