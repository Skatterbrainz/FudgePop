function Test-FPControlSource {
	<#
	.SYNOPSIS
		Validate File or URI is accessible
	.DESCRIPTION
		Verifies Control XML file is accessible
	.PARAMETER Path
		Full Path or URI to file
	.INPUTS
		Path to file
	.OUTPUTS
		$True or $null
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Path
	)
	if ($Path.StartsWith('http')) {
		Write-FPLog "verifying URI resource: $Path"
		try {
			$test = Invoke-WebRequest -UseBasicParsing -Uri $Path -Method Get -ErrorAction SilentlyContinue
			if ($test) {
				Write-Output ($test.StatusCode -eq 200)
			}
		} catch {}
	} else {
		Write-FPLog "verifying file system resource: $Path"
		Write-Output (Test-Path $Path)
	}
}
