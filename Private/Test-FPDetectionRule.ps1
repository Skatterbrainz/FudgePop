function Test-FPDetectionRule {
    <#
    .SYNOPSIS
        Return TRUE if detection rule is valid
    .PARAMETER DataSet
        XML data from control file import
    .PARAMETER RuleName
        Name of rule in control XML file
    #>
        param (
            [parameter(Mandatory = $True)]
            $DataSet,
            [parameter(Mandatory = $True)]
            [ValidateNotNullOrEmpty()]
            [string] $RuleName
        )
        Write-FPLog "detection rule: $RuleName"
        try {
            $detectionRule = $DataSet.configuration.detectionrules.detectionrule | Where-Object {$_.name -eq $RuleName}
            $rulePath = $detectionRule.path
            Write-FPLog "detection test: $rulePath"
            Write-Output (Test-Path $rulePath)
        }
        catch {}
}