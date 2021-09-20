<#
    .SYNOPSIS
        Compile the DSC configuration into a DSC MOF file.
#>
function ConvertTo-DscMofFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ConfigurationName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationParam,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationData,

        [Parameter(Mandatory = $false)]
        [System.String]
        $OutputPath
    )

    try
    {
        $VerbosePreference = 'SilentlyContinue'

        # Import the configuration file into the current function scope.
        . $ConfigurationFile

        # Check if the configuration contains the expected command name.
        if ((Get-Command -CommandType 'Configuration').Name -notcontains $ConfigurationName)
        {
            throw "The configuration file '$ConfigurationFile' does not contain the configuration named '$ConfigurationName'."
        }

        # Create a temporary output path to store the compiled mof.
        if (-not $PSBoundParameters.ContainsKey('OutputPath'))
        {
            $OutputPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
        }

        # Patch the configuration data with the required node name and allow
        # domain users as well as plain text secrets.
        # TODO: Allow to use certificates for encrypted compilation
        # 1. Ensure the AllNodes key exists
        if (-not $ConfigurationData.ContainsKey('AllNodes'))
        {
            $ConfigurationData['AllNodes'] = @()
        }
        # 2. Ensure the AllNodes key contains one node
        if ($ConfigurationData['AllNodes'].Length -eq 0)
        {
            $ConfigurationData['AllNodes'] += @{}
        }
        # 3. Exit of the AllNodes key contains multiple nodes
        if ($ConfigurationData['AllNodes'].Length -gt 1)
        {
            throw "The configuration data parameter contains more than one node. Only provide one node."
        }
        # 4. Set the required node properties
        $ConfigurationData['AllNodes'][0]['NodeName']                    = 'localhost'
        $ConfigurationData['AllNodes'][0]['PSDscAllowDomainUser']        = $true
        $ConfigurationData['AllNodes'][0]['PSDSCAllowPlainTextPassword'] = $true

        # Compile the DSC configuration into a DSC MOF configuration file
        $mofConfigurationFile = & $ConfigurationName -ConfigurationData $ConfigurationData -OutputPath $OutputPath @ConfigurationParam

        Write-Output $mofConfigurationFile.FullName
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
