function Install-FPLinuxUpdates {
	<#
	.SYNOPSIS
		Install Linux Updates
	.DESCRIPTION
		Process Configuration Control: Linux System Updates
	.PARAMETER DataSet
		Control data from control file import
	.EXAMPLE
		Install-FPLinuxUpdates -DataSet $configdata
	#>
	[CmdletBinding()]
 	param (
 		[parameter(Mandatory = $True)]$DataSet
 	)
	Write-FPLog "--------- linux updates assignments: begin ---------"
	foreach ($package in $DataSet) {
		$deviceName = $package.device
		$collection = $package.collection
		$runtime    = $package.when
		$username   = $package.user
		$enabled    = $package.enabled
		Write-FPLog "device................ $deviceName"
		Write-FPLog "collection............ $collection"
		Write-FPLog "user.................. $username"
		Write-FPLog "runtime............... $runtime"
		if (-not $enabled) {
			Write-FPLog "skip: assignment disabled"
			continue
		} else {
			if (Test-FPControlRuntime -RunTime $runtime) {
				Write-FPLog "run: runtime is now or already passed"
				$params = ("update", "&&", "sudo", "apt", "upgrade", "-y")
				Write-FPLog "command............... sudo apt $($params -join ' ')"
				if (-not $TestMode) {
					try {
						$p = Start-Process -FilePath "apt" -NoNewWindow -ArgumentList $params -Wait -PassThru -ErrorAction Stop
						if ($p.ExitCode -eq 0) {
							Write-FPLog "result................ successful"
						} else {
							Write-FPLog -Category 'Error' -Message "update exit code: $($p.ExitCode)"
						}
					} catch {
						Write-FPLog -Category 'Error' -Message "Failed to install updates"
					}
				} else {
					Write-FPLog "TESTMODE: Would have been applied"
				}
			} else {
				Write-FPLog "skip: not yet time to run this assignment"
			}
		}
	} # foreach
	Write-FPLog "--------- linux updates assignments: finish ---------"
}