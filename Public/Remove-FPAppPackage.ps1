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
		$p = Start-Process -FilePath "winget.exe" -NoNewWindow -ArgumentList "uninstall --name `"$PackageName`" --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru -ErrorAction Stop
		if ($p.ExitCode -eq 0) {
			$result = [pscustomobject]@{
				"PackageName" = $PackageName
				"Result"      = "Uninstalled"
			}
		} elseif ($p.ExitCode -eq 3010) {
			$result = [pscustomobject]@{
				"PackageName" = $PackageName
				"Result"      = "Uninstalled"
				"Message"     = "Reboot required"
			}
		} elseif ($p.ExitCode -eq 1605) {
			$result = [pscustomobject]@{
				"PackageName" = $PackageName
				"Result"      = "Warning"
				"Message"     = "Package not found"
			}
		} else {
			$result = [pscustomobject]@{
				"PackageName" = $PackageName
				"Result"      = "Failed"
				"Message"     = "Exit code: $($p.ExitCode)"
			}
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