function Get-FPDeviceCollections {
	<#
	.SYNOPSIS
		Get Device Collection Memberships
	.DESCRIPTION
		Get List of Collections this Device is a Member of
	.PARAMETER XmlData
		Control Data XML
	.EXAMPLE
		$colls = Get-FPDeviceCollections -ControlData $ControlData
	.NOTES
	#>
	param (
		[parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		$ControlData
	)
	try {
		$( $ControlData.configuration.collections.collection | Where-Object { $_.members -match $env:COMPUTERNAME }).name
	} catch {
		Write-Output ""
	}
}