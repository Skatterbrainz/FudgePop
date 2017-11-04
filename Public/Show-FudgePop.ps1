#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Display FudgePop configuration
.NOTES
	1.0.5 - 11/03/2017 - David Stein
.EXAMPLE
	Show-FudgePop -Verbose
#>

function Show-FudgePop {
	param ()
	Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
	Write-Host "version........... $FPVersion" -ForegroundColor Cyan
	Write-Host "registry path..... $FPRegRoot" -ForegroundColor Cyan
	Write-Host "scheduled task.... $FPRunJob" -ForegroundColor Cyan
	Write-Host "default control... $FPCFDefault" -ForegroundColor Cyan
	Write-Host "log file path..... $FPLogFile"	 -ForegroundColor Cyan
}

Export-ModuleMember -Function Show-FudgePop
