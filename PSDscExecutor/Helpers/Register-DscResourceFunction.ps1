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
        PS C:\> Register-DscResourceFunction
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function Register-DscResourceFunction
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResourceInfo,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Script', 'Global')]
        [System.String]
        $Scope = 'Script'
    )

    begin
    {
        try
        {
            # Resource with no module name?!?
            $functionName = '{0}:{1}@{2}\{3}' -f $Scope, $DscResourceInfo.ModuleName, $DscResourceInfo.Version, $DscResourceInfo.Name
            $functionCode = [System.Management.Automation.ScriptBlock]::Create('param ($A) Write-Host "A: $A"')

            New-Item -Path 'Function:\' -Name $functionName -Value $functionCode | Out-Null
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
