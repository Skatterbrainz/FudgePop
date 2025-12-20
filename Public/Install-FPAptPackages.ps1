function Install-FPAptPackages {
	<#
	.SYNOPSIS
		Install APT Packages
	.DESCRIPTION
		Process Configuration Control: APT Package Installs and Upgrades
	.PARAMETER DataSet
		Control data from control file import
	.EXAMPLE
		Install-FPAptPackages -DataSet $configdata
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- apt installation assignments: begin ---------"
	$itemcount = $DataSet.count
	$paramext = "-y"
	foreach ($package in $DataSet) {
		$deviceName = $package.device
		$collection = $package.collection
		$runtime    = $package.when
		$username   = $package.user
		$update     = $package.update
		$enabled    = $package.enabled
		Write-FPLog "device................ $deviceName"
		Write-FPLog "collection............ $collection"
		Write-FPLog "user.................. $username"
		Write-FPLog "runtime............... $runtime"
		Write-FPLog "autoupdate............ $update"
		if (-not $enabled) {
			Write-FPLog "skip: assignment disabled"
			continue
		}
		if (Test-FPControlRuntime -RunTime $runtime) {
			Write-FPLog "run: runtime is now or already passed"
			$pkglist = $package.packages -split ','
			Write-FPLog "packages assigned..... $($pkglist.count)"
			foreach ($pkg in $pkglist) {
				Write-FPLog "package............... $pkg"
				$params = ("install", $pkg, $paramext)
				Write-FPLog "command............... sudo apt $($params -join ' ')"
				if (-not $TestMode) {
					if ($params -ne "") {
						try {
							$p = Start-Process -FilePath "apt" -NoNewWindow -ArgumentList $params -Wait -PassThru -ErrorAction Stop
							if ($p.ExitCode -eq 0) {
								Write-FPLog "result................ successful"
							} else {
								Write-FPLog -Category 'Error' -Message "package exit code: $($p.ExitCode)"
							}
						} catch {
							Write-FPLog -Category 'Error' -Message "Failed to install package $pkg"
						}
					}
				} else {
					Write-FPLog "TESTMODE: Would have been applied"
				}
			} # foreach
		} else {
			Write-FPLog "skip: not yet time to run this assignment"
		}
	} # foreach
	if ($itemcount -eq 0) {
		Write-FPLog "no assignments found"
	}
	Write-FPLog "--------- apt installation assignments: finish ---------"
}