function Install-FudgePop {
	<#
	.SYNOPSIS
		Configure FudgePop options and Scheduled Task
	.DESCRIPTION
		Configures FudgePop options, including source control XML file path,
		and Scheduled Task options.
	.PARAMETER UseDefaults
		Applies default settings and initializes the
		scheduled client task at a 1 hour interval.  The default control XML
		file path is the URI to the control.xml on the project Github site.
	.EXAMPLE
		Install-FudgePop -UseDefaults
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $False, HelpMessage="Automatic configuration with default settings")]
		[switch] $UseDefaults
	)
	$ModuleData = Get-Module FudgePop
	$ModuleVer  = $ModuleData.Version -join '.'

	Write-Host "FudgePop $ModuleVer - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
	Install-Chocolatey
	Write-FPLog $ModuleVer
	Write-FPLog $Script:FPRegRoot
	Write-FPLog $Script:FPRunJob
	Write-FPLog $Script:FPCFDefault
	$ControlFile = Get-FPConfiguration -Name "ControlFile" -Default $FPCFDefault
	$ScheduleHrs = Get-FPConfiguration -Name "ScheduleHours" -Default 1
	$EnableJob   = Get-FPConfiguration -Name "EnableJob" -Default 1
	$RunJobName  = Get-FPConfiguration -Name "RunJobName" -Default $Script:FPRunJob
	if ($UseDefaults) {
		$newFile  = $ControlFile
		$newJob   = 1
		$newHours = 1
		Write-FPLog 'Applying default settings and configuring scheduled task'
		if (!(Test-FPControlSource $newFile)) {
			Write-FPLog -Category 'Error' -Message 'Failed to validate control file location!'
			break
		}
		Write-FPLog 'control file location has been validated'
		Set-FPConfiguration -Name "ControlFile" -Data $newFile | Out-Null
		Set-FPConfiguration -Name "EnableJob" -Data $newJob | Out-Null
		Set-FPConfiguration -Name "ScheduleHours" -Data $newHours | Out-Null
	} else {
		Write-Host "Current control file is: $ControlFile" -ForegroundColor Cyan
		$newFile = (Read-Host "  New control file or Enter to accept default")
		if ($newFile -eq "") {$newFile = $ControlFile}
		$newJob = (Read-Host "  Enable FudgePop to run on a recurring schedule? <Y>")
		if ($newJob -ne 'N') {
			$newJob    = 1
			$EnableJob = 1
		} else {
			$newJob    = 0
			$EnableJob = $null
		}
		if ($newJob -eq 1) {
			Write-Host "Current schedule interval (hours) is: $ScheduleHrs" -ForegroundColor Cyan
			$newHours = (Read-Host "  New schedule interval (1 to 12) or Enter to accept default")
			if ($newHours -eq "") {$newHours = $ScheduleHrs}
		} else {
			$newHours = 0
		}
		if (!(Test-FPControlSource $newFile)) {
			Write-FPLog -Category 'Error' -Message 'Failed to validate control file location!'
			break
		}
		Write-FPLog 'control file location has been validated'
		Set-FPConfiguration -Name "ControlFile" -Data $newFile | Out-Null
		Set-FPConfiguration -Name "EnableJob" -Data $newJob | Out-Null
		Set-FPConfiguration -Name "ScheduleHours" -Data $newHours | Out-Null
	}
	if ($EnableJob -eq 1) {
		#$filepath = "$(Split-Path((Get-Module FudgePop).Path))\Public\Invoke-FudgePop.ps1"
		$filepath = "$(Split-Path((Get-Module FudgePop).Path))\Public\RunFudgePop.bat"
		if (Test-Path $filepath) {
			Write-FPLog "operation: $filepath"
			Write-FPLog "cmd: SCHTASKS /Create /RU `"SYSTEM`" /SC hourly /MO $newHours /TN `"$RunJobName`" /TR `"$filepath`" /RL HIGHEST /F"
			try {
				SCHTASKS /Create /RU "SYSTEM" /SC hourly /MO $newHours /TN "$RunJobName" /TR "$filepath" /RL HIGHEST /F
				if (Get-ScheduledTask -TaskName $RunJobName -ErrorAction SilentlyContinue) {
					Write-FPLog "task has been updated successfully."
					Set-FPConfiguration -Name "ScheduledTaskName" -Data $RunJobName | Out-Null
					Write-Output $True
				} else {
					Write-FPLog -Category "Error" -Message "well, that sucked. no scheduled task update for you."
				}
			} catch {
				Write-FPLog -Category 'Error' -Message $_.Exception.Message
			}
		} else {
			Write-FPLog -Category 'Error' -Message "$filepath could not be found"
		}
	} else {
		if (Get-ScheduledTask -TaskName "$RunJobName" -ErrorAction SilentlyContinue) {
			try {
				Get-ScheduledTask -TaskName "$RunJobName" -ErrorAction SilentlyContinue |
					Unregister-ScheduledTask -Confirm:$False -ErrorAction Stop
			} catch {
				Write-FPLog -Category 'Error' -Message $_.Exception.Message
				Write-Host 'FudgePop scheduled task could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
			}
		} else {
			Write-FPLog "uhhhhhhhh. There is no scheduled task named $RunJobName to disable. No biggie."
		}
	}
	Write-Host "Configuration has been updated" -ForegroundColor Green
}
