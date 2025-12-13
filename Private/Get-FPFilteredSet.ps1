function Get-FPFilteredSet {
	<#
	.SYNOPSIS
		Return Targeted Control data set
	.DESCRIPTION
		Return Targeted Control data set for this device or associated collection
	.PARAMETER ControlData
		Control data set for specific control group (e.g. files, folders, etc.)
	.PARAMETER Collections
		Array of collection names
	.EXAMPLE
		$dataset = Get-FPFilteredSet -ControlData $ControlData.configuration.files.file -Collections (Get-FPDeviceCollections -ControlData $ControlData)
	#>
	param (
		[parameter(Mandatory = $True)]
		$ControlData,
		[parameter(Mandatory = $False)]
		$Collections
	)
	$thisDevice = $env:COMPUTERNAME
	if ($null -ne $Collections) {
		$result = $ControlData |
		Where-Object { $_.enabled -eq 'true' -and ($Collections.Contains($_.collection)) }
	} else {
		$result = $ControlData |
		Where-Object { $_.enabled -eq 'true' -and ($_.device -eq 'all' -or $_.device -eq $thisDevice) }
	}
	Write-Output $result
}