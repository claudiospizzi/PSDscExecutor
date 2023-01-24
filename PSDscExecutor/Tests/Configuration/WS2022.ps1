
Configuration WS2022
{
    param
    (
        # Name of the target computer.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        # Name of the AD domain.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        # AD domain NetBIOS.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainNetBIOS,

        # AD domain credential.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainCredential,

        # The DSRM restore mode password.
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $DomainSafeModePassword
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration' -ModuleVersion '1.1'
    Import-DscResource -ModuleName 'ComputerManagementDsc' -ModuleVersion '8.5.0'
    Import-DscResource -ModuleName 'NetworkingDsc' -ModuleVersion '8.2.0'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc' -ModuleVersion '6.0.1'

    Node $AllNodes.NodeName
    {
        Computer 'Computer Name'
        {
            Name        = $ComputerName
            Description = 'Domain Controller'
        }

        PowerPlan 'High Performance'
        {
            IsSingleInstance = 'Yes'
            Name             = 'High Performance'
        }

        WindowsFeature 'RSAT DNS Feature'
        {
            Ensure = 'Present'
            Name   = 'RSAT-DNS-Server'
        }

        WindowsFeature 'RSAT ADDS PowerShell Feature'
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-PowerShell'
        }

        WindowsFeature 'WIN-Domain-ADDSFeature'
        {
            Ensure    = 'Present'
            Name      = 'AD-Domain-Services'
        }

        ADDomain 'WIN-Domain-InstallForest'
        {
            DomainName                    = $DomainName
            DomainNetbiosName             = $DomainNetBIOS
            Credential                    = $DomainCredential
            SafemodeAdministratorPassword = ConvertTo-WindowsCredential -Username 'dsrm' -Password $DomainSafeModePassword
        }

        DnsServerAddress 'WIN-Network-IPv4-DnsServer'
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'

            Address        = '127.0.0.1'
            Validate       = $false
        }
    }
}
