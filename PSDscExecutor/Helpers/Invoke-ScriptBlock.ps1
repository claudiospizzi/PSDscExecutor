<#
    .SYNOPSIS
        Helper function to invoke a script block on the local system or on the
        remote system if a session was specified.
#>
function Invoke-ScriptBlock
{
    [CmdletBinding()]
    param
    (
        # The remoting session to use.
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        # The script block to invoke.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Parameter for the script block.
        [Parameter(Mandatory = $false)]
        [System.Object[]]
        $ArgumentList = @()
    )

    if ($null -eq $Session)
    {
        $ScriptBlock.Invoke($ArgumentList)
    }
    else
    {
        Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    }
}
