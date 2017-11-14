#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Display FudgePop configuration
.NOTES
	1.0.7 - 11/14/2017 - David Stein
.EXAMPLE
	Show-FudgePop -Verbose
#>

function Show-FudgePop {
	param ()
	Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
	Write-Host "version........... $FPVersion" -ForegroundColor Cyan
	Write-Host "registry path..... $FPRegRoot" -ForegroundColor Cyan
	Write-Host "default control... $FPCFDefault" -ForegroundColor Cyan
	Write-Host "log file path..... $FPLogFile"	 -ForegroundColor Cyan
	try {
		$reg = Get-ItemProperty -Path $Script:FPRegRoot -ErrorAction Stop
		$x1 = $reg.LastStartTime
		$x2 = $reg.InitialSetup
		$x3 = $reg.LastFinishTime
		$x4 = $reg.LastRunUpdates
		$x5 = $reg.ModuleVersion
		$x6 = $reg.EnableJob
		$x7 = $reg.ScheduleHours
		if ($x6 -eq 1) {
			Write-Host "schedule enabled.. yes" -ForegroundColor Cyan
			if (Get-ScheduledTask -TaskName $Script:FPRunJob -ErrorAction SilentlyContinue) {
				Write-Host "scheduled task.... $FPRunJob" -ForegroundColor Cyan
			}
			else {
				Write-Host "scheduled task.... not configured"
			}
			$ns = (Get-Date $x1).AddHours(3).ToString("M/d/yyyy HH:mm:ss")
			Write-Host "last start time... $x1" -ForegroundColor Cyan
			Write-Host "last finish time.. $x3" -ForegroundColor Cyan
			Write-Host "last updates run.. $x4" -ForegroundColor Cyan
			Write-Host "next start time... $ns" -ForegroundColor Cyan
		}
		else {
			Write-Host "schedule enabled.. no" -ForegroundColor Cyan
		}
	}
	catch {
		Write-Host "Run Install-FudgePop to configure options and enable service" -ForegroundColor Red
	}
}

Export-ModuleMember -Function Show-FudgePop