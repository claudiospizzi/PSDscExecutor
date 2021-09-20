<#
    .SYNOPSIS
        Import all DSC resources into the current PowerShell sessions.

    .DESCRIPTION
        Use this command to import all DSC resources found in the modules
        installed in the module path into the current PowerShell session.
        Already imported modules are skipped. Use the force parameter to reset
        the DSC resource cache and re-import all resource from scratch.

    .EXAMPLE
        PS C:\> Update-DscResourceCache -ModuleInfo $moduleInfo
        Import all DSC resources in the specified modules into the cache.

    .EXAMPLE
        PS C:\> Update-DscResourceCache -Clear
        Reset the DSC resource cache and then re-import all DSC resources.

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Update-DscResourceCache
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [PSTypeName('PSDscExecutor.ModuleInfo')]
        [System.Object[]]
        $ModuleInfo,

        # Reset the DSC resource cache and re-import all resource from scratch.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Clear
    )

    try
    {
        # Clear the DSC resource cache and the PSDscExecutor resource cache
        # list to enable re-importing all DSC resources.
        if ($Clear.IsPresent)
        {
            Write-Verbose 'DSC Resource Cache: Clear and Reset'

            $Script:DscResourceCache.Clear()

            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache()
            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords()
        }

        if ($PSBoundParameters.ContainsKey('ModuleInfo'))
        {
            $modules = @()
            foreach ($module in $ModuleInfo)
            {
                $modules += Get-Module -FullyQualifiedName @{ ModuleName = $module.Name; ModuleVersion = $module.Version } -ListAvailable -Verbose:$false
            }
        }
        else
        {
            $modules = Get-Module -ListAvailable -Verbose:$false
        }

        foreach ($module in $modules)
        {
            $moduleId = '{0} {1}' -f $module.Name, $module.Version

            # Only import the module into the DSC resource cache, if it's not
            # already imported.
            if (-not $Script:DscResourceCache.Contains($moduleId))
            {
                Write-Verbose "DSC Resource Cache: Add Module $moduleId"

                try
                {
                    # Improt the script and binary DSC resources
                    $refImportedSchemaFile = $null
                    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($module, $null, [ref] $refImportedSchemaFile) | Out-Null
                }
                catch
                {
                    Write-Warning $_
                }

                try
                {
                    # Improt the class-based DSC resources
                    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClassResourcesFromModule($module, $module.ExportedDscResources, $null) | Out-Null
                }
                catch
                {
                    Write-Warning $_
                }

                $Script:DscResourceCache.Add($moduleId) | Out-Null
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
