function Test-FPControlRuntime {
	<#
	.SYNOPSIS
		Confirm Task Execution Time
	.DESCRIPTION
		Return TRUE if a task runtime is active
	.PARAMETER RunTime
		Date Value, or 'now' or 'daily'
	.PARAMETER Key
		Label to map to Registry for get/set operations
	.EXAMPLE
		Test-FPControlRuntime -RunTime "now"
	.EXAMPLE
		Test-FPControlRuntime -RunTime "11/12/2017 10:05:00 PM"
	.EXAMPLE
		Test-FPControlRuntime -RunTime "daily" -Key "TestValue"
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $RunTime,
		[parameter(Mandatory = $False)][string] $Key = ""
	)
	switch ($RunTime) {
		'now' { Write-Output $True; break }
		'daily' {
			$lastrun = Get-FPConfiguration -Name "$Key" -Default ""
			if ($lastrun -ne "") {
				$prevDate = $(Get-Date($lastrun)).ToShortDateString()
				Write-FPLog "previous run: $prevDate"
				if ($prevDate -ne (Get-Date).ToShortDateString()) {
					Write-FPLog "$prevDate is not today: $((Get-Date).ToShortDateString())"
					Write-Output $True
				}
			} else {
				Write-FPLog "no previous run"
				Write-Output $True
			}
			break
		}
		default {
			Write-FPLog "checking explicit runtime"
			if ((Get-Date).ToLocalTime() -ge $RunTime) {
				Write-Output $True
			}
		}
	} # switch
}