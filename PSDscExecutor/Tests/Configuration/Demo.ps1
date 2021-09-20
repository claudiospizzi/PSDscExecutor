
Configuration Demo
{
    param
    (
        # The registry key value.
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Value
    )

    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0' -Name 'Registry'

    Registry 'RegValue'
    {
        Ensure    = 'Present'
        Key       = 'HKCU:\SOFTWARE\DscDemo'
        Force     = $true
        ValueName = 'Test'
        ValueData = $Value
    }
}
