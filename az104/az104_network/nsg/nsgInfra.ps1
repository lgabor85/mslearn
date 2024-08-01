<#PSScriptInfo

.VERSION 1.0.0

.GUID e2e06e23-a84d-4245-9412-268181a88af9

.AUTHOR linkedin.com/in/lakatosgabor

#>
<#

.DESCRIPTION
MS Learn: Implement App Sec Group Module

.PARAMETER virtualMachineRG
The name of the Resource Group

.PARAMETER location
The location of the Resource Group

.PARAMETER nsgName
The name of the Network Security Group

.PARAMETER vmName
The name of the Virtual Machine

.PARAMETER adminUsername
The admin username

.PARAMETER adminPassword
The admin password for the Virtual Machine. The password will be generated and stored in a file.
The file will be created in the same directory as the script. You can find the file in the Secrets folder.

.PARAMETER templateFile
The path to the template file

#>

# ┌──────────────────────────────────────────────────┐
# |Import any modules that may be used in the script |
# └──────────────────────────────────────────────────┘

Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\verifyPsModuleVersion.psm1
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\verifyAzModules.psm1
Import-Module -Name $PSScriptRoot\..\vnet\addSubnets.psm1
Import-Module -Name $PSScriptRoot\..\vnet\newVnet.psm1


    # ┌───────────────────────────────────────┐
    # |Define Initial Parameters and Variables|
    # └───────────────────────────────────────┘
    

    [string]$virtualMachineRG = Read-Host -Prompt "Enter the name of the Resource Group"
    [string]$location = Read-Host -Prompt "Enter the location of the Resource Group"
    [string]$nsgName = Read-Host -Prompt "Enter the name of the Network Security Group"
    [string]$vmName = Read-Host -Prompt "Enter the name of the Virtual Machine"
    [string]$adminUsername = Read-Host -Prompt "Enter the admin username"
    [string]$Password = openssl rand -base64 32
    [securestring]$adminPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    [string]$templateFile = "$PSScriptRoot\Templates\simpleWinWM\simpleWinWm.bicep"


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
    Write-Progress -Activity "Creating a new Resource Group..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)

    try {

        New-AzResourceGroup -Name $virtualMachineRG -Location $location
        
    }
    catch {
        
        Write-Error -Message "Main $mainCounter - failed to create a new Resource Group. $_"
        break

    }

    
    $mainCounter++

    # Main 2: Create a new Virtual Network
    Write-Progress -Activity "Creating a new Virtual Network..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)

    try {
        
        New-Vnet

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create a new Virtual Network. $_"
        break

    }

    $mainCounter++

    $vnetName = Get-AzVirtualNetwork -ResourceGroupName $virtualMachineRG | Select-Object -ExpandProperty Name

    # Main 3: Add subnets to the vnet
    Write-Progress -Activity "Adding subnets to the Virtual Network..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)
    
    try {

        Add-Subnets
    
    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to add subnets to the Virtual Network. $_"
        break

    }

    $mainCounter++

    # List the subnets
    Get-AzVirtualNetwork -ResourceGroupName $virtualMachineRG | Select-Object -ExpandProperty Subnets | Select-Object -Property Name | Format-Table

    # Chose a subnet
    [string]$subnetName = Read-Host -Prompt "Enter the name of the subnet"

    # Main 4: Create a new Network Security Group
    Write-Progress -Activity "Creating a new Network Security Group..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)

    try {

        New-AzNetworkSecurityGroup -ResourceGroupName $virtualMachineRG -Name $nsgName -Location $location

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create a new Network Security Group. $_"
        break

    }

    $mainCounter++

    # Main 5: Deploy VMs from a template
    Write-Progress -Activity "Deploying VMs from a template..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)



    try {

        New-AzResourceGroupDeployment -ResourceGroupName $virtualMachineRG `
        -location $location `
        -vmName $vmName `
        -vnetNAme $vnetName `
        -subnetName $subnetName `
        -adminUsername $adminUsername `
        -adminPassword $adminPassword `
        -TemplateFile $templateFile

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to deploy VMs from a template. $_"
        break

    }

    $mainCounter++


    # Main 6: Associate the NSG with the NIC
    Write-Progress -Activity "Associating the NSG with the NIC..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)

    try {

        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $virtualMachineRG -Name $nsgName
        $nicName = Get-AzNetworkInterface -ResourceGroupName $virtualMachineRG | Select-Object -ExpandProperty Name
        $nic = Get-AzNetworkInterface -ResourceGroupName $virtualMachineRG -Name $nicName
        $nic.NetworkSecurityGroup = $nsg
        $nic | Set-AzNetworkInterface

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to associate the NSG with the NIC. $_"
        break

    }

    $mainCounter++

    # Main 7: Create new inbound port rule to allow RDP
    Write-Progress -Activity "Creating new inbound port rule to allow RDP..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)

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

    # Main 8: Create new outbound port rule to deny internet access

    # Note: When you make a change to the existing NSG rule to block the traffic, the flows which are active will still be running and will not be terminated. Any new flow will hit that rule and that gets blocked. Also, when you make changes, give it a 30 seconds for the system to populate the change all the way in the stack to get it working.
    # Source: https://learn.microsoft.com/en-us/answers/questions/607799/nsg-rule-time-to-be-effective

    Write-Progress -Activity "Creating new outbound port rule to deny internet access..." -Status "$mainCounter/8" -PercentComplete ($mainCounter / 8 * 100)
    
    try {

        $nsg | Add-AzNetworkSecurityRuleConfig -Name "Deny-Internet" `
        -Description "Deny Internet" `
        -Access Deny `
        -Protocol Tcp `
        -Direction Outbound `
        -Priority 4000 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix Internet `
        -DestinationPortRange * `
        | Set-AzNetworkSecurityGroup

    }
    catch {

        Write-Error -Message "Main $mainCounter - failed to create new outbound port rule to deny internet access. $_"
        break

    }


    # Final progress
    Write-Progress -Activity "All $mainCounter tasks completed" -Status "$mainCounter/8" -PercentComplete 100 -Completed

    # Write the password to a file
    $Password | Out-File -FilePath "$PSScriptRoot\Secrets\password.txt" -Force