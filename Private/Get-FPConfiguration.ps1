function Get-FPConfiguration {
	<#
	.SYNOPSIS
		Import Control Data from Registry
	.DESCRIPTION
		Fetch data from Registry or return Default if none found
	.PARAMETER RegPath
		Registry Path (default is HKLM:\SOFTWARE\FudgePop)
	.PARAMETER Name
		Registry Value name
	.PARAMETER Default
		Data to return if no value found in registry
	.INPUTS
		Registry Key, Value Name, Default Value (if not found in registry)
	.OUTPUTS
		Information returned from registry (or default value)
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $False)][ValidateNotNullOrEmpty()][string] $RegPath = $FPRegRoot,
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Name,
		[parameter(Mandatory = $False)][string] $Default = ""
	)
	if (Test-Path $RegPath) {
		Write-Verbose "registry path confirmed: $RegPath ($Name)"
		try {
			$result = Get-ItemProperty -Path $RegPath -ErrorAction Stop |
			Select-Object -ExpandProperty $Name -ErrorAction Stop
			if ($null -eq $result -or $result -eq "") {
				Write-Verbose "no data returned from query. using default: $Default"
				$result = $Default
			}
		} catch {
			Write-Verbose "error: returning $Default"
			$result = $Default
		}
	} else {
		Write-Verbose "registry path does not yet exist: $RegPath"
		$result = $Default
	}
	Write-Output $result
}
