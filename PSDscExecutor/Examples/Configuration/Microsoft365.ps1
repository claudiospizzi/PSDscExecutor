<#
    .SYNOPSIS
        DSC configuration for the Microsoft 365 Cloud.
#>
Configuration Microsoft365
{
    param
    (
        # Global Admin credentials.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminCredential
    )

    Import-DscResource -ModuleName 'Microsoft365DSC' -ModuleVersion '1.21.1013.1' # Oct 2021

    Node $AllNodes.NodeName
    {
        AADTenantDetails 'AADTenantDetails'
        {
            IsSingleInstance = 'Yes'
            Credential       = $GlobalAdminCredential
        }
    }
}
