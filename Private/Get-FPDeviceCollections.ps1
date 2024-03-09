function Get-FPDeviceCollections {
	<#
	.SYNOPSIS
		Get Device Collection Memberships
	.DESCRIPTION
		Get List of Collections this Device is a Member of
	.PARAMETER XmlData
		Control Data XML
	.EXAMPLE
		$colls = Get-FPDeviceCollections -XmlData $ControlData
	.NOTES
	#>
	param (
		[parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		$XmlData
	)
	try {
		$( $XmlData.configuration.collections.collection | Where-Object { $_.members -match $env:COMPUTERNAME }).name
	} catch {
		Write-Output ""
	}
}