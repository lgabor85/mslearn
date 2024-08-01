<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 51b31118-d0c7-4f6a-9941-b724c87aeab7

.AUTHOR linkedin.com/in/lakatosgabor

#>
<#

.DESCRIPTION
Quick Start: Deploy Simple Win VM

#>

# ┌─────────────────┐
# │Initial Variables│
# └─────────────────┘

function printSecret {
    
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        $keyVaultName
        
    )

    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "vmAdminPassword"
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)

    try {

        $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    
    }
    
    finally {

        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    
    }

    Write-Output $secretValueText
    
}

function NewRg {
    
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$location
        
    )
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location
    
}

function NewKv {
    
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$keyVaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$adUserId,
        
        [Parameter(Mandatory = $true)]
        [securestring]$secretValue
        
    )
    
    $templateUri = "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/tutorials-use-key-vault/CreateKeyVault.json"
    
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -keyVaultName $keyVaultName -adUserId $adUserId -secretValue $secretValue
    
}

[string]$projectName = "mslearn" + (Get-Random -Count 1 -Maximum 100)
[string]$location = Read-Host -Prompt "Enter the location (i.e. centralus)"
[string]$upn = Read-Host -Prompt "Enter your user principal name (email address) used to sign in to Azure"

[string]$secret = openssl rand -base64 32
[securestring]$secretValue = ConvertTo-SecureString -String $secret -AsPlainText -Force


# ┌──────────┐
# │Main Block│
# └──────────┘

# Select a Resource Group or create a new one
[string]$rg = Read-Host -Prompt "Existing Resource Group Name or New Resource Group Name(e/n)?"

if ($rg -eq "e") {
    
    [string]$resourceGroupName = Read-Host -Prompt "Enter the Resource Group Name"
    
}
else {
    
    [string]$resourceGroupName = "${projectName}rg"
    NewRg -resourceGroupName $resourceGroupName `
        -location $location
    
}

# Select a Key Vault or create a new one
[string]$kv = Read-Host -Prompt "Existing Key Vault Name or New Key Vault Name(e/n)?"

if ($kv -eq "e") {
    
    [string]$keyVaultName = Read-Host -Prompt "Enter the Key Vault Name"
    
}
else {
    
    [string]$keyVaultName = "${projectName}kv"
    $adUserId = (Get-AzADUser -UserPrincipalName $upn).Id
    NewKv -resourceGroupName $resourceGroupName `
        -keyVaultName $keyVaultName`
        -adUserId $adUserId `
        -secretValue $secretValue
    
}


# Create a new Windows VM from ARM template using the Secret stored in the Key Vault
$vmName = "${projectName}vm" + (Get-Random -Count 1 -Maximum 100)

New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "$PSScriptRoot\azuredeployWinNested.json" `
    -vaultName $keyVaultName `
    -vmName $vmName


Read-Host -Prompt "Press [Enter] to print the secret"
printSecret -keyVaultName $keyVaultName