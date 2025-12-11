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
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- removal assignments: begin ---------"
	$paramext = "--accept-source-agreements --accept-package-agreements --silent"
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
			$pkglist = $package.InnerText -split ','
			#if ($extparams.length -gt 0) { $params = $extparam } else { $params = ' -y -r' }
			foreach ($pkg in $pkglist) {
				Write-FPLog "package............... $pkg"
				if (Get-WinGetPackage -Name $pkg -ErrorAction SilentlyContinue) {
					Write-FPLog "package is installed"
					$params = "uninstall $pkg $paramext"
				} else {
					Write-FPLog "package is not installed (skip)"
					continue
				}
				Write-FPLog "command............... winget $params"
				if (-not $TestMode) {
					try {
						$p = Start-Process -FilePath "winget.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru -ErrorAction Stop
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
	Write-FPLog "--------- removal assignments: finish ---------"
}