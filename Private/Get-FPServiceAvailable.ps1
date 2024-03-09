function Get-FPServiceAvailable {
	<#
	.SYNOPSIS
		Verify FudgePop Control Item is Enabled
	.DESCRIPTION
		Return TRUE if enabled="true" in control section of XML
	.PARAMETER DataSet
		XML data from control file import
	.INPUTS
		XML data
	.OUTPUTS
		$True or $null
	#>
	param (
		[parameter(Mandatory = $True)]
		$DataSet
	)
	if ($DataSet.configuration.control.enabled -eq 'true') {
		if (($DataSet.configuration.control.exclude -split ',') -contains $MyPC) {
			Write-FPLog 'FudgePop services are enabled, but this device is excluded'
			break
		} else {
			Write-FPLog 'FudgePop services are enabled for all devices'
			Write-Output $True
		}
	} else {
		Write-FPLog 'FudgePop services are currently disabled for all devices'
	}
}