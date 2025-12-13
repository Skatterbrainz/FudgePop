function Install-FPPythonPackages {
	<#
	.SYNOPSIS
		Installs Python packages using pip.

	.DESCRIPTION
		This function installs Python packages specified in the input dataset using pip.

	.PARAMETER DataSet
		The dataset containing the list of Python packages to install.

	.EXAMPLE
		Install-FPPythonPackages -DataSet $pythonPackages

	.NOTES
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- python package installations: begin ---------"
	$package = $null
	foreach ($package in $DataSet) {
		$packageName = $package.name
		$enabled = $package.enabled
		Write-FPLog "package............... $packageName"
		if (-not $enabled) {
			Write-FPLog "skip: package installation is disabled"
			continue
		}
		try {
			if ($IsWindows) {
				$pyPath = (Get-Command py.exe -ErrorAction Stop)
			} else {
				$pyPath = (Get-Command python3 -ErrorAction Stop)
			}
			if ($pyPath) {
				Write-FPLog "using python executable at: $($pyPath.Path)"
				$pipArgs = "-m pip install $packageName"
				Write-FPLog "command............... $($pyPath.Path) $pipArgs"
				if (-not $TestMode) {
					$p = Start-Process -FilePath $pyPath.Path -NoNewWindow -ArgumentList $pipArgs -Wait -PassThru -ErrorAction Stop
					if ($p.ExitCode -eq 0) {
						Write-FPLog "installation was successful"
					} else {
						throw $p.ExitCode
					}
				} else {
					Write-FPLog "test mode: installation skipped"
				}
			} else {
				throw "python3 executable not found"
			}
		} catch {
			Write-FPLog "pip is not installed or not found in PATH"
			continue
		}
}