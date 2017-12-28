function Set-FPControlRemovals {
    <#
    .SYNOPSIS
        Uninstall Chocolatey Packages
    .DESCRIPTION
        Uninstall Chocolatey Packages applicable to this computer
    .PARAMETER DataSet
        XML data
    .EXAMPLE
        Set-FPControlRemovals -DataSet $xmldata
    .NOTES
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog "--------- removal assignments: begin ---------"
    foreach ($package in $DataSet) {
        $deviceName = $package.device
        $collection = $package.collection
        $runtime    = $package.when
        $autoupdate = $package.autoupdate
        $username   = $package.user
        $extparams  = $package.params
        Write-FPLog "device................ $deviceName"
        Write-FPLog "collection............ $collection"
        Write-FPLog "user.................. $username"
        Write-FPLog "autoupdate............ $autoupdate"
        Write-FPLog "runtime............... $runtime"
        if (Test-FPControlRuntime -RunTime $runtime) {
            Write-FPLog "run: runtime is now or already passed"
            $pkglist = $package.InnerText -split ','
            if ($extparams.length -gt 0) { $params = $extparam } else { $params = ' -y -r' }
            foreach ($pkg in $pkglist) {
                Write-FPLog "package............... $pkg"
                if (Test-Path "$($env:PROGRAMDATA)\chocolatey\lib\$pkg") {
                    Write-FPLog "package is installed"
                    $params = "uninstall $pkg $params"
                }
                else {
                    Write-FPLog "package is not installed (skip)"
                    break
                }
                Write-FPLog "command............... choco $params"
                if (-not $TestMode) {
                    $p = Start-Process -FilePath "choco.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru
                    if ($p.ExitCode -eq 0) {
                        Write-FPLog "removal was successful"
                    }
                    else {
                        Write-FPLog -Category 'Error' -Message "removal exit code: $($p.ExitCode)"
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
    Write-FPLog "--------- removal assignments: finish ---------"
}