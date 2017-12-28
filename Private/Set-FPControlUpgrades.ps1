function Set-FPControlUpgrades {
    <#
    .SYNOPSIS
        Upgrade Chocolatey Packages
    .DESCRIPTION
        Process Configuration Control: Chocolatey Package Upgrades
    .PARAMETER DataSet
        XML data from control file import
    .EXAMPLE
        Set-FPControlUpgrades -DataSet $xmldata
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog "--------- upgrade assignments: begin ---------"
    foreach ($upgrade in $DataSet) {
        # later / maybe
    }
    Write-FPLog "--------- upgrade assignments: finish ---------"
}