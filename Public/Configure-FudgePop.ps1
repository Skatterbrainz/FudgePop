#requires -version 3
<#
#>

function Configure-FudgePop {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param ()
	$ControlFile = Get-FPConfiguration -Name "ControlFile" -Default $FPCFDefault
	$ScheduleHrs = Get-FPConfiguration -Name "ScheduleHours" -Default 1
	$EnableJob   = Get-FPConfiguration -Name "EnableJob" -Default 1

	Write-Host "Current control file is: $ControlFile" -ForegroundColor Cyan
	$newFile  = (Read-Host "  New control file or Enter to accept default")
	if ($newFile -eq "") {$newFile = $ControlFile}
	
	$newJob = (Read-Host "  Enable FudgePop to run on a recurring schedule? <Y>")
	if ($newJob -ne 'N') { $newJob = 1 } else { $newJob = 0 }
	
	if ($newJob -eq 1) {
		Write-Host "Current schedule interval (hours) is: $ScheduleHrs" -ForegroundColor Cyan
		$newHours = (Read-Host "  New schedule interval (1 to 12) or Enter to accept default")
		if ($newHours -eq "") {$newHours = $ScheduleHrs}
	}
	else {
		$newHours = 0
	}
	
	Set-FPConfiguration -Name "ControlFile" -Data $newFile | Out-Null
	Set-FPConfiguration -Name "EnableJob" -Data $newJob | Out-Null
	Set-FPConfiguration -Name "ScheduleHours" -Data $newHours | Out-Null
	
	if ($EnableJob -eq 1) {
		if (Get-ScheduledTask -TaskName "$FPRunJob" -ErrorAction SilentlyContinue) {
			# update task
		}
		else {
			# create task
		}
	}
	else {
		if (Get-ScheduledTask -TaskName "$FPRunJob" -ErrorAction SilentlyContinue) {
			# disable task
		}
		else {
			# do nothing
		}
	}
	Write-Host "Configuration has been updated" -ForegroundColor Green
}

Export-ModuleMember -Function Configure-FudgePop
