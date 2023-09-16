<#
    .SYNOPSIS
        Internal method to simplify the invocation independent of the used DSC
        method like get, set, test or invoke.
#>
function Invoke-DesiredStateInternal
{
    [CmdletBinding(DefaultParameterSetName = 'ConfigurationName')]
    param
    (
        # Specify which method should be executed. The invoke method is a
        # combination of test and set with a loop to ensure the desired state of
        # a system as the command has finished.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Set', 'Test', 'Invoke')]
        [System.String]
        $Method,

        # Name of the configuration.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationName,

        # Path to the configuration file, if used.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfigurationFile')]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        # Script definition of the configuration, if used.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfigurationScript')]
        [System.Management.Automation.ScriptBlock]
        $ConfigurationScript,

        # The configuration parameter. Always passed, but can be an empty.
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationParam,

        # The configuration parameter. Always passed, but can be an empty.
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationData,

        # The remoting computer name. Always passed, but can be an empty string.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ComputerName,

        # The remoting credential. Always passed, but can be an empty.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Definition of the reboot behavior.
        [Parameter(Mandatory = $true)]
        [ValidateSet('RebootAndContinue', 'ContinueWithoutReboot', 'ExitConfiguration', 'Inquire')]
        [System.String]
        $RebootPolicy,

        # Option to return the output objects.
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $PassThru
    )

    try
    {
        #region Prerequisite

        # Check for Windows PowerShell 5.1
        if ($PSVersionTable.PSVersion.Major -gt 5)
        {
            Write-Warning "THE PREREQUISITE CHECK FOR WINDOWS POWERSHELL 5.1 IS DISABLED!"
            # throw 'The PSDscExecutor requires Windows PowerShell 5.1 and does not support later PowerShell version because of a DSC incompatibility.'
        }

        # If executing on the local system, ensure the ComputerName is set to
        # localhost and the current process has Administrator privileges.
        if ([System.String]::IsNullOrEmpty($ComputerName) -or $ComputerName -in 'localhost', '127.0.0.1', '::1', $Env:ComputerName -or $ComputerName -like "$Env:ComputerName.*")
        {
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
            {
                Write-Warning "THE PREREQUISITE CHECK FOR LOCAL ADMINISTRATOR ROLE IS DISABLED!"
                # throw 'The PSDscExecutor requires administrator privilege if invoked against the local system.'
            }

            $ComputerName = 'localhost'
        }

        #endregion

        #region Module Dependency

        # Load the configuration definition from memory, file or script block.
        switch ($PSCmdlet.ParameterSetName)
        {
            'ConfigurationName'
            {
                $configurationDefinition = Get-DscConfigurationDefinition -ConfigurationName $ConfigurationName
            }

            'ConfigurationFile'
            {
                $configurationDefinition = Get-DscConfigurationDefinition -ConfigurationName $ConfigurationName -ConfigurationFile $ConfigurationFile
            }

            'ConfigurationScript'
            {
                $configurationDefinition = Get-DscConfigurationDefinition -ConfigurationName $ConfigurationName -ConfigurationScript $ConfigurationScript
            }
        }

        # Extract all depending modules from the configuration definition.
        $moduleInfos = Get-DscConfigurationModuleDependency -ConfigurationDefinition $configurationDefinition

        # Install all dependency modules if they are not present yet.
        foreach ($moduleInfo in $moduleInfos)
        {
            Update-DscModuleInstallation -ModuleName $moduleInfo.Name -ModuleVersion $moduleInfo.Version -Import
        }

        #endregion

        #region Compile Configuration

        try
        {
            if ($PSCmdlet.ParameterSetName -in 'ConfigurationFile', 'ConfigurationScript')
            {
                Write-Verbose "[PSDscExecutor] DSC Compile Configuration: Interpret Configuration"

                $configurationDefinitionScriptBlock = [System.Management.Automation.ScriptBlock]::Create($configurationDefinition)

                . $configurationDefinitionScriptBlock
            }

            Write-Verbose "[PSDscExecutor] DSC Compile Configuration: Generate Certificate"

            $certificate = Get-DscExecCertificate -CreateIfNotExist

            Write-Verbose "[PSDscExecutor] DSC Compile Configuration: Invoke Compilation"

            # Compile the DSC configuration into a DSC MOF file. Provide the
            # configuration data and parameters.
            Update-DscResourceCache -ModuleInfo $moduleInfos -Clear
            $mofFile = ConvertTo-DscMofFile -ConfigurationName $ConfigurationName -ConfigurationParam $ConfigurationParam -ConfigurationData $ConfigurationData -Certificate $certificate

            Write-Verbose "[PSDscExecutor] DSC Compile Configuration: Extract Configuration Resources $mofFile"

            # Now, convert the parsed DSC MOF configuration file back to a
            # PowerShell object
            Update-DscResourceCache -ModuleInfo $moduleInfos -Clear
            $configuration = ConvertFrom-DscMofFile -Path $mofFile
        }
        finally
        {
            # Ensure the DSC MOF file is removed after using, as the file could
            # potentially contain sensitive data.
            if ((Get-Variable).Name -contains 'mofFile' -and $null -ne $mofFile -and (Test-Path -Path $mofFile))
            {
                # Remove-Item -Path $mofFile -Force
            }
        }

        #endregion

        #region Invoke Configuration

        try
        {
            $session = $null

            if ($ComputerName -ne 'localhost')
            {
                if ($PSBoundParameters.ContainsKey('Credential') -and $null -ne $Credential)
                {
                    Write-Verbose "[PSDscExecutor] DSC Execution: Open Session on $ComputerName as $($Credential.Username)"

                    $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                }
                else
                {
                    Write-Verbose "[PSDscExecutor] DSC Execution: Open Session on $ComputerName"

                    $session = New-PSSession -ComputerName $ComputerName
                }
            }

            foreach ($resource in $configuration.Resources)
            {
                $resourceId = $resource.ResourceId.Split(':')[0]

                $invokeDesiredStateResourceSplat = @{
                    Session      = $session
                    Resource     = $resource
                    RebootPolicy = $RebootPolicy
                    PassThru     = $PassThru
                }

                if ($Method -in 'Get', 'Set', 'Test')
                {
                    Invoke-DesiredStateResource @invokeDesiredStateResourceSplat -Method $Method
                }
                else
                {
                    $invokeDesiredStateResourceSplat.PassThru = $true

                    do
                    {
                        # First test if the resource is in desired state. If
                        # yes, we don't have to invoke the set command later and
                        # continue directly to the loop check.
                        $testState = Invoke-DesiredStateResource @invokeDesiredStateResourceSplat -Method 'Test'
                        if ($PassThru)
                        {
                            Write-Output $testState
                        }
                        if ($testState.State.InDesiredState)
                        {
                            continue
                        }

                        # Second invoke the method Set to bring the resource
                        # into the desired state. We anyway will test again
                        # afterwards to check, if the resource really is in
                        # desired state.
                        $setState = Invoke-DesiredStateResource @invokeDesiredStateResourceSplat -Method 'Set'
                        if ($PassThru)
                        {
                            Write-Output $testState
                        }

                        # The Set method can return a flag, that the target
                        # system requires a reboot. Control, how the reboot is
                        # handled.
                        if ($setState.State.RebootRequired)
                        {
                            $verifiedRebootPolicy = $RebootPolicy

                            if ($verifiedRebootPolicy -eq 'Inquire')
                            {
                                Write-Host ''
                                Write-Host 'Reboot'
                                Write-Host "The resource '$resourceId' requires a reboot of the system '$ComputerName', how do you want to continue?"

                                $inputReboot = ''
                                do
                                {
                                    $inputReboot = Read-Host -Prompt '[R] Reboot and Continue  [C] Continue without Reboot  [X] Exit Configuration  '
                                }
                                while ($inputReboot -notin 'R', 'C', 'X')

                                switch ($inputReboot)
                                {
                                    'R' { $verifiedRebootPolicy = 'RebootAndContinue' }
                                    'C' { $verifiedRebootPolicy = 'ContinueWithoutReboot' }
                                    'X' { $verifiedRebootPolicy = 'ExitConfiguration' }
                                }
                            }

                            if ($verifiedRebootPolicy -eq 'ExitConfiguration')
                            {
                                throw "The resource '$resourceId' requires a reboot of the system '$ComputerName'. The reboot policy is set to 'ExitConfiguration'. Exit configuration now."
                            }

                            if ($verifiedRebootPolicy -eq 'RebootAndContinue')
                            {
                                if ($null -eq $session)
                                {
                                    throw "The resource '$resourceId' requires a reboot of the local system. Please reboot now and restart the configuration by hand."
                                }
                                else
                                {
                                    throw "Remote reboot not implemented yet!"

                                    # Write-Verbose "[PSDscExecutor] DSC Execution: Reboot $ComputerName"

                                    # Invoke-Command $session -ScriptBlock { shutdown -r -t 0 }
                                    # Remove-PSSession $session -ErrorAction 'SilentlyContinue'
                                    # Start-Sleep -Second 60
                                    # $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                                }
                            }
                        }
                    }
                    while (-not $testState.State.InDesiredState)
                }
            }
        }
        finally
        {
            if ($null -ne $session)
            {
                Remove-PSSession $session
            }
        }




        #endregion

        return



        # ToDo
        # Rewritten up to here with the new configuration parameter options. Continue below.
        # **********************************************************************************

    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
