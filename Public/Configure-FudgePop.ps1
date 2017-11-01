#requires -version 3
#requires -RunAsAdministrator
<#
.SYNOPSIS
	Configure FudgePop options
.NOTES
	1.0.3 - 10/31/2017 - David Stein
#>

function Configure-FudgePop {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param ()
	
	Write-FPLog $Script:FPVersion
	Write-FPLog $Script:FPRegRoot
	Write-FPLog $Script:FPRunJob
	Write-FPLog $Script:FPCFDefault

	$ControlFile = Get-FPConfiguration -Name "ControlFile" -Default $FPCFDefault
	$ScheduleHrs = Get-FPConfiguration -Name "ScheduleHours" -Default 1
	$EnableJob   = Get-FPConfiguration -Name "EnableJob" -Default 1
	$RunJobName  = Get-FPConfiguration -Name "RunJobName" -Default $Script:FPRunJob

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
		#$filepath = "$(Split-Path((Get-Module FudgePop).Path))\Public\Invoke-FudgePop.ps1"
		$filepath = "$(Split-Path((Get-Module FudgePop).Path))\Public\RunFudgePop.bat"
		if (Test-Path $filepath) {
			Write-FPLog "operation: $filepath"
			Write-FPLog "cmd: SCHTASKS /Create /RU `"SYSTEM`" /SC hourly /MO $newHours /TN `"$RunJobName`" /TR `"$filepath`" /RL HIGHEST /F"
			#}
			try {
				SCHTASKS /Create /RU "SYSTEM" /SC hourly /MO $newHours /TN "$RunJobName" /TR "$filepath" /RL HIGHEST /F
				if (Get-ScheduledTask -TaskName $RunJobName -ErrorAction SilentlyContinue) {
					Write-FPLog -Category "Info" -Message "task has been updated successfully."
					Set-FPConfiguration -Name "ScheduledTaskName" -Data $RunJobName | Out-Null
					Write-Output $True
				}
				else {
					Write-FPLog -Category "Error" -Message "well, that sucked. no scheduled task update for you."
				}
			}
			catch {
				Write-FPLog -Category 'Error' -Message $_.Exception.Message
			}
		}
		else {
			Write-FPLog -Category 'Error' -Message "$filepath could not be found"
		}
	}
	else {
		if (Get-ScheduledTask -TaskName "$RunJobName" -ErrorAction SilentlyContinue) {
			try {
				Get-ScheduledTask -TaskName "$RunJobName" -ErrorAction SilentlyContinue |	
					Unregister-ScheduledTask -Confirm:$False -ErrorAction Stop
			}
			catch {
				Write-FPLog -Category 'Error' -Message $_.Exception.Message
				Write-Host 'FudgePop scheduled task could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
				break
			}
		}
		else {
			Write-FPLog -Category 'Info' -Message "uhhhhhhhh. There is no scheduled task named $RunJobName to disable. No biggie."
		}
	}
	Write-Host "Configuration has been updated" -ForegroundColor Green
}

Export-ModuleMember -Function Configure-FudgePop
