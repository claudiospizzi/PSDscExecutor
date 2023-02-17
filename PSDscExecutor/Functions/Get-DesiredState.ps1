<#
    .SYNOPSIS
        Invoke the get method on all resource in the specified configuration.

    .DESCRIPTION
        This command uses the specified DSC configuration together with the
        configuration data and parameters to generate the desired resource. This
        resources will then be called with the Invoke-DscResource, all without
        applying a configuration to a LCM.

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

        # Path to the DSC configuration file. The configuration name should
        # match the configuration file name. If not, the configuration name must
        # be specified in the ConfigurationName parameter.
        [Parameter(Mandatory = $true)]
        [Alias('File', 'Path')]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        # Name of the configuration to compile. Default is the configuration
        # base file name. If the configuration name is different, this parameter
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
        $ConfigurationData = @{},

        # Device how the executor will handle a reboot request of a DSC
        # resource. By default, the user is queried for every reboot.
        [Parameter(Mandatory = $false)]
        [ValidateSet('RebootAndContinue', 'ContinueWithoutReboot', 'ExitConfiguration', 'Inquire')]
        [System.String]
        $RebootPolicy = 'Inquire',

        # Pass the result object to the output stream.
        [Parameter(Mandatory = $false)]
        [Switch]
        $PassThru
    )

    try
    {
        # Enable the information output by default. The InformationPreference
        # variable will hold the value of the InformationAction parameter, if it
        # was specified by the caller. This will be respected.
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
            RebootPolicy       = $RebootPolicy
            PassThru           = $PassThru.IsPresent
            InformationAction  = $informationAction
        }
        Invoke-DesiredStateInternal @invokeDesiredStateSplat
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
