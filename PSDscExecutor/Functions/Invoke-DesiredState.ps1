<#
    .SYNOPSIS
        Perform get, set and test methods to bring the target system into the
        desired state. It will continue to test and set until the target system
        is in desired state.

    .DESCRIPTION
        This command uses the specified DSC configuration together with the
        configuration data and parameters to generate the desired resource. This
        resources will then be invoked with the Invoke-DscResource, all without
        applying a configuration to a LCM.

    .INPUTS
        None.

    .OUTPUTS
        PSDscExecutor.Result.Invoke.

    .EXAMPLE
        PS C:\> Invoke-DesiredState
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Invoke-DesiredState
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
        # $informationAction = $InformationPreference
        if (-not $PSBoundParameters.ContainsKey('InformationAction'))
        {
            $InformationPreference = 'Continue'
            # $informationAction = 'Continue'
        }

        $invokeDesiredStateSplat = @{
            Method             = 'Invoke'
            ComputerName       = $ComputerName
            Credential         = $Credential
            ConfigurationFile  = $ConfigurationFile
            ConfigurationName  = $ConfigurationName
            ConfigurationParam = $ConfigurationParam
            ConfigurationData  = $ConfigurationData
            # InformationAction  = $informationAction
        }
        Invoke-DesiredStateInternal @invokeDesiredStateSplat
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
