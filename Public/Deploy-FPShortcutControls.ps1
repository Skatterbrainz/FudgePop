function Deploy-FPShortcutControls {
	<#
	.SYNOPSIS
		Process Shortcut Controls
	.DESCRIPTION
		Process Configuration Control: File and URL Shortcuts
	.PARAMETER DataSet
		Control data from control file import
	.EXAMPLE
		Deploy-FPShortcutControls -DataSet $controldata
	#>
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- shortcut assignments: begin ---------"
	foreach ($sc in $DataSet) {
		$scDevice   = $sc.device
		$collection = $sc.collection
		$scName     = $sc.name
		$scAction   = $sc.action
		$scTarget   = $sc.target
		$scPath     = $sc.path
		$scType     = $sc.type
		$scForce    = $sc.force
		$scDesc     = $sc.description
		$scArgs     = $sc.args
		$scWindow   = $sc.windowstyle
		$scWorkPath = $sc.workingpath
		$enabled    = $sc.enabled
		Write-FPLog "device................ $scDevice"
		Write-FPLog "collection............ $collection"
		Write-FPLog "shortcut name......... $scName"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		try {
			if (-not (Test-Path $scPath)) {
				$scRealPath = [environment]::GetFolderPath($scPath)
			} else {
				$scRealPath = $scPath
			}
		} catch {
			$scRealPath = $null
		}
		if ($scRealPath) {
			Write-FPLog "shortcut action....... $scAction"
			switch ($scAction) {
				'create' {
					if ($scWindow.length -gt 0) {
						switch ($scWindow) {
							'normal' { $scWin = 1; break; }
							'max' { $scWin = 3; break; }
							'min' { $scWin = 7; break; }
						}
					} else {
						$scWin = 1
					}
					Write-FPLog "device................ $scDevice"
					Write-FPLog "shortcut path......... $scPath ($scRealPath)"
					Write-FPLog "shortcut target....... $scTarget"
					Write-FPLog "shortcut descrip...... $scDesc"
					Write-FPLog "shortcut args......... $scArgs"
					Write-FPLog "shortcut workpath..... $scWorkPath"
					Write-FPLog "shortcut window....... $scWindow"
					Write-FPLog "device name........... $scDevice"
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FPLog "full linkpath......... $scFullName"
					if ($scForce -eq 'true' -or (-not(Test-Path $scFullName))) {
						Write-FPLog "creating new shortcut"
						try {
							if (-not $TestMode) {
								$wShell   = New-Object -ComObject WScript.Shell
								$shortcut = $wShell.CreateShortcut("$scFullName")
								$shortcut.TargetPath = $scTarget
								if ($scType -eq 'lnk') {
									if ($scArgs -ne "") { $shortcut.Arguments = "$scArgs" }
									#$shortcut.HotKey       = ""
									if ($scWorkPath -ne "") { $shortcut.WorkingDirectory = "$scWorkPath" }
									$shortcut.WindowStyle = $scWin
									$shortcut.Description = $scName
								}
								#$shortcut.IconLocation = $scFullName
								$shortcut.Save()
							} else {
								Write-FPLog "TEST MODE: $scFullName"
							}
						} catch {
							Write-FPLog -Category "Error" -Message "failed to create shortcut: $($_.Exception.Message)"
						}
					} else {
						Write-FPLog "shortcut already created - no updates"
					}
				}
				'delete' {
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FPLog "shortcut path......... $scPath"
					Write-FPLog "device name........... $scDevice"
					Write-FPLog "full linkpath......... $scFullName"
					if (Test-Path $scFullName) {
						Write-FPLog "deleting shortcut"
						try {
							if (-not $TestMode) {
								Remove-Item -Path $scFullName -Force | Out-Null
							} else {
								Write-FPLog "TEST MODE: $scFullName"
							}
						} catch {
							Write-FPLog -Category 'Error' -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "shortcut not found: $scFullName"
					}
				}
			} # switch
		} else {
			Write-FPLog -Category "Error" -Message "failed to convert path key"
		}
	} # foreach
	Write-FPLog "--------- shortcut assignments: finish ---------"
}