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
        [AllowNull()]
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
        $Resource,

        [Parameter(Mandatory = $true)]
        [ValidateSet('RebootAndContinue', 'ContinueWithoutReboot', 'ExitConfiguration', 'Inquire')]
        [System.String]
        $RebootPolicy,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $PassThru
    )

    try
    {
        # Detect the computer name based on the session. If no session was
        # specified, we use the local system.
        $computerName = 'localhost'
        if ($null -ne $Session)
        {
            $computerName = $Session.ComputerName
        }

        # Resource definition to be used to invoke the Get, Set or Test method.
        $resourceSplat = @{
            ModuleName = @{
                ModuleName    = $Resource.ModuleName
                ModuleVersion = $Resource.ModuleVersion
            }
            Name       = $Resource.ResourceName
            Property   = $Resource.PropertiesModified
        }

        # Template for the result object. The output state is appended after the
        # method call.
        $resultObject = [PSCustomObject] @{
            PSTypeName   = 'PSDscExecutor.Result.{0}' -f $Method
            ComputerName = $computerName
            Module       = $Resource.ModuleName
            Version      = $Resource.ModuleVersion
            Resource     = $Resource.ResourceName
            Description  = $Resource.ResourceDescription
            State        = $null
        }

        $informationPrefix = '[{0}] [{1}@{2}] [{3}/{4}] [{5}]' -f $computerName, $Resource.ModuleName, $Resource.ModuleVersion, $Resource.ResourceName, $Resource.ResourceDescription.Split(':')[0], $Method

        Write-Information "$informationPrefix Start"

        if ($Method -eq 'Get')
        {
            if ($null -eq $Session)
            {
                $($result = Invoke-DscResource -Method 'Get' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
            }
            else
            {
                $result = Invoke-Command -Session $Session -ArgumentList $resourceSplat -ScriptBlock {
                    param ($ResourceSplat)
                    $(Invoke-DscResource -Method 'Get' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
                }
            }

            # Exclude all default, PowerShell Remoting and CIM properties so
            # that we only have the properties for the actual DSC resource.
            $result = $result | Select-Object -Property '*' -ExcludeProperty 'PSComputerName', 'PSShowComputerName', 'RunspaceId', 'ResourceId', 'ModuleName', 'ModuleVersion', 'SourceInfo', 'DependsOn', 'ConfigurationName', 'PsDscRunAsCredential', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties'

            foreach ($resultPropertyName in $result.PSObject.Properties.Name)
            {
                $resultPropertyValue = $result.$resultPropertyName
                if ($Resource.ResourceName -eq 'Script' -and $resultPropertyName -eq 'Result')
                {
                    $resultPropertyValue = $resultPropertyValue | ConvertTo-Json -Depth 5 -Compress
                }

                Write-Information "$informationPrefix $resultPropertyName = $resultPropertyValue"
            }

            $resultObject.State = $result
        }

        if ($Method -eq 'Set')
        {
            if ($null -eq $Session)
            {
                $($result = Invoke-DscResource -Method 'Set' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
            }
            else
            {
                $result = Invoke-Command -Session $Session -ArgumentList $resourceSplat -ScriptBlock {
                    param ($ResourceSplat)
                    $($result = Invoke-DscResource -Method 'Set' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
                    # It's important to convert the property into a boolean
                    # value, else the XML serialization will hit a "Serialized
                    # XML is nested too deeply." exception. Root cause unknown.
                    return [System.Boolean] $result.RebootRequired
                }
            }

            if ($result)
            {
                Write-Information "$informationPrefix RebootRequired = $result"
            }

            $resultObject.State = [PSCustomObject] @{ RebootRequired = $result }
        }

        if ($Method -eq 'Test')
        {
            if ($null -eq $Session)
            {
                $($result = Invoke-DscResource -Method 'Test' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
            }
            else
            {
                $result = Invoke-Command -Session $Session -ArgumentList $resourceSplat -ScriptBlock {
                    param ($ResourceSplat)
                    $($result = Invoke-DscResource -Method 'Test' @resourceSplat -Verbose) 4>&1 | Write-DscInformation
                    # It's important to convert the property into a boolean
                    # value, else the XML serialization will hit a "Serialized
                    # XML is nested too deeply." exception. Root cause unknown.
                    return [System.Boolean] $result.InDesiredState
                }
            }

            Write-Information "$informationPrefix InDesiredState = $result"

            $resultObject.State = [PSCustomObject] @{ InDesiredState = $result }
        }

        Write-Information "$informationPrefix End"

        if ($PassThru)
        {
            Write-Output $resultObject
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
