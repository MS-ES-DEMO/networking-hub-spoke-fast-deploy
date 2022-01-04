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

$deploymentName = $deploymentPrefix


New-AzDeployment -Name $deploymentName `
                -Location $location `
                -TemplateFile $templateFile `
                -TemplateParameterFile $parameterFile `
                -Verbose

