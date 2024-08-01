<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 4c7d80af-8e49-4e45-a7f7-e877a9220fbf

.AUTHOR linkedin.com/in/lakatosgabor

#>
<#

.DESCRIPTION
Quick Start: Deploy Simple Linux VM

#>

# ┌─────────────────┐
# │Initial Variables│
# └─────────────────┘


[string]$projectName = "mslearn" + (Get-Random -Count 1 -Maximum 100)
[string]$location = Read-Host -Prompt "Enter the location (i.e. centralus)"
[string]$upn = Read-Host -Prompt "Enter your user principal name (email address) used to sign in to Azure"

[string]$secret = openssl rand -base64 32
[securestring]$secretValue = ConvertTo-SecureString -String $secret -AsPlainText -Force


# ┌──────────┐
# │Main Block│
# └──────────┘

# Create a new resource group and the key vault from ARM template
$resourceGroupName = "${projectName}rg"
$keyVaultName = $projectName
$adUserId = (Get-AzADUser -UserPrincipalName $upn).Id
$templateUri = "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/tutorials-use-key-vault/CreateKeyVault.json"

New-AzResourceGroup -Name $resourceGroupName -Location $location
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -keyVaultName $keyVaultName -adUserId $adUserId -secretValue $secretValue

# Create a new Windows VM from ARM template using the Secret stored in the Key Vault

New-AzResourceGroupDeployment `
    -TemplateFile "$PSScriptRoot\azuredeployLinux.json" `
    -TemplateParameterFile ".$PSScriptRoot\azuredeployLinux.parameters.json" `
    -dnsLabelPrefix ("vm2-" + (Get-Random -Count 1 -Maximum 9999999)) `
    -ResourceGroupName $resourceGroupName


Read-Host -Prompt "Press [ENTER] to continue ..."
