function Remove-FPAppPackage {
	<#
	.SYNOPSIS
		Removes an application package using winget.
	.DESCRIPTION
		Removes an application package using winget.
	.PARAMETER PackageName
		Specifies the name of the application package to remove.
	.EXAMPLE
		Remove-FPAppPackage -PackageName "Movies & TV"
	#>
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