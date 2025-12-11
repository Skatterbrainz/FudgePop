function Install-Chocolatey {
	<#
	.SYNOPSIS
		Insure Chocolatey is installed
	.DESCRIPTION
		Check if Chocolatey is installed.  If not, then install it.
	.EXAMPLE
		Install-Chocolatey
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $false)][string]$SourceURL = "https://chocolatey.org/install.ps1"
	)
	Write-FPLog -Category Info -Message "verifying chocolatey is installed"
	if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
		Write-FPLog -Category Info -Message "installing chocolatey..."
		try {
			Invoke-Expression (Invoke-WebRequest -Uri $SourceURL -UseBasicParsing -ErrorAction Stop)
		} catch {
			Write-FPLog -Category Error -Message $_.Exception.Message
		}
	} else {
		Write-FPLog -Category Info -Message "chocolatey is already installed"
	}
}