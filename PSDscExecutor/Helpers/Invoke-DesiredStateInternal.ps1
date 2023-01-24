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
        $ConfigurationData = @{}
    )

    try
    {
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
            Write-Verbose "DSC Resource Dependency: Found Module $($moduleInfo.Name) $($moduleInfo.Version)"
            Import-Module -Name $moduleInfo.Name -RequiredVersion $moduleInfo.Version -Verbose:$false
        }

        $certificate = Get-DscExecCertificate -CreateIfNotExist

        try
        {
            Write-Verbose "DSC Compile: Invoke Configuration $ConfigurationFile"

            # Compile the DSC configuration into a DSC MOF file. Provide the
            # configuration data and parameters.
            Update-DscResourceCache -ModuleInfo $moduleInfos -Clear
            $mofFile = ConvertTo-DscMofFile -ConfigurationFile $ConfigurationFile -ConfigurationName $ConfigurationName -ConfigurationParam $ConfigurationParam -ConfigurationData $ConfigurationData -Certificate $certificate

            Write-Verbose "DSC Compile: Extract Configuration Resources $mofFile"

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

            # ToDo: Create a command to open a session
            if ($PSBoundParameters.ContainsKey('Credential') -and $null -ne $Credential)
            {
                Write-Verbose "DSC Execution: Open Session on $ComputerName as $($Credential.Username)"

                $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            }
            else
            {
                Write-Verbose "DSC Execution: Open Session on $ComputerName"

                $session = New-PSSession -ComputerName $ComputerName
            }

            Write-Verbose "DSC Execution: Install and Import Provider NuGet 2.8.5.201"

            Invoke-Command -Session $session -ScriptBlock {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
            }

            foreach ($moduleInfo in $moduleInfos)
            {
                Write-Verbose "DSC Execution: Install and Import Module $($moduleInfo.Name) $($moduleInfo.Version)"

                Invoke-Command -Session $session -ScriptBlock {
                    $module = Get-Module -FullyQualifiedName @{ ModuleName = $using:moduleInfo.Name; ModuleVersion = $using:moduleInfo.Version } -ListAvailable -Verbose:$false
                    if ($null -eq $module)
                    {
                        Install-Module -Name $using:moduleInfo.Name -RequiredVersion $using:moduleInfo.Version -AllowClobber -SkipPublisherCheck -Force #-AcceptLicense
                    }
                    Import-Module -Name $using:moduleInfo.Name -RequiredVersion $using:moduleInfo.Version -Global -Force
                }
            }

            foreach ($resource in $configuration.Resources)
            {
                if ($Method -in 'Get', 'Set', 'Test')
                {
                    Invoke-DesiredStateResource -Session $session -Method $Method -Resource $Resource
                }
                else
                {
                    $testState = Invoke-DesiredStateResource -Session $session -Method 'Test' -Resource $Resource
                    while (-not $testState.State.InDesiredState)
                    {
                        $setState = Invoke-DesiredStateResource -Session $session -Method 'Set' -Resource $Resource
                        if ($setState.State.RebootRequired)
                        {
                            Invoke-Command -Session $session -ScriptBlock { shutdown -r -t 0 }
                            Remove-PSSession -Session $session -ErrorAction 'SilentlyContinue'
                            Start-Sleep -Second 15
                            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                        }

                        $testState = Invoke-DesiredStateResource -Session $session -Method 'Test' -Resource $Resource
                    }
                }
            }
        }
        finally
        {
            if ($null -ne $session)
            {
                Remove-PSSession -Session $session
            }
        }

        # $configuration | ft
        # $configuration.Resources | fl
        # $configuration.Resources.Properties | fl

        return








        $configuration

        foreach ($resource in $configuration.Resources)
        {
            Invoke-DscResourceInternal -Method 'Get' -Resource $resource
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
