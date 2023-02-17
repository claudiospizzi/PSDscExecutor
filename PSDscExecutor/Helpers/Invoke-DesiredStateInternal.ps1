<#
    .SYNOPSIS
        .

    .DESCRIPTION
        .

    .INPUTS
        .

    .OUTPUTS
        .

    .EXAMPLE
        PS C:\> Invoke-DesiredStateInternal
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Invoke-DesiredStateInternal
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Set', 'Test', 'Invoke')]
        [System.String]
        $Method,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ConfigurationName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationParam = @{},

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ConfigurationData = @{},

        [Parameter(Mandatory = $true)]
        [ValidateSet('RebootAndContinue', 'ContinueWithoutReboot', 'ExitConfiguration', 'Inquire')]
        [System.String]
        $RebootPolicy,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $PassThru
    )

    try
    {
        # Prerequisite: Windows PowerShell 5.1
        if ($PSVersionTable.PSVersion.Major -gt 5)
        {
            throw 'The PSDscExecutor requires Windows PowerShell 5.1 and does not support later PowerShell version because of a DSC incompatibility.'
        }

        # Prerequisite: Administrator (if on localhost)
        if ([System.String]::IsNullOrEmpty($ComputerName))
        {
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
            {
                throw 'The PSDscExecutor requires administrator privilege if invoked against the local system.'
            }
        }

        # Parameter: ComputerName
        if ([System.String]::IsNullOrEmpty($ComputerName))
        {
            $ComputerName = 'localhost'
        }

        # Parameter: ConfigurationName
        if ([System.String]::IsNullOrEmpty($ConfigurationName))
        {
            $ConfigurationName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigurationFile)
        }

        # Module Dependencies
        $moduleInfos = Get-DscConfigurationModuleDependency -ConfigurationFile $ConfigurationFile
        foreach ($moduleInfo in $moduleInfos)
        {
            Write-Verbose "[PSDscExecutor] DSC Resource Dependency: Found Module $($moduleInfo.Name) $($moduleInfo.Version)"
            Import-Module -Name $moduleInfo.Name -RequiredVersion $moduleInfo.Version -Verbose:$false -Force
        }

        $certificate = Get-DscExecCertificate -CreateIfNotExist

        try
        {
            Write-Verbose "[PSDscExecutor] DSC Compile: Invoke Configuration $ConfigurationFile"

            # Compile the DSC configuration into a DSC MOF file. Provide the
            # configuration data and parameters.
            Update-DscResourceCache -ModuleInfo $moduleInfos -Clear
            $mofFile = ConvertTo-DscMofFile -ConfigurationFile $ConfigurationFile -ConfigurationName $ConfigurationName -ConfigurationParam $ConfigurationParam -ConfigurationData $ConfigurationData -Certificate $certificate

            Write-Verbose "[PSDscExecutor] DSC Compile: Extract Configuration Resources $mofFile"

            # Now, convert the parsed DSC MOF configuration file back to a
            # PowerShell object
            Update-DscResourceCache -ModuleInfo $moduleInfos -Clear
            $configuration = ConvertFrom-DscMofFile -Path $mofFile
        }
        finally
        {
            # Ensure the DSC MOF file is removed after using, as the file could
            # potentially contain sensitive data.
            if ($null -ne $mofFile -and (Test-Path -Path $mofFile))
            {
                Remove-Item -Path $mofFile -Force
            }
        }

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

            Write-Verbose "[PSDscExecutor] DSC Execution: Install and Import Provider NuGet 2.8.5.201"

            $installPackageProviderScriptBlock = {
                Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Force -Verbose:$false | Out-Null
            }

            if ($null -eq $session)
            {
                $installPackageProviderScriptBlock.Invoke()
            }
            else
            {
                Invoke-Command -Session $session -ScriptBlock $installPackageProviderScriptBlock
            }

            foreach ($moduleInfo in $moduleInfos)
            {
                Write-Verbose "[PSDscExecutor] DSC Execution: Install and Import Module $($moduleInfo.Name) $($moduleInfo.Version)"

                $installAndImportModuleScriptBlock = {
                    param ($Name, $Version)

                    $module = Get-Module -FullyQualifiedName @{ ModuleName = $Name; ModuleVersion = $Version } -ListAvailable -Verbose:$false | Where-Object { $_.ModuleBase -like 'C:\Program Files\*' }

                    if ($null -eq $module)
                    {
                        Install-Module -Name $Name -RequiredVersion $Version -Scope 'AllUsers' -AllowClobber -SkipPublisherCheck -Force -Verbose:$false #-AcceptLicense
                    }

                    Import-Module -Name $Name -RequiredVersion $Version -Global -Force -Verbose:$false
                }

                if ($null -eq $session)
                {
                    $installAndImportModuleScriptBlock.Invoke($moduleInfo.Name, $moduleInfo.Version)
                }
                else
                {
                    Invoke-Command -Session $session -ScriptBlock $installAndImportModuleScriptBlock -ArgumentList $moduleInfo.Name, $moduleInfo.Version
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
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
