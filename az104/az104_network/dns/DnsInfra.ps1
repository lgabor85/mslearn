<#PSScriptInfo

.VERSION 1.0.0

.GUID 9aa833b7-f07a-4afb-b496-8697b1b2ade0

.AUTHOR linkedin.com/in/lakatosgabor

#>
<#

.DESCRIPTION
MS Learn: Configure Azure DNS

#>

# ┌─────────────────────────────────────────────────────────┐
# |Import any custom modules that may be used in the script |
# └─────────────────────────────────────────────────────────┘

try {

    [array] $psModule = @(

        [PSCustomObject] @{ Name = 'verifyAzModules' }
        [PSCustomObject] @{ Name = 'verifyPsModuleVersion' }

    )

    [array] $auxModule = @(

        [PSCustomObject] @{ Name = 'newVnet' }
        [PSCustomObject] @{ Name = 'addSubnets' }

    )



    $modules = Get-Module

    foreach ($mod in $psModule) {

        if ($modules.Name -notcontains $mod.Name) {

            $modulePath = "D:\Repos\AzureEngineer\PowerShell\Modules\$($mod.Name)\$($mod.Name).psm1"
            Import-Module -Name $modulePath

        }

    }

    foreach ($mod in $auxModule) {

        if ($modules.Name -notcontains $mod.Name) {

            $modulePath = "D:\Repos\AzureEngineer\PowerShell\Scripts\az104\az104_network\vnet\$($mod.Name)\$($mod.Name).psm1"
            Import-Module -Name $modulePath

        }

    }
}

catch {

    Write-Host "Error: $_"

}

# ┌────────────────┐
# |Define Functions|
# └────────────────┘

function New-Vault {

    param (

        [Parameter(Mandatory = $true)]
        [string]$rg,
        [Parameter(Mandatory = $true)]
        [string]$location,
        [Parameter(Mandatory = $true)]
        [string]$upn,
        [Parameter(Mandatory = $true)]
        [securestring]$adminPassword

    )

    $keyVaultName = "${rg}kv"
    $adUserId = (Get-AzADUser -UserPrincipalName $upn).Id
    $templateUri = "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/tutorials-use-key-vault/CreateKeyVault.json"

    New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateUri $templateUri -keyVaultName $keyVaultName -adUserId $adUserId -secretValue $adminPassword -EnabledForTemplateDeployment

}

    # ┌───────────────────────────────────────┐
    # |Define Initial Parameters and Variables|
    # └───────────────────────────────────────┘
    

    [string]$rg = Read-Host -Prompt "Enter the name of the Resource Group"
    [string]$location = Read-Host -Prompt "Enter the location of the Resource Group"
        
    [string]$vm1Name = Read-Host -Prompt "Enter the name of the Virtual Machine 1"
    [string]$vm2Name = Read-Host -Prompt "Enter the name of the Virtual Machine 2"
    
    [string]$vnetName = Read-Host -Prompt "Enter the name of the Virtual Network"
    [string]$addressRanges = Read-Host -Prompt "Enter the address ranges for the Virtual Network"
    [string]$nsgName = Read-Host -Prompt "Enter the name of the Network Security Group"

    [string]$upn = Read-Host -Prompt "Enter your user principal name (email address) used to sign in to Azure"
    [string]$adminUsername = Read-Host -Prompt "Enter the admin username"
    [string]$Password = openssl rand -base64 32
    [securestring]$adminPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    [string]$templateFile = "$PSScriptRoot\Templates\simpleWinWM\simpleWinWm.bicep"

    # Ask the user how many subnets they want to create
    # Create an empty hashtable to store the subnet names and ranges
    # Loop to get the subnet names and ranges and store them in the hashtable

    [int]$subnetCount = Read-Host -Prompt "Enter the number of subnets you want to create"

    [hashtable]$subnets = @{}

    for ($i = 1; $i -le $subnetCount; $i++) {

        [string]$subnetName = Read-Host -Prompt "Enter the name of subnet $i"
        [string]$subnetRange = Read-Host -Prompt "Enter the range of subnet $i"
    
        $subnets[$subnetName] = $subnetRange
    }
    

        # Counter(s) to display progress
        $precheckCounter = 1
        $mainCounter = 1

        # Get-Command 'Some-Command' | Select-Object ModuleName
        # Get-Module -Name 'Some-Module' | Select-Object Name, Version

        # Powershell module(s) needed for this script. 
        [array] $PSModules = @(
    
            [pscustomobject]@{ Name = "PowerShellGet"; MinVersion = "2.2.5" }
            [pscustomobject]@{ Name = "Az.Tools.Installer"; MinVersion = "1.0.0" }
    
        )
    
        # Define Azure PowerShell module(s) needed for this script.
        [array] $AzModules = @(
    
            [pscustomobject]@{ Name = "Az.Network"; MinVersion = "7.4.0" }
            [pscustomobject]@{ Name = "Az.Resources"; MinVersion = "6.15.1" }
    
        )
    
    # ┌──────────────────────────────────────┐
    # |Perform pre-requisite checks as needed|
    # └──────────────────────────────────────┘

    # Precheck 1: Verify that the minimum required version of the PowerShell module is installed

    Write-Progress -Activity "Doing Prechecks: Verify PS modules.." -Status "$precheckCounter/2" -PercentComplete ($precheckCounter / 2 * 100)

    foreach ($PSModule in $PSModules) {

        Confirm-PSModuleVersion -Name $PSModule.Name -MinVersion $PSModule.MinVersion

    }

    $precheckCounter++

    # Precheck 2: Verify that the minimum required version of the Azure PowerShell module is installed

    Write-Progress -Activity "Doing Prechecks: Verify Az modules..." -Status "$precheckCounter/2" -PercentComplete ($precheckCounter / 2 * 100)

    foreach ($AzModule in $AzModules) {

        Confirm-AzModuleVersion -Name $AzModule.Name -MinVersion $AzModule.MinVersion

    }

    $precheckCounter++
    
    # ┌───────────────────────┐
    # |Start the Main function|
    # └───────────────────────┘

    # Main 1: Create a new Resource Group
    Write-Progress -Activity "Creating a new Resource Group..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        New-AzResourceGroup -Name $rg -Location $location
        
    }
    catch {
        
        Write-Error -Message "Main $mainCounter - failed to create a new Resource Group. $_"
        break

    }

    
    $mainCounter++

    # Main 2: Create a new Virtual Network
    Write-Progress -Activity "Creating a new Virtual Network..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {
        
        New-Vnet -rg $rg -location $location -vnetName $vnetName -addressRanges $addressRanges

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create a new Virtual Network. $_"
        break

    }

    $mainCounter++

    $vnetName = Get-AzVirtualNetwork -ResourceGroupName $rg | Select-Object -ExpandProperty Name

    # Main 3: Add subnets to the vnet
    Write-Progress -Activity "Adding subnets to the Virtual Network..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)
    
    try {

        Add-Subnets -rg $rg -vnetName $vnetName -subnets $subnets
    
    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to add subnets to the Virtual Network. $_"
        break

    }

    $mainCounter++

    # List the subnets
    Get-AzVirtualNetwork -ResourceGroupName $rg | Select-Object -ExpandProperty Subnets | Select-Object -Property Name | Format-Table

    # Chose a subnet
    [string]$subnetName = Read-Host -Prompt "Enter the name of the subnet"

    # Main 4: Create a new Network Security Group
    Write-Progress -Activity "Creating a new Network Security Group..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        New-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName -Location $location

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create a new Network Security Group. $_"
        break

    }

    $mainCounter++

    # Main 5: Create Azure Key Vault
    Write-Progress -Activity "Creating Azure Key Vault..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        New-Vault -rg $rg -location $location -upn $upn -adminPassword $adminPassword

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create Azure Key Vault. $_"
        break

    }

    $keyVault = Get-AzKeyVault -ResourceGroupName $rg | Select-Object -Property ResourceId
    $keyVaultId = $keyVault.ResourceId

    $mainCounter++

    # Main 6: Deploy VM1 from a template
    Write-Progress -Activity "Deploying VMs from a template..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)



    try {

        New-AzResourceGroupDeployment -ResourceGroupName $rg `
        -location $location `
        -vmName $vm1Name `
        -vnetNAme $vnetName `
        -subnetName $subnetName `
        -adminUsername $adminUsername `
        -TemplateFile $templateFile `
        -keyVaultId $keyVaultId

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to deploy VMs from a template. $_"
        break

    }

    $mainCounter++

    # Main 7: Create VM2 from a template
    Write-Progress -Activity "Deploying VMs from a template..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        New-AzResourceGroupDeployment -ResourceGroupName $rg `
        -location $location `
        -vmName $vm2Name `
        -vnetNAme $vnetName `
        -subnetName $subnetName `
        -adminUsername $adminUsername `
        -adminPassword $adminPassword `
        -TemplateFile $templateFile `
        -keyVaultId $keyVaultId

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to deploy VMs from a template. $_"
        break

    }

    # Main 8: Associate the NSG with the NIC from VM1
    Write-Progress -Activity "Associating the NSG with the NIC..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName
        
        Get-AzNetworkInterface -ResourceGroupName $rg | Select-Object -ExpandProperty Name | Format-Table

        $nicName = Read-Host -Prompt "Pick a NIC from the list above"
        
        $nic = Get-AzNetworkInterface -ResourceGroupName $rg -Name $nicName
        $nic.NetworkSecurityGroup = $nsg
        $nic | Set-AzNetworkInterface

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to associate the $($nsg.name) with $nicName. $_"
        break

    }

    $mainCounter++

    # Main 9: Associate the NSG with the NIC from VM2
    Write-Progress -Activity "Associating the NSG with the NIC..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName
        
        Get-AzNetworkInterface -ResourceGroupName $rg | Select-Object -ExpandProperty Name | Format-Table

        $nicName = Read-Host -Prompt "Pick a NIC from the list above"
        
        $nic = Get-AzNetworkInterface -ResourceGroupName $rg -Name $nicName
        $nic.NetworkSecurityGroup = $nsg
        $nic | Set-AzNetworkInterface

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to associate the $($nsg.name) with $nicName. $_"
        break

    }

    # Main 10: Create new inbound port rule to allow RDP
    Write-Progress -Activity "Creating new inbound port rule to allow RDP..." -Status "$mainCounter/10" -PercentComplete ($mainCounter / 10 * 100)

    try {

        $nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP" `
        -Description "Allow RDP" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 300 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange 3389 `
        | Set-AzNetworkSecurityGroup

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create new inbound port rule to allow RDP. $_"
        break

    }

    $mainCounter++


    # Final progress
    Write-Progress -Activity "All $mainCounter tasks completed" -Status "$mainCounter/10" -PercentComplete 100 -Completed

    # Write the password to a file
    $Password | Out-File -FilePath "$PSScriptRoot\Secrets\password.txt" -Force