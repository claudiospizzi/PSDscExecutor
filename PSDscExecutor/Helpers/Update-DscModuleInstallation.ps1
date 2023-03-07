<#
    .SYNOPSIS
        Helper function to ensure, the required module is installed.
#>
function Update-DscModuleInstallation
{
    [CmdletBinding()]
    param
    (
        # The remoting session to use.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session = $null,

        # Name of the module.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        # Version of the module.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        # Option to import the installed module.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Import
    )

    try
    {
        Write-Verbose "[PSDscExecutor] DSC Module Dependency: Verify Package Provider NuGet 2.8.5.201"

        $packageProviderNuGet = Invoke-ScriptBlock -Session $Session -ScriptBlock {
            Get-PackageProvider -Name 'NuGet' -ErrorAction 'SilentlyContinue'
        }

        if ($null -eq $packageProviderNuGet -or $packageProviderNuGet.Version -lt '2.8.5.201')
        {
            Write-Verbose "[PSDscExecutor] DSC Module Dependency: Install Package Provider NuGet 2.8.5.201"

            Invoke-ScriptBlock -Session $Session -ScriptBlock {
                Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Force -Verbose:$false | Out-Null
            }
        }

        Write-Verbose "[PSDscExecutor] DSC Module Dependency: Verify Module $ModuleName $ModuleVersion"

        $module = Invoke-ScriptBlock -Session $Session -ArgumentList $ModuleName, $ModuleVersion -ScriptBlock {
            param ($ModuleName, $ModuleVersion)
            Get-Module -FullyQualifiedName @{ ModuleName = $ModuleName; ModuleVersion = $ModuleVersion } -ListAvailable -Verbose:$false |
                Where-Object { $_.ModuleBase -like 'C:\Program Files\*' }
        }

        if ($null -eq $module)
        {
            Write-Verbose "[PSDscExecutor] DSC Module Dependency: Install Module $ModuleName $ModuleVersion"

            Invoke-ScriptBlock -Session $Session -ArgumentList $ModuleName, $ModuleVersion -ScriptBlock {
                param ($ModuleName, $ModuleVersion)
                Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope 'AllUsers' -AllowClobber -SkipPublisherCheck -Force -Verbose:$false #-AcceptLicense
            }
        }

        if ($Import.IsPresent)
        {
            Write-Verbose "[PSDscExecutor] DSC Module Dependency: Import Module $ModuleName $ModuleVersion"

            Invoke-ScriptBlock -Session $Session -ArgumentList $ModuleName, $ModuleVersion -ScriptBlock {
                param ($ModuleName, $ModuleVersion)
                Import-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Global -Force -Verbose:$false
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}






# foreach ($moduleInfo in $moduleInfos)
# {
#     Write-Verbose "[PSDscExecutor] DSC Module Dependency: Install and Import Module $ModuleName $ModuleVersion"

#     $installAndImportModuleScriptBlock = {
#         param ($Name, $Version)

#         $module = Get-Module -FullyQualifiedName @{ ModuleName = $Name; ModuleVersion = $Version } -ListAvailable -Verbose:$false | Where-Object { $_.ModuleBase -like 'C:\Program Files\*' }

#         if ($null -eq $module)
#         {
#             Install-Module -Name $Name -RequiredVersion $Version -Scope 'AllUsers' -AllowClobber -SkipPublisherCheck -Force -Verbose:$false #-AcceptLicense
#         }

#         Import-Module -Name $Name -RequiredVersion $Version -Global -Force -Verbose:$false
#     }

#     if ($null -eq $session)
#     {
#         $installAndImportModuleScriptBlock.Invoke($moduleInfo.Name, $moduleInfo.Version)
#     }
#     else
#     {
#         Invoke-Command -Session $session -ScriptBlock $installAndImportModuleScriptBlock -ArgumentList $moduleInfo.Name, $moduleInfo.Version
#     }
# }