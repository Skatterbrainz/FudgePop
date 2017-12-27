function Set-FPControlAppxRemovals {
    <#
    .SYNOPSIS
        Remove Appx Packages
    .DESCRIPTION
        Process Configuration Control: Chocolatey Package Removals
    .PARAMETER DataSet
        XML data from control file import
    .EXAMPLE
        Set-FPControlAppxRemovals -DataSet $xmldata
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog "--------- appx removal assignments: begin ---------"
    foreach ($appx in $DataSet) {
        $deviceName = $appx.device
        $runtime    = $appx.when
        $username   = $appx.user
        $appxcomm   = $appx.comment
        Write-FPLog "device................ $deviceName"
        Write-FPLog "user.................. $username"
        Write-FPLog "runtime............... $runtime"
        Write-FPLog "comment............... $appxcomm"
        if (Test-FPControlRuntime -RunTime $runtime) {
            Write-FPLog "run: runtime is now or already passed"
            $pkglist = $appx.InnerText -split ','
            foreach ($pkg in $pkglist) {
                Write-FPLog "package............... $pkg"
                if (-not $TestMode) {
                    try {
                        Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object {$_.Name -match $pkg} | Remove-AppxPackage -AllUsers -Confirm:$False
                        Write-FPLog "device................ $scDevice"
                        Write-FPLog "status................ successfully uninstalled"
                    }
                    catch {
                        Write-FPLog -Category 'Error' -Message $_.Exception.Message
                        break
                    }
                }
                else {
                    Write-FPLog "TESTMODE: Would have been applied"
                }
            } # foreach
        }
        else {
            Write-FPLog "skip: not yet time to run this assignment"
        }
    } # foreach
    Write-FPLog "--------- appx removal assignments: finish ---------"
}