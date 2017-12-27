function Set-FPControlPackages {
    <#
    .SYNOPSIS
        Install Chocolatey Packages
    .DESCRIPTION
        Process Configuration Control: Chocolatey Package Installs and Upgrades
    .PARAMETER DataSet
        XML data from control file import
    .EXAMPLE
        Set-FPControlPackages -DataSet $xmldata
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog "--------- installation assignments: begin ---------"
    foreach ($package in $DataSet) {
        $deviceName = $package.device
        $collection = $package.collection
        $runtime    = $package.when
        $autoupdate = $package.autoupdate
        $username   = $package.user
        $extparams  = $package.params
        $update     = $package.update
        Write-FPLog "device................ $deviceName"
        Write-FPLog "collection............ $collection"
        Write-FPLog "user.................. $username"
        Write-FPLog "runtime............... $runtime"
        Write-FPLog "autoupdate............ $autoupdate"
        if (Test-FPControlRuntime -RunTime $runtime) {
            Write-FPLog "run: runtime is now or already passed"
            $pkglist = $package.InnerText -split ','
            if ($extparams.length -gt 0) { $params = $extparam } else { $params = ' -y -r' }
            foreach ($pkg in $pkglist) {
                Write-FPLog "package............... $pkg"
                if (Test-Path "$($env:PROGRAMDATA)\chocolatey\lib\$pkg") {
                    if ($update -eq 'true') {
                        Write-FPLog "package is already installed (upgrade)"
                        $params = "upgrade $pkg $params"
                    }
                    else {
                        Write-FPLog "package is already installed (no upgrade.. skip)"
                        break
                    }
                }
                else {
                    Write-FPLog "package is not installed (install)"
                    $params = "install $pkg $params"
                }
                Write-FPLog "command............... choco $params"
                if (-not $TestMode) {
                    $p = Start-Process -FilePath "choco.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru
                    if ($p.ExitCode -eq 0) {
                        Write-FPLog "result................ successful"
                    }
                    else {
                        Write-FPLog -Category 'Error' -Message "package exit code: $($p.ExitCode)"
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
    Write-FPLog "--------- installation assignments: finish ---------"
}