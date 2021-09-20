
Configuration WS2022
{
    param
    (
        # Name of the target computer.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName
    )

    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName 'ComputerManagementDsc' -ModuleVersion '8.5.0'

    Computer 'Computer Name'
    {
        Name        = $ComputerName
        Description = 'Windows Server 2022 ;-)'
    }

    PowerPlan 'High Performance'
    {
        IsSingleInstance = 'Yes'
        Name             = 'High Performance'
    }

    WindowsFeature 'DNS Feature'
    {
        Ensure = 'Present'
        Name   = 'RSAT-DNS-Server'
    }
}
