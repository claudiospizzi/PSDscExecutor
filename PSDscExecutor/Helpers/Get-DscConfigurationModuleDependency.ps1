<#
    .SYNOPSIS
        Parse the DSC configuration file for module dependencies.
#>
function Get-DscConfigurationModuleDependency
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationFile
    )

    try
    {
        $VerbosePreference = 'SilentlyContinue'

        $tokens = $null
        $errors = $null

        # Query for all Import-DscResource statements in the configuration file
        # by using the abstract syntax tree (AST).
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($ConfigurationFile, [ref]$tokens, [ref]$errors)
        $astImportCommandQuery = { param($astObject) $astObject -is [System.Management.Automation.Language.DynamicKeywordStatementAst] -and $astObject.Extent.Text -like 'Import-DscResource *' }
        $astImportCommands = $ast.FindAll($astImportCommandQuery, $true)

        $moduleInfos = @{}

        foreach ($astImportCommand in $astImportCommands)
        {
            $moduleName    = ''
            $moduleVersion = ''

            # Check all command elements excluding the first (command itself)
            # and the last (parameter value) for a parameters. If a parameter
            # was, go to the next element to get the parameter value.
            $astImportCommandElements = @($astImportCommand.CommandElements)
            for ($i = 1; $i -lt ($astImportCommandElements.Count - 1); $i++)
            {
                if ($astImportCommandElements[$i] -is [System.Management.Automation.Language.CommandParameterAst])
                {
                    # Check for the ModuleName and ModuleVersion parameter.
                    switch -wildcard ($astImportCommandElements[$i].ParameterName)
                    {
                        'ModuleN*' { $moduleName    = [System.String] $astImportCommandElements[$i + 1].Value }
                        'ModuleV*' { $moduleVersion = [System.Version] $astImportCommandElements[$i + 1].Value }
                    }
                }
            }

            # Check the import statement: Is it valid and was the module not
            # imported already with a different version.
            if ([System.String]::IsNullOrEmpty($moduleName) -or
                [System.String]::IsNullOrEmpty($moduleVersion))
            {
                throw "Failed to parse DSC resource import statement, missing module name or version in '$($astImportCommand.Extent.Text)'."
            }
            if ($moduleInfos.ContainsKey($moduleName) -and $moduleInfos[$moduleName].Version -ne $moduleVersion)
            {
                throw "Failed to parse DSC resource import statement, the module $moduleName is specified multiple times with different versions."
            }

            $moduleInfos[$moduleName] = [PSCustomObject] @{
                PSTypeName = 'PSDscExecutor.ModuleInfo'
                Name       = $moduleName
                Version    = $moduleVersion
            }
        }

        Write-Output $moduleInfos.Values
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
