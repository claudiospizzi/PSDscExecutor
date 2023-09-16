<#
    .SYNOPSIS
        Compile the DSC configuration into a DSC MOF file.

    .DESCRIPTION
        This command will use all provided configurations like the name, data
        and parameter and will invoke the DSC compilation. It will return the
        compiled DSC MOF file.

    .OUTPUTS
        System.String

    .EXAMPLE
        PS C:\> ConvertTo-DscMofFile -ConfigurationName 'WebServer'
        Compile the DSC configuration for the web server.

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function ConvertTo-DscMofFile
{
    [CmdletBinding()]
    param
    (
        # The configuration to compile.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ConfigurationName,

        # The configuration parameter values.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationParam = @{},

        # The configuration data, should contain an AllNodes array with exactly
        # one node. If not, the node is dynamically added.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationData = @{},

        # The document encryption certificate for DSC to encrypt secrets.
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        # Path where the DSC MOF file is stored.
        [Parameter(Mandatory = $false)]
        [System.String]
        $OutputPath
    )

    try
    {
        $VerbosePreference = 'SilentlyContinue'

        # Check if the configuration contains the expected command name.
        $configurationCommands = Get-Command -CommandType 'Configuration'
        if ($null -eq $configurationCommands -or $configurationCommands.Name -notcontains $ConfigurationName)
        {
            throw "The configuration '$ConfigurationName' does not exist."
        }

        # Create a temporary output path to store the compiled mof.
        if (-not $PSBoundParameters.ContainsKey('OutputPath'))
        {
            $OutputPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
        }

        # Define and export the certificate file
        $certificateFile = "{0}\{1}.cer" -f ([System.IO.Path]::GetTempPath()), $certificate.Thumbprint

        # Patch the configuration data with the required node name and allow
        # domain users as well as plain text secrets.
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
        $ConfigurationData['AllNodes'][0]['NodeName'] = 'localhost'
        $ConfigurationData['AllNodes'][0]['CertificateFile'] = $certificateFile
        $ConfigurationData['AllNodes'][0]['Thumbprint'] = $certificate.Thumbprint
        $ConfigurationData['AllNodes'][0]['PSDscAllowDomainUser'] = $true

        try
        {
            $certificate | Export-Certificate -FilePath $certificateFile -Force | Out-Null

            # Compile the DSC configuration into a DSC MOF configuration file
            $mofConfigurationFile = & $ConfigurationName -InstanceName 'localhost' -ConfigurationData $ConfigurationData -OutputPath $OutputPath @ConfigurationParam -ErrorAction 'Stop'

            Write-Output $mofConfigurationFile.FullName
        }
        finally
        {
            if (Test-Path -Path $certificateFile)
            {
                # Remove-Item -Path $certificateFile -Force -ErrorAction 'SilentlyContinue'
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
