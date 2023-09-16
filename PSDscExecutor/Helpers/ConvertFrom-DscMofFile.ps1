<#
    .SYNOPSIS
        Convert a DSC MOF configuration file into a PowerShell object.

    .DESCRIPTION
        Use the internal function ImportInstances() of the DSC DscClassCache
        class to convert the DSC MOF configuration file into a PowerShell object
        containing a list of DSC resources.

        The Update-DscResourceCache should be used prior to this command to
        ensure, the required resources are loaded into the cache.

    .OUTPUTS
        PSDscExecutor.Configuration

    .EXAMPLE
        PS C:\> ConvertFrom-DscMofFile -Path .\MyConfig.mof
        Convert the provided DSC MOF configuration file to a PowerShell object
        with the DSC configuration and resources.

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function ConvertFrom-DscMofFile
{
    [CmdletBinding()]
    param
    (
        # Path to the MOF file.
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $Path
    )

    try
    {
        # Resolve the path to the real full path, required in the .NET method.
        $Path = Resolve-Path -Path $Path

        $mofCimInstances = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($Path)

        # Extract the configuration document, also called the configuration
        # meta data with the configuration details like author and host.
        $mofCimCfgDocument = $mofCimInstances | Where-Object { $_.CimClass.CimClassName -eq 'OMI_ConfigurationDocument' } | Select-Object -First 1
        if ($null -eq $mofCimCfgDocument)
        {
            throw "Failed to parse DSC MOF configuration: OMI_ConfigurationDocument node missing"
        }

        $configuration = [PSCustomObject] @{
            PSTypeName = 'PSDscExecutor.Configuration'
            Name       = [System.String] $mofCimCfgDocument.Name
            Version    = [System.Version] $mofCimCfgDocument.Version
            Date       = [System.DateTime] $mofCimCfgDocument.GenerationDate
            Author     = [System.String] $mofCimCfgDocument.Author
            Host       = [System.String] $mofCimCfgDocument.GenerationHost
            Resources  = [System.Collections.ArrayList]::new()
        }

        foreach ($mofCimInstance in $mofCimInstances)
        {
            # All resources should be based on the OMI_BaseResource super
            # class. All these resources will be added to the configuration
            # resources.
            if ($mofCimInstance.CimClass.CimSuperClassName -eq 'OMI_BaseResource')
            {
                $resource = [PSCustomObject] @{
                    PSTypeName           = 'PSDscExecutor.Configuration.Resource'
                    ResourceId           = $mofCimInstance.ResourceId
                    ResourceName         = $mofCimInstance.ResourceId.Substring(1, $mofCimInstance.ResourceId.IndexOf(']') - 1)
                    ResourceDescription  = $mofCimInstance.ResourceId.Split(']', 2)[1]
                    ModuleName           = $mofCimInstance.ModuleName
                    ModuleVersion        = $mofCimInstance.ModuleVersion
                    SourceInfo           = $mofCimInstance.SourceInfo
                    DependsOn            = $mofCimInstance.DependsOn
                    PSDscRunAsCredential = $mofCimInstance.PsDscRunAsCredential
                    Properties           = [System.Collections.ArrayList]::new()
                    PropertiesModified   = @{}
                }

                foreach ($propertyDefinition in $mofCimInstance.CimInstanceProperties)
                {
                    # Skip the default properties, not custom to a resource.
                    if ($propertyDefinition.Name -in 'ResourceId', 'ModuleName', 'ModuleVersion', 'SourceInfo', 'DependsOn', 'ConfigurationName', 'PsDscRunAsCredential')
                    {
                        continue
                    }

                    $property = [PSCustomObject] @{
                        PSTypeName = 'PSDscExecutor.Configuration.Resource.Property'
                        Name       = $propertyDefinition.Name
                        Value      = $propertyDefinition.Value
                        Type       = $propertyDefinition.CimType
                        IsKey      = [System.Boolean] ($propertyDefinition.Flags -band [Microsoft.Management.Infrastructure.CimFlags]::Key)
                        IsModified = $propertyDefinition.IsValueModified
                    }
                    $resource.Properties.Add($property) | Out-Null

                    # Generate a list of all modified property. Used directory
                    # as the property parameter for the Invoke-DscResource
                    # command.
                    if ($property.IsModified)
                    {
                        $resource.PropertiesModified[$property.Name] = $property.Value
                    }
                }

                $configuration.Resources.Add($resource) | Out-Null
            }
            # Skip the DSC MOF configuration document.
            elseif ($mofCimInstance.CimClass.CimClassName -eq 'OMI_ConfigurationDocument')
            {
                continue
            }
            # If it's not a configuration document nor a base resource, it's an
            # unexpected DSC CIM instance!
            else
            {
                throw "Failed to parse DSC MOF configuration: $($mofCimInstance.CimClass.CimClassName) unexpected"
            }
        }

        # Convert the array list into a simple array.
        $configuration.Resources = $configuration.Resources.ToArray()

        Write-Output $configuration
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
