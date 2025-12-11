function Remove-FPAppPackage {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)][string]$PackageName
	)
	try {
		Write-Verbose "Removing: $PackageName"
		winget uninstall --name "$PackageName" --silent --accept-source-agreements --accept-package-agreements
		$result = [pscustomobject]@{
			"PackageName" = $PackageName
			"Result"      = "Uninstalled"
		}
	} catch {
		$result = [pscustomobject]@{
			"PackageName" = $PackageName
			"Result"      = "Failed"
			"Message"     = $_.Exception.Message
		}
	} finally {
		Write-Output $result
	}
}