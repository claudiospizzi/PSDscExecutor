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
        PS C:\> DscExecConfiguration
        .

    .LINK
        https://github.com/claudiospizzi/PSDscExecutor
#>
function DscExecConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ScriptBlock]
        $Definition
    )

    try
    {
        & $Definition | Out-Null
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
