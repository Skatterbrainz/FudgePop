#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Removes FudgePop configuration items from the local computer
.NOTES
	1.0.5 - 11/03/2017 - David Stein
.EXAMPLE
	Remove-FudgePop -Verbose -WhatIf
#>

function Remove-FudgePop {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param ()
	Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
	try {
		Get-ScheduledTask -TaskName "$FPRunJob" -ErrorAction SilentlyContinue |	
			Unregister-ScheduledTask -Confirm:$False -ErrorAction Stop
	}
	catch {
		Write-FPLog -Category 'Error' -Message $_.Exception.Message
		Write-Host 'FudgePop scheduled task could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
		break
	}
	if (Test-Path $FPRegRoot) {
		try {
			Remove-Item -Path $FPRegRoot -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
		}
		catch {
			Write-FPLog -Category 'Error' -Message $_.Exception.Message
			Write-Host 'FudgePop registry items could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
			break
		}
	}
	Write-FPLog 'FudgePop has been disabled on this computer'
	Write-Host 'FudgePop has been disabled on this computer' -ForegroundColor Green
}

Export-ModuleMember -Function Remove-FudgePop
