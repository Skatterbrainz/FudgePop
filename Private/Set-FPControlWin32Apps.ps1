function Set-FPControlWin32Apps {
	<#
	.SYNOPSIS
		Install Win32 Applications
	.DESCRIPTION
		Process Configuration Control: Windows Application Installs and Uninstalls
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlWin32Apps -DataSet $xmldata
	#>
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- win32 app assignments: begin ---------"
	foreach ($app in $DataSet) {
		$device     = $app.device
		$collection = $app.collection
		$appName    = $app.name
		$action     = $app.action
		$appPlat    = $app.platforms
		$appRun     = $app.run
		$appParams  = $app.params
		$runtime    = $app.when
		$enabled    = $app.enabled
		Write-FPLog "device................ $device"
		Write-FPLog "collection............ $collection"
		Write-FPLog "appname............... $appName"
		Write-FPLog "app run............... $appRun"
		Write-FPLog "action................ $action"
		Write-FPLog "platform.............. $appPlat"
		Write-FPLog "runtime............... $runtime"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		switch ($action) {
			'install' {
				if ($appRun.EndsWith('.msi')) {
					$proc = "msiexec.exe"
					$argx = "/i `"$appRun`" /q"
					if ($appParams -ne "") {
						$argx += " $appParams"
					}
				} elseif ($appRun.EndsWith('.exe')) {
					$proc = $appRun
					$argx = $appParams
				} else {
					Write-FPLog -Category "Error" -Message "invalid file type"
					break
				}
				Write-FPLog "process............... $proc"
				Write-FPLog "argx.................. $argx"
				Write-FPLog "contacting source to verify availability..."
				if (Test-Path $appRun) {
					if (-not $TestMode) {
						try {
							$p = Start-Process -FilePath $proc -ArgumentList $argx -NoNewWindow -Wait -PassThru
							if ((0, 3010) -contains $p.ExitCode) {
								Write-FPLog "result................ successful!"
							} else {
								Write-FPLog -Category "Error" -Message "installation failed with $($p.ExitCode)"
							}
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				} else {
					Write-FPLog "installer file is not accessible (skipping)"
				}
			}
			'uninstall' {
				$detect = $app.detect
				if (Test-FPDetectionRule -DataSet $DataSet -RuleName $detect) {
					Write-FPLog "ruletest = TRUE"
					if ($appRun.StartsWith('msiexec /x')) {
						$proc = "msiexec"
						$argx = ($appRun -replace ("msiexec", "")).trim()
						Write-FPLog "process............... $proc"
						Write-FPLog "argx.................. $argx"
						if (-not $TestMode) {
							try {
								$p = Start-Process -FilePath $proc -ArgumentList $argx -NoNewWindow -Wait -PassThru
								if ((0, 3010, 1605) -contains $p.ExitCode) {
									Write-FPLog "result................ uninstall was successful!"
								} else {
									Write-FPLog -Category "Error" -Message "uninstall failed with $($p.ExitCode)"
								}
							} catch {
								Write-FPLog -Category "Error" -Message $_.Exception.Message
							}
						} else {
							Write-FPLog "TESTMODE: Would have been applied"
						}
					}
				} else {
					Write-FPLog "ruletest = FALSE"
				}
			}
		} # switch
	} # foreach
	Write-FPLog "--------- win32 app assignments: finish ---------"
}