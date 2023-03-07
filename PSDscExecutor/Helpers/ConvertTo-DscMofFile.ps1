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
        [AllowEmptyString()]
        [System.String]
        $ConfigurationName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationParam,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationData,

        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

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
        $ConfigurationData['AllNodes'][0]['NodeName']             = 'localhost'
        $ConfigurationData['AllNodes'][0]['CertificateFile']      = $certificateFile
        $ConfigurationData['AllNodes'][0]['Thumbprint']           = $certificate.Thumbprint
        # $ConfigurationData['AllNodes'][0]['PSDscAllowDomainUser'] = $true
        # $ConfigurationData['AllNodes'][0]['PSDSCAllowPlainTextPassword'] = $true

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
    finally
    {
    }
}
