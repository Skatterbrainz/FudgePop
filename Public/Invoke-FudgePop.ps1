#requires -version 3
#requires -RunAsAdministrator
<#
.SYNOPSIS
	Runs FudgePop
.DESCRIPTION
	Invokes the FudgePop client process. If Install-FudgePop has not yet been
	executed, you will be prompted to do that first, in order to configure the
	options required to support FudgePop
.PARAMETER TestMode
	[switch][optional] Force WhatIf and Verbose output
.NOTES
	1.0.5 - 11/03/2017 - David Stein
.EXAMPLE
	Invoke-FudgePop
.EXAMPLE
	Invoke-FudgePop -TestMode
.EXAMPLE
	Invoke-FudgePop -Verbose
#>

function Invoke-FudgePop {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$False)]
			[switch] $TestMode
	)
	Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
	$ControlFile = Get-FPConfiguration -Name "ControlFile" -Default ""
	if ($ControlFile -eq "") {
		Write-FPLog -Category 'Warning' -Message 'FudgePop has not been configured yet. Run Install-FudgePop to set default options.'
		Write-Warning 'FudgePop has not been configured yet. Run Install-FudgePop to set default options.'
		break
	}
	else {
		$ControlData = Get-FPControlData -FilePath $ControlFile
		if (Get-FPServiceAvailable -DataSet $ControlData) {
			Write-Verbose "FudgePop is active."
			Set-FPConfiguration -Name "LastStartTime" -Data (Get-Date) | Out-Null
			Invoke-FPControls -DataSet $ControlData
			Set-FPConfiguration -Name "LastFinishTime" -Data (Get-Date) | Out-Null
			Set-FPConfiguration -Name "LastRunUser" -Data $env:USERNAME | Out-Null
		}
		else {
			Write-Verbose "FudgePop is not currently active."
		}
	}
}

Export-ModuleMember -Function Invoke-FudgePop
