<#PSScriptInfo

.VERSION 1.0.0

.GUID 13218e06-aa8e-4807-876f-0c389ba62e22

.AUTHOR linkedin.com/in/lakatosgabor

#>
<#

.DESCRIPTION
Creates a new vnet

#>

# ┌──────────────────────────────────────────────────┐
# |Import any modules that may be used in the script |
# └──────────────────────────────────────────────────┘
try {

    [array] $module = @(

        [PSCustomObject]@{
            Name = 'verifyAzModules'
        }

        [PSCustomObject]@{
            Name = 'verifyPsModuleVersion'
        }

    )

    $modules = Get-Module

    foreach ($mod in $module) {

        if ($modules.Name -notcontains $mod.Name) {

            $modulePath = "D:\Repos\AzureEngineer\PowerShell\Modules\$($mod.Name)\$($mod.Name).psm1"
            Import-Module -Name $modulePath

        }

    }
}
catch {
    Write-Host "Error: $_"
}

function New-Vnet {

    # ┌───────────────────────────────────────┐
    # |Define Initial Parameters and Variables|
    # └───────────────────────────────────────┘


    [CmdletBinding()]
    param (

        [parameter(Mandatory = $true)]
        [string]$rg,

        [parameter(Mandatory = $true)]
        [string]$vnetName,

        [parameter(Mandatory = $true)]
        [string]$addressRanges,

        [string]$location = (Get-AzResourceGroup -Name $rg).Location

    )

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

    Write-Progress -Activity "Doing Prechecks: Verify Az modules..." -Status "$precheckCounter/2" -PercentComplete ($precheckCounter / 2 * 100) -Completed

    foreach ($AzModule in $AzModules) {

        Confirm-AzModuleVersion -Name $AzModule.Name -MinVersion $AzModule.MinVersion

    }

    
    # ┌───────────────────────┐
    # |Start the Main function|
    # └───────────────────────┘

    Write-Progress -Activity "Creating Vnet..." -Status "0/1" -PercentComplete ($mainCounter / 1 * 100) -Completed

    # Create the vnet
    New-AzVirtualNetwork -ResourceGroupName $rg -Location $location -Name $vnetName -AddressPrefix $addressRanges
    
}
Export-ModuleMember -Function New-Vnet