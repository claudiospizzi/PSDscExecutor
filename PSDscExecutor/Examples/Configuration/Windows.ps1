<#
    .SYNOPSIS
        DSC configuration for the Windows Server 2022 operating system.
#>
Configuration Windows
{
    param
    (
        # Name of the target computer.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        # Name of the Active Directory domain.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        # Domain Admin credentials.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainCredential
    )

    Import-DscResource -ModuleName 'ComputerManagementDsc' -ModuleVersion '8.5.0'

    Node $AllNodes.NodeName
    {
        Computer 'Computer Name'
        {
            Name       = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCredential
        }
    }
}
