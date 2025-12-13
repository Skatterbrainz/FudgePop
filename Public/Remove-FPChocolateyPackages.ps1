function Remove-FPChocolateyPackages {
	<#
	.SYNOPSIS
		Uninstall Chocolatey Packages
	.DESCRIPTION
		Uninstall Chocolatey Packages applicable to this computer
	.PARAMETER DataSet
		Control data
	.EXAMPLE
		Remove-FPChocolateyPackages -DataSet $controldata
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- chocolatey removal assignments: begin ---------"
	$paramext = "--yes"
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
				$params = "uninstall $pkg $paramext"
				Write-FPLog "command............... choco $params"
				if (-not $TestMode) {
					try {
						$p = Start-Process -FilePath "choco.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru -ErrorAction Stop
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
	Write-FPLog "--------- winget removal assignments: finish ---------"
}