function Install-FPPowerShellModules {
	<#
	.SYNOPSIS
	Install PowerShell Modules
	.DESCRIPTION
	Install Specified PowerShell Modules
	.PARAMETER DataSet
	Control data from control file import
	.EXAMPLE
	Install-FPPowerShellModules -DataSet $controldata
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $True, HelpMessage = "Control data from control file import")]
		[ValidateNotNullOrEmpty()]$DataSet
	)
	Write-FPLog "--------- mdodule assignments: begin ---------"
	foreach ($module in $DataSet) {
		$device     = $module.device
		$collection = $module.collection
		$modname    = $module.name
		$modver     = $module.version
		$runtime    = $module.when
		$comment    = $module.comment
		$enabled    = $module.enabled
		Write-FPLog "device................ $device"
		Write-FPLog "collection............ $collection"
		Write-FPLog "module................ $modname"
		Write-FPLog "version............... $modver"
		Write-FPLog "runtime............... $runtime"
		Write-FPLog "comment............... $comment"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		if (Test-FPControlRuntime -RunTime $runtime) {
			Write-FPLog "Runtime is now or overdue"
			if ($m = Get-Module -Name $modname -ListAvailable) {
				$lv = $m.Version -join '.'
				Write-FPLog "Module version $lv is already installed"
				if ($r = Find-Module -Name $modname) {
					$rv = $r.Version -join '.'
					if ($modver -eq 'latest') {
						Write-FPLog 'Latest version is requested via control policy.'
						if ($lv -lt $rv) {
							try {
								Write-FPLog "Updating module to $rv"
								Update-Module -Name $modname -Force -ErrorAction Stop
							} catch {
								Write-FPLog $_.Exception.Message -Category Error
							}
						} else {
							Write-FPLog "Local version is the latest. No update required."
						}
					} else {
						Write-FPLog 'Specific version is requested via control policy.'
						if ($lv -lt $modver) {
							try {
								Write-FPLog "Updating module to $modver"
								Update-Module -Name $modname -RequiredVersion $modver -ErrorAction Stop
							} catch {
								Write-FPLog -Category 'Error' -Message $_.Exception.Message
								break
							}
						} else {
							Write-FPLog "Local version is the latest. No update required."
						}
					}
				}
			} else {
				Write-FPLog "Module is not installed. Installing it now."
				try {
					if (!($TestMode)) {
						Install-Module -Name $modname -Force -ErrorAction Stop
						Write-FPLog "Module has been installed successfully."
					} else {
						Write-FPLog "TESTMODE: Would have been installed"
					}
				} catch {
					Write-FPLog -Category 'Error' -Message "Installation failed: "+$_.Exception.Message
				}
			}
		} else {
			Write-FPLog 'skip: not yet time to run this assignment'
		}
	} # foreach
	Write-FPLog '--------- module assignments: finish ---------'
}