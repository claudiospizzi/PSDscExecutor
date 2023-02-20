<#
    .SYNOPSIS
        Load the configuration definition from the specified configuration file
        or from the already interpreted configuration by configuration name.
#>
function Get-DscConfigurationDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'ConfigurationName')]
    param
    (
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
        $ConfigurationScript
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'ConfigurationName'
        {
            Write-Verbose "[PSDscExecutor] DSC Configuration Definition: Parse the already imported in-memory configuration '$ConfigurationName'"

            # The configuration is already defined as command in the current
            # PowerShell host, so extract it from memory.
            $configurationCommand = Get-Command -Name $ConfigurationName -CommandType 'Configuration' -ErrorAction 'SilentlyContinue' -All | Select-Object -First 1

            if ($null -eq $configurationCommand)
            {
                throw "The configuration definition '$ConfigurationName' was not found in the PowerShell host memory and was not imported yet."
            }

            # Finally, we wrap the configuration block around the command
            # definition script block.
            $configurationDefinition = 'Configuration {0} {{ {1} }}' -f $ConfigurationName, $configurationCommand.Definition
        }

        'ConfigurationFile'
        {
            Write-Verbose "[PSDscExecutor] DSC Configuration Definition: Load the configuration '$ConfigurationName' from the provided file '$ConfigurationFile'"

            $tokens = $null
            $errors = $null

            # Use the PowerShell language parser to generate an abstract syntax
            # tree of the configuration file and search for the configuration
            # node in the file.
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($ConfigurationFile, [ref]$tokens, [ref]$errors)
            $astConfigurationQuery = { param($astObject) $astObject -is [System.Management.Automation.Language.ConfigurationDefinitionAst] -and $astObject.InstanceName.Value -eq $ConfigurationName }
            $astConfiguration = $ast.FindAll($astConfigurationQuery, $true) | Select-Object -First 1

            if ($null -eq $astConfiguration)
            {
                throw "The configuration definition '$ConfigurationName' was not found in the configuration file '$ConfigurationFile'."
            }

            $configurationDefinition = $astConfiguration.Extent.Text
        }

        'ConfigurationScript'
        {
            Write-Verbose "[PSDscExecutor] DSC Configuration Definition: Load the configuration '$ConfigurationName' from the provided script block"

            $tokens = $null
            $errors = $null

            # Use the PowerShell language parser to generate an abstract syntax
            # tree of the configuration script and search for the configuration
            # node in the file.
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ConfigurationScript.ToString(), [ref]$tokens, [ref]$errors)
            $astConfigurationQuery = { param($astObject) $astObject -is [System.Management.Automation.Language.ConfigurationDefinitionAst] -and $astObject.InstanceName.Value -eq $ConfigurationName }
            $astConfiguration = $ast.FindAll($astConfigurationQuery, $true) | Select-Object -First 1

            if ($null -eq $astConfiguration)
            {
                throw "The configuration definition '$ConfigurationName' was not found in the provided script block."
            }

            $configurationDefinition = $astConfiguration.Extent.Text
        }
    }

    Write-Output $configurationDefinition
}
