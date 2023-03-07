<#
    .SYNOPSIS
        Invoke the test method on the specified configuration to check, if the
        target system is in desired state.

    .DESCRIPTION
        This command uses the specified DSC configuration together with the
        configuration data and parameters to generate the desired resource. This
        resources will then be called with the Invoke-DscResource, all without
        applying a configuration to a LCM.

        The command can be used in three modes:

        - ConfigurationName only
            The specified configuration name must already be imported into the
            current PowerShell host. The required definition will be extracted
            of the configuration command definition.

        - ConfigurationName with ConfigurationFile
            The specified configuration name must exist in the configuration
            file. The required modules are installed before the configuration is
            compiled.

        - ConfigurationName with ConfigurationScript
            The specified configuration name must exist in the specified script
            block. The required modules are installed before the configuration
            is compiled.

    .INPUTS
        None.

    .OUTPUTS
        PSDscExecutor.Result.Test.

    .EXAMPLE
        PS C:\> Test-DesiredState -ConfigurationName 'WebServer'
        Test the configuration WebServer on the local system.

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Test-DesiredState
{
    [CmdletBinding(DefaultParameterSetName = 'ConfigurationName')]
    param
    (
        # Name of the configuration to be used. Always required. Specify the
        # configuration file or script, if the configuration is not already
        # imported in the current session.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationName,

        # If the configuration is stored in an external PowerShell script file,
        # it can be specified with this parameter.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfigurationFile')]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        # If the configuration is stored in an existing script block, it can be
        # passed with this parameter.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfigurationScript')]
        [System.Management.Automation.ScriptBlock]
        $ConfigurationScript,

        # PowerShell script parameters for the DSC configuration file. By
        # default, no parameters are passed.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationParam = @{},

        # The configuration data used while compiling the configuration. By
        # default, no configuration data is passed.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ConfigurationData = @{},

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

        # Decide, how the executor will handle a reboot request of an invoked
        # DSC resources. By default, the user is asked for every pending reboot.
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

        # Define the basic parameter splat to call the internal invoke method.
        # This also includes the always required configuration name.
        $invokeDesiredStateSplat = @{
            Method             = 'Test'
            ConfigurationName  = $ConfigurationName
            ConfigurationParam = $ConfigurationParam
            ConfigurationData  = $ConfigurationData
            ComputerName       = $ComputerName
            Credential         = $Credential
            RebootPolicy       = $RebootPolicy
            PassThru           = $PassThru.IsPresent
            InformationAction  = $informationAction
        }

        # If using the parameter set for configuration file or script, extend
        # the basic parameter splat.
        switch ($PSCmdlet.ParameterSetName)
        {
            'ConfigurationFile'
            {
                $invokeDesiredStateSplat['ConfigurationFile'] = $ConfigurationName
            }
            'ConfigurationScript'
            {
                $invokeDesiredStateSplat['ConfigurationScript'] = $ConfigurationScript
            }
        }

        Invoke-DesiredStateInternal @invokeDesiredStateSplat
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
