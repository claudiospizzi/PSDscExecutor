<#
    .SYNOPSIS
        Write the DSC information stream to the host.
#>
function Write-DscInformation
{
    [CmdletBinding()]
    param
    (
        # Verbose record.
        [Parameter(Mandatory = $true, ParameterSetName = 'VerboseRecord', ValueFromPipeline = $true)]
        [System.Management.Automation.VerboseRecord]
        $VerboseRecord
    )

    begin
    {
        $messageFilters = @(
            "Perform operation 'Invoke CimMethod' with following parameters, ''methodName' = Resource*,'className' = MSFT_DSCLocalConfigurationManager,'namespaceName' = root/Microsoft/Windows/DesiredStateConfiguration'."
            "An LCM method call arrived from computer * with user sid *."
            "Operation 'Invoke CimMethod' complete."
            "Time taken for configuration job to complete is * seconds"
        )
    }

    process
    {
        if ($InformationPreference -eq 'Continue')
        {
            if ($PSCmdlet.ParameterSetName -eq 'VerboseRecord')
            {
                if ($messageFilters.Where({ $VerboseRecord.Message -like $_ }).Count -gt 0)
                {
                    return
                }

                $verboseMessageEnhanced = $VerboseRecord.Message.Split(':', 2)[1]
                $verboseMessageEnhanced = '>{0}' -f $verboseMessageEnhanced

                Write-Information $verboseMessageEnhanced
            }
        }
    }
}
