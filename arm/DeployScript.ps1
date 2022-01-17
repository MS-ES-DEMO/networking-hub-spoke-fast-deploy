$rgName = "networking-fundamentals-rg"
$location = "westeurope"

New-AzResourceGroup -Name $rgName -Location $location

$deploymentName = "NetworkingFundamentals-$($((Get-Date -UFormat "%Y-%m-%dT%H-%M-%S_%ZZ").Replace("+", '')))"
$file = ".\template.json"
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -Location $location `
    -TemplateFile $file `
    -TemplateParameterFile .\parameters.json `
    -Name $deploymentName `
    -Verbose

$gwHub = Get-AzVirtualNetworkGateway -Name gw-vpn-hub -ResourceGroupName $rgName
$gwOnPrem = Get-AzVirtualNetworkGateway -Name gw-vpn-onpremises -ResourceGroupName $rgName

$sharedGWSecret = 'abcd1234'
New-AzVirtualNetworkGatewayConnection -Name hub-to-onprem -ResourceGroupName $rgName `
    -VirtualNetworkGateway1 $gwHub -VirtualNetworkGateway2 $gwOnPrem -Location $location `
    -ConnectionType Vnet2Vnet -SharedKey $sharedGWSecret

New-AzVirtualNetworkGatewayConnection -Name onprem-to-hub -ResourceGroupName $rgName `
    -VirtualNetworkGateway1 $gwOnPrem -VirtualNetworkGateway2 $gwHub -Location $location `
    -ConnectionType Vnet2Vnet -SharedKey $sharedGWSecret

$deploymentName = "PostDeploymentOps-$($((Get-Date -UFormat "%Y-%m-%dT%H-%M-%S_%ZZ").Replace("+", '')))"
$file = ".\post-deployment-ops.json"
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -Location $location `
    -TemplateFile $file `
    -Name $deploymentName `
    -Verbose

<#
(Only if the existing VM setup scripts fail)
Set-AzVMRunCommand -ResourceGroupName $rgname -VMName 'vm-nva-hub' -RunCommandName 'initialsetup' -SourceScript 'sudo apt update;sudo sysctl -w net.ipv4.ip_forward=1; sudo iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -j MASQUERADE;sudo apt install ubuntu-desktop -y;sudo apt install xrdp -y;sudo adduser xrdp ssl-cert;sudo systemctl restart xrdp' -NoWait

az vm run-command create -g $rgName --name "initialsetup" --vm-name 'vm-privatelink' --script 'sudo apt update;sudo apt install apache2 -y' --no-wait

Tests:
ssh azureAdmin@vm-onprem-IP
ssh 10.0.2.4 #<- Should go to vm-spoke1
^D
ssh 10.0.0.4 #<- Should go to vm-nva-hub
^D

curl -G https://<storage-account-name>.blob.core.windows.net/logs?restype=container&comp=list #<- Should return the list of containers if launched from vm-spoke1 or a permission denial if from vm-nva-hub or on-prem

telnet 10.0.2.37 80 #<- Sould establish connection
---
Connect via Bastion to vm-nva-hub and open a browser. Google should be blocked, all other websites, allowed

#>