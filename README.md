# Hub-spoke network topology - Fast Deploy

This repository contains an Azure Bicep template to simplify the deployment of a Hub and Spoke network architecture with fundamental network services in a test or demo environment.

The following diagram shows a detailed architecture of the logical and network topology of the resources created by this template. Relevant resources for the specific scenario covered in this repository are deployed into the following resource group:

- **rg-network-fundamentals**: network configuration for provisioning all the required services for the different usage scenarios.

![Logical architecture](/doc/images/logical-network-diagram.png)

## Repository structure

This repository is organized in the following folders:

- **doc**: contains documents and images related to this scenario.
- **modules**: Bicep modules that integrates the different resources used by the base scripts.

## Prerequisites

Bicep is the language used for defining declaratively the Azure resources required in this template. You would need to configure your development environment with Bicep support to successfully deploy this scenario.

- [Installing Bicep with Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Installing Bicep with Azure PowerShell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-powershell)

As alternative, you can use [Azure Shell with PowerShell](https://ms.portal.azure.com/#cloudshell/) that already includes support for Bicep.

After validating Bicep installation, you would need to configure the Azure subscription where the resources would be deployed. You need to make sure that you have at least enough quota for creating the required sessions hosts instances you define in the parameters file.

## How to deploy

1. Customize the required parameters in parameters.json described in the Parameters section .
2. Add extra customizations if wanted to adapt their values to your specific environment.
3. Execute deploy.PowerShell.ps1 or deploy.CLI.ps1 script based on the current command line Azure tools available in your computer with the correct parameter file.
4. Wait around 50 minutes.
5. Enjoy.

## Parameters

*The default parameter file contains all the possible options available in this environment. We recommend to adjust only the values of the parameters described here.*

- *location*
  - "type": "string",
  - "description": "Allows to configure the Azure region where the resources should be deployed."

- *resourceGroupNames*
  - "type": "string",
  - "description": "Allows to configure the specific resource group where the resources associated to that service would be deployed. You can define the same resource group name for all resources in a test environment to simplify management and deletion after finishing with the evaluation."
