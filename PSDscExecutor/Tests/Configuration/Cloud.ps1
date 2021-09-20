
# Register-MicrosoftOnlineAutomation
# Get-MicrosoftOnlineTenant ARCADESPIZZILAB | fl *

Configuration Cloud
{
    param
    (
        # # Credentials to connect to the tenant.
        # [Parameter(Mandatory = $true)]
        # [System.Management.Automation.PSCredential]
        # $GlobalAdminAccount
    )

    Import-DscResource -ModuleName 'Microsoft365DSC' -ModuleVersion '1.21.908.1' -Name 'AADTenantDetails'

    Node $AllNodes.NodeName
    {
        AADTenantDetails 'TenantDetails'
        {
            TenantId              = '5f36d76e-9089-4ef3-94fc-d1758088e39a'
            ApplicationId         = '08bd4a7c-de3d-4738-a01e-5666bfca19d1'
            CertificateThumbprint = '36F3FD189EDF35C367CF111211BB8060CB833FF3'

            IsSingleInstance      = 'Yes'
        }
    }
}
