<#
    .SYNOPSIS
        Invoke the DSC method on the local or remote system.
#>
function Invoke-DesiredStateResource
{
    [CmdletBinding()]
    param
    (
        # The remoting session to use.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        # The DSC method to invoke.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Set', 'Test')]
        [System.String]
        $Method,

        # The DSC resource itself.
        [Parameter(Mandatory = $true)]
        [PSTypeName('PSDscExecutor.Configuration.Resource')]
        $Resource
    )

    try
    {
        $resourceSplat = @{
            ModuleName = @{
                ModuleName    = $Resource.ModuleName
                ModuleVersion = $Resource.ModuleVersion
            }
            Name       = $Resource.ResourceName
            Property   = $Resource.PropertiesModified
        }

        if ($Method -eq 'Get')
        {
            $result = Invoke-Command -Session $session -ArgumentList $resourceSplat -ScriptBlock {
                param ($ResourceSplat)
                $result = Invoke-DscResource -Method 'Get' @resourceSplat #-Verbose
                return $result
            }

            # Exclude all default, PowerShell Remoting and CIM properties
            $result = $result | Select-Object -Property '*' -ExcludeProperty 'PSComputerName', 'PSShowComputerName', 'RunspaceId',
                                                                             'ResourceId', 'ModuleName', 'ModuleVersion', 'SourceInfo',
                                                                             'DependsOn', 'ConfigurationName', 'PsDscRunAsCredential',
                                                                             'CimClass', 'CimInstanceProperties', 'CimSystemProperties'

            [PSCustomObject] @{
                PSTypeName   = 'PSDscExecutor.Result.Get'
                ComputerName = $Session.ComputerName
                Module       = $Resource.ModuleName
                Version      = $Resource.ModuleVersion
                Resource     = $Resource.ResourceName
                Description  = $Resource.ResourceDescription
                State        = $result
            }
        }

        if ($Method -eq 'Set')
        {
            $result = Invoke-Command -Session $session -ArgumentList $resourceSplat -ScriptBlock {
                param ($ResourceSplat)
                $result = Invoke-DscResource -Method 'Set' @resourceSplat #-Verbose
                # $result | fl * -force | out-string | out-file -filepath C:\set.txt
                # It's important to convert the property into a boolean value,
                # else the XML serialization will hit a "Serialized XML is
                # nested too deeply." exception. Root cause unknown...
                return [System.Boolean] $result.RebootRequired
            }

            [PSCustomObject] @{
                PSTypeName   = 'PSDscExecutor.Result.Set'
                ComputerName = $Session.ComputerName
                Module       = $Resource.ModuleName
                Version      = $Resource.ModuleVersion
                Resource     = $Resource.ResourceName
                Description  = $Resource.ResourceDescription
                State        = [PSCustomObject] @{ RebootRequired = $result }
            }
        }

        if ($Method -eq 'Test')
        {
            $result = Invoke-Command -Session $session -ArgumentList $resourceSplat -ScriptBlock {
                param ($ResourceSplat)
                $result = Invoke-DscResource -Method 'Test' @resourceSplat #-Verbose
                # It's important to convert the property into a boolean value,
                # else the XML serialization will hit a "Serialized XML is
                # nested too deeply." exception. Root cause unknown...
                return [System.Boolean] $result.InDesiredState
            }

            [PSCustomObject] @{
                PSTypeName   = 'PSDscExecutor.Result.Test'
                ComputerName = $Session.ComputerName
                Module       = $Resource.ModuleName
                Version      = $Resource.ModuleVersion
                Resource     = $Resource.ResourceName
                Description  = $Resource.ResourceDescription
                State        = [PSCustomObject] @{ InDesiredState = $result }
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
