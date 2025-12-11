function Get-FPControlJSON {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True, HelpMessage = "Path or URI to JSON control file")]
		[ValidateNotNullOrEmpty()]
		[string] $FilePath
	)
	Write-FPLog "preparing to import control file: $FilePath"
	if ($FilePath.StartsWith("http")) {
		try {
			$result = ((New-Object System.Net.WebClient).DownloadString($FilePath) | ConvertFrom-Json)
		} catch {
			Write-FPLog -Category 'Error' -Message "failed to import data from Uri: $FilePath"
			Write-Output -3
			break;
		}
		Write-FPLog 'control data loaded successfully'
	} else {
		if (Test-Path $FilePath) {
			try {
				$result = (Get-Content -Path $FilePath | ConvertFrom-Json)
			} catch {
				Write-FPLog -Category 'Error' -Message "unable to import control file: $FilePath"
				Write-Output -4
				break;
			}
		} else {
			Write-FPLog -Category 'Error' -Message "unable to locate control file: $FilePath"
			Write-Output -5
			break;
		}
	}
	Write-Output $result
}