<#
    .SYNOPSIS
        Invoke the get method on all resource in the specified configuration.

    .DESCRIPTION
        This command uses the specified DSC configuration together with the
        configuraiton data and parameters to generate the desired resource.
        This resources will then be invoked with the Invoke-DscResource, all
        without applying a configuration to a LCM.

    .INPUTS
        None.

    .OUTPUTS
        PSDscExecutor.Result.Get.

    .EXAMPLE
        PS C:\> Get-DesiredState
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Get-DesiredState
{
    [CmdletBinding()]
    param
    (
        # If specified, the DSC configuration will be invoked on the remote
        # host. If not, it is invoked locally. It always uses a PowerShell
        # Remoting (PSSession) to execute the DSC configuration.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ComputerName,

        # If specified, the DSC configuration is executed as the provided
        # account. If not specified, it will use the current logon session to
        # authenticate and execute the DSC configuration. The DSC resource
        # property PsDscRunAsCredential will override the credential.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Path to the DSC configuration file. Should contain a configuration
        # named like the configuration file itself or the ConfigurationName
        # parameter is required.
        [Parameter(Mandatory = $true)]
        [Alias('File', 'Path')]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        # Name of the configuration to compile. Default is the configuration
        # base file name. If the configuration name is diffrent, this parameter
        # is required.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ConfigurationName,

        # PowerShell script parameters for the DSC configuration file.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationParam = @{},

        # The configuration data used while compiling the configuration.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationData = @{}
    )

    try
    {
        # Enable the information output by default. If the user specifies the
        # information action parameter, the users choise is respected.
        $informationAction = $InformationPreference
        if (-not $PSBoundParameters.ContainsKey('InformationAction'))
        {
            $informationAction = 'Continue'
        }

        $invokeDesiredStateSplat = @{
            Method             = 'Get'
            ComputerName       = $ComputerName
            Credential         = $Credential
            ConfigurationFile  = $ConfigurationFile
            ConfigurationName  = $ConfigurationName
            ConfigurationParam = $ConfigurationParam
            ConfigurationData  = $ConfigurationData
            InformationAction  = $informationAction
        }
        Invoke-DesiredStateInternal @invokeDesiredStateSplat
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
