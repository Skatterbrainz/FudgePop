function Remove-FPAptPackages {
	<#
	.SYNOPSIS
		Uninstall APT Packages
	.DESCRIPTION
		Uninstall APT Packages applicable to this computer
	.PARAMETER DataSet
		Control data
	.EXAMPLE
		Remove-FPAptPackages -DataSet $controldata
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- apt removal assignments: begin ---------"
	$paramext = "--assume-yes --quiet"
	$package = $null
	$pkglist = $null
	$pkg     = $null
	foreach ($package in $DataSet) {
		$deviceName = $package.device
		$collection = $package.collection
		$runtime    = $package.when
		$autoupdate = $package.autoupdate
		$username   = $package.user
		$enabled    = $package.enabled
		#$extparams  = $package.params
		Write-FPLog "device................ $deviceName"
		Write-FPLog "collection............ $collection"
		Write-FPLog "user.................. $username"
		Write-FPLog "autoupdate............ $autoupdate"
		Write-FPLog "runtime............... $runtime"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		if (Test-FPControlRuntime -RunTime $runtime) {
			Write-FPLog "run: runtime is now or already passed"
			$pkglist = $package.packages -split ','
			Write-FPLog "packages.............. $($pkglist.Count)"
			foreach ($pkg in $pkglist) {
				Write-FPLog "package............... $pkg"
				$params = ("remove", $pkg, $paramext)
				Write-FPLog "command............... apt $($params -join ' ')"
				if (-not $TestMode) {
					try {
						$p = Start-Process -FilePath "apt" -NoNewWindow -ArgumentList "$params" -Wait -PassThru -ErrorAction Stop
						if ($p.ExitCode -eq 0) {
							Write-FPLog "removal was successful"
						} else {
							throw $p.ExitCode
						}
					} catch {
						Write-FPLog -Category 'Error' -Message "removal failed: $($_.Exception.Message)"
					}
				} else {
					Write-FPLog "TESTMODE: Would have been applied"
				}
			} # foreach
		} else {
			Write-FPLog "skip: not yet time to run this assignment"
		}
	} # foreach
	Write-FPLog "--------- apt removal assignments: finish ---------"
}