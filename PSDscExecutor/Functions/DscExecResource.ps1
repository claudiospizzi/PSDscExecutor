<#
    .SYNOPSIS
        .

    .DESCRIPTION
        .

    .INPUTS
        .

    .OUTPUTS
        .

    .EXAMPLE
        PS C:\> DscExecResource
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function DscExecResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $ResourceName,

        [Parameter(Mandatory = $true, Position = 2)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, Position = 3)]
        [System.Collections.Hashtable]
        $Property
    )

    try
    {
        if ($ModuleName.Contains('@'))
        {
            # The module definition contains the required version. Extract the
            # version of the definition and the get the DSC resource.
            $ModuleName, $moduleVersion = $ModuleName.Split('@', 2)
            $dscResource = Get-DscResource -Module @{ ModuleName = $ModuleName; RequiredVersion = $moduleVersion } -Name $ResourceName
        }
        else
        {
            # Get the DSC resource right away. Check if the DSC resource was
            # loaded and extract the version.
            $dscResource = Get-DscResource -Module $ModuleName -Name $ResourceName
            $moduleVersion = $dscResource.Version
            if ($null -eq $moduleVersion)
            {
                $moduleVersion = 'n/a'
                if ($dscResource.Path -like 'C:\Windows\System32\WindowsPowershell\v1.0\Modules\PSDesiredStateConfiguration\DscResources\*')
                {
                    $moduleVersion = '1.1'
                }
            }
        }

        # Verify all mandatory properties are part of the provided properties
        # and extract them in a dedicated hash table.
        $keyProperties = @{}
        foreach ($propertyKey in $dscResource.Properties.Where({ $_.IsMandatory }).Name)
        {
            if ($Property.Keys -notcontains $propertyKey)
            {
                throw "The mandatory property $propertyKey is not specified in $ModuleName@$moduleVersion/$ResourceName/$Name."
            }
            $keyProperties[$propertyKey] = $Property[$propertyKey]
        }

        # Copy and verify all provided properties.
        $allProperties = @{}
        foreach ($propertyKey in $Property.Keys)
        {
            if ($dscResource.Properties.Name -notcontains $propertyKey)
            {
                throw "The property $propertyKey not found in the resource $ModuleName@$moduleVersion/$ResourceName."
            }
            $allProperties[$propertyKey] = $Property[$propertyKey]
        }

        # Prepare all the DSC invocation helpers
        $invokeDscResourceVerbose = "[$ModuleName@$moduleVersion] [$ResourceName] [$Name]"
        # $verboseResourceName  = "[$ModuleName@$moduleVersion] [$ResourceName] [$Name]"
        # $verboseResourceSpace = "[$ModuleName@$moduleVersion] [$ResourceName]" -replace '.', ' '
        # $verboseInstanceName  = "$verboseResourceName [$Name]"
        # $verboseInstanceSpace = $verboseInstanceName -replace '.', ' '
        $invokeDscResourceSplat = @{
            Name       = $ResourceName
            ModuleName = @{
                ModuleName      = $ModuleName
                RequiredVersion = $moduleVersion
            }
        }

        Write-Verbose $invokeDscResourceVerbose

        # Loop over the resource as long as it is not in the desired state.
        $inDesiredState = $false
        while (-not $inDesiredState)
        {
            Write-Verbose "$invokeDscResourceVerbose [Test] Start"

            $inDesiredState = Invoke-DscResource @invokeDscResourceSplat -Method 'Test' -Property $allProperties | Select-Object -ExpandProperty 'InDesiredState'

            Write-Verbose "$invokeDscResourceVerbose [Test]   DesiredState = $inDesiredState"

            Write-Verbose "$invokeDscResourceVerbose [Test] End"

            if (-not $inDesiredState)
            {
                Write-Verbose "$invokeDscResourceVerbose [Set] Start"

                Invoke-DscResource @invokeDscResourceSplat -Method 'Set' -Property $allProperties

                Write-Verbose "$invokeDscResourceVerbose [Set] End"
            }
        }

        Write-Verbose "$invokeDscResourceVerbose [Get] Start"

        $stateData = Invoke-DscResource @invokeDscResourceSplat -Method 'Get' -Property $keyProperties

        foreach ($stateDataPropertyKey in $stateData.Keys)
        {
            Write-Verbose "$invokeDscResourceVerbose [Get]   $stateDataPropertyKey = $($stateData[$stateDataPropertyKey])"
        }

        Write-Verbose "$invokeDscResourceVerbose [Get] End"

        Write-Verbose $invokeDscResourceVerbose

        return $stateData
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
