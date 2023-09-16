<#
    .SYNOPSIS
        Get the DSC certificate to encrypt the MOF file.

    .DESCRIPTION
        This command will return the certificate used to encrypt the a MOF
        file. If it does not exist, it will throw an error except the
        parameter CreateIfNotExist is specified.

    .OUTPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .EXAMPLE
        PS C:\> Get-DscExecCertificate -CreateIfNotExist
        Get the DSC encryption cert. If it does not exist, generate it.

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Get-DscExecCertificate
{
    [CmdletBinding()]
    param
    (
        # Certificate store for the encryption certificate.
        [Parameter(Mandatory = $false)]
        [System.String]
        $CertStorePath = 'Cert:\LocalMachine\My',

        # Encryption certificate subject.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Subject = 'PSDscExecutor',

        # Option to create the certificate, if it does not exist.
        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateIfNotExist
    )

    try
    {
        $certificate =
            Get-ChildItem -Path $CertStorePath |
                Where-Object { $_.Subject -eq "CN=$Subject" -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } |
                    Select-Object -First 1

        if ($null -eq $certificate)
        {
            if ($CreateIfNotExist.IsPresent)
            {
                $certificateSplat = @{
                    CertStoreLocation = $CertStorePath
                    Type              = 'DocumentEncryptionCertLegacyCsp'
                    DnsName           = $Subject
                    HashAlgorithm     = 'SHA256'
                    NotAfter          = [System.DateTime]::Now.AddYears(10)
                }
                $certificate = New-SelfSignedCertificate @certificateSplat
            }
            else
            {
                throw "No valid DSC encryption certificate $Subject found in $CertStorePath"
            }
        }

        Write-Output $certificate
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
