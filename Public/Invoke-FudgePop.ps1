#requires -version 3

function Invoke-FudgePop {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$False)]
			[switch] $TestMode
	)
	$ControlFile = Get-FPConfiguration -Name "ControlFile" -Default ""
	if ($ControlFile -eq "") {
		Write-FPLog -Category 'Warning' -Message 'FudgePop has not been configured yet. Run Configure-FudgePop to set default options.'
		Write-Warning 'FudgePop has not been configured yet. Run Configure-FudgePop to set default options.'
		break
	}
	else {
		$ControlData = Get-FPControlData -FilePath $ControlFile
		if (Get-FPServiceAvailable -DataSet $ControlData) {
			Write-Verbose "FudgePop is active."
			Set-FPConfiguration -Name "LastStartTime" -Data (Get-Date)
			Invoke-FPControls -DataSet $ControlData
			Set-FPConfiguration -Name "LastFinishTime" -Data (Get-Date)
			Set-FPConfiguration -Name "LastRunUser" -Data $env:USERNAME
		}
		else {
			Write-Verbose "FudgePop is not currently active."
		}
	}
}

Export-ModuleMember -Function Invoke-FudgePop
