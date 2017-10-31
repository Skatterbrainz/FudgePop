<#
.SYNOPSIS
	Private functions for running FudgePop
.NOTES
	1.0.0 - 10/30/2017 - David Stein
#>

$FPRegPath  = "HKLM:\SOFTWARE\FudgePop"
$FPLogFile  = "$($env:TEMP)\fudgepop.log"

<#
.SYNOPSIS
	Yet another custom log writing function, like all the others
.PARAMETER Category
	[string] [required] One of 'Info', 'Warning', or 'Error'
.PARAMETER Message
	[string] [required] Message text to enter into log file
#>

function Write-FudgePopLog {
	param (
		[parameter(Mandatory=$True)]
			[ValidateSet('Info','Warning','Error')]
			[string] $Category,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Message
	)
	Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
	"$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | 
		Out-File -FilePath $FPLogFile -Append -NoClobber -Encoding Default
}

<#
.SYNOPSIS
	Makes sure Chocolatey is installed and kept up to date
#>

function Assert-Chocolatey {
	param ()
	Write-FudgePopLog -Category "Info" -Message "verifying chocolatey installation"
	if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
		try {
			Write-FudgePopLog -Category "Info" -Message "installing chocolatey"
			iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		}
		catch {
			Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
			break
		}
	}
	else {
		Write-FudgePopLog -Category "Info" -Message "checking for newer version of chocolatey"
		choco upgrade chocolatey -y
	}
}

<#
.SYNOPSIS
	Imports the XML data from the XML control file
.PARAMETER FilePath
	Path or URI to the control XML file
#>

function Get-FPControlData {
	param (
		[parameter(Mandatory=$True, HelpMessage="Path or URI to XML control file")]
		[ValidateNotNullOrEmpty()]
		[string] $FilePath
	)
	Write-FudgePopLog -Category "Info" -Message "preparing to import control file: $FilePath"
	if ($FilePath.StartsWith("http")) {
		try {
			[xml]$result = Invoke-RestMethod -Uri $FilePath -UseBasicParsing
		}
		catch {
			Write-FudgePopLog -Category "Error" -Message "failed to import data from Uri: $FilePath"
			Write-Output -3
			break;
		}
	}
	else {
		if (Test-Path $FilePath) {
			try {
				[xml]$result = Get-Content -Path $FilePath
			}
			catch {
				Write-FudgePopLog -Category "Error" -Message "unable to import control file: $FilePath"
				Write-Output -4
				break;
			}
		}
		else {
			Write-FudgePopLog -Category "Error" -Message "unable to locate control file: $FilePath"
			Write-Output -5
			break;
		}
	}
	Write-Output $result
}

<#
.SYNOPSIS
	Execute CHOCOLATEY INSTALLATION AND UPGRADE directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPChocoInstalls {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- installaation assignments ---------"
	if ($DataSet) {
		$deviceName = $DataSet.device
		$runtime    = $DataSet.when
		$autoupdate = $DataSet.autoupdate
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePopLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePopLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePopLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $DataSet.InnerText -split ','
			foreach ($pkg in $pkglist) {
				if ($extparams.length -gt 0) {
					Write-FudgePopLog -Category "Info" -Message "package: $pkg (params: $extparams)"
					if (-not $TestMode) {
						choco upgrade $pkg $extparams
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE : choco upgrade $pkg $extparams"
					}
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco upgrade $pkg -y
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE: choco upgrade $pkg -y"
					}
				}
			} # foreach
		}
		else {
			Write-FudgePopLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	}
	else {
		Write-FudgePopLog -Category "Info" -Message "NO installations have been assigned to this computer"
	}
}

<#
.SYNOPSIS
	Execute CHOCOLATEY REMOVALS directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPChocoRemovals {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- removal assignments ---------"
	if ($DataSet) {
		$deviceName = $DataSet.device
		$runtime    = $DataSet.when
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePopLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePopLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePopLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $DataSet.InnerText -split ','
			foreach ($pkg in $pkglist) {
				if ($extparams.length -gt 0) {
					Write-FudgePopLog -Category "Info" -Message "package: $pkg (params: $extparams)"
					if (-not $TestMode) {
						choco uninstall $pkg $extparams
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE : choco uninstall $pkg $extparams"
					}
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco uninstall $pkg -y -r
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE : choco uninstall $pkg -y -r"
					}
				}
			} # foreach
		}
		else {
			Write-FudgePopLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	}
	else {
		Write-FudgePopLog -Category "Info" -Message "NO removals have been assigned to this computer"
	}
}

<#
.SYNOPSIS
	Execute REGISTRY directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPRegistry {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- registry assignments ---------"
	if ($DataSet) {
		Write-FudgePopLog -Category "Info" -Message "registry changes have been assigned to this computer"
		Write-FudgePopLog -Category "Info" -Message "assigned device: $devicename"
		foreach ($reg in $DataSet) {
			$regpath    = $reg.path
			$regval     = $reg.value
			$regdata    = $reg.data
			$regtype    = $reg.type
			$deviceName = $reg.device
			$regAction  = $reg.action
			Write-FudgePopLog -Category "Info" -Message "assigned to device: $deviceName"
			Write-FudgePopLog -Category "Info" -Message "keypath: $regpath"
			Write-FudgePopLog -Category "Info" -Message "action: $regAction"
			switch ($regAction) {
				'create' {
					if ($regdata -eq '$controlversion') { $regdata = $controlversion }
					if ($regdata -eq '$(Get-Date)') { $regdata = Get-Date }
					Write-FudgePopLog -Category "Info" -Message "value: $regval"
					Write-FudgePopLog -Category "Info" -Message "data: $regdata"
					Write-FudgePopLog -Category "Info" -Message "type: $regtype"
					if (-not(Test-Path $regpath)) {
						Write-FudgePopLog -Category "Info" -Message "key not found, creating registry key"
						if (-not $TestMode) {
							New-Item -Path $regpath -Force | Out-Null
							Write-FudgePopLog -Category "Info" -Message "updating value assignment to $regdata"
							New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
						}
						else {
							Write-FudgePopLog -Category "Info" -Message "TEST MODE"
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "key already exists"
						if (-not $TestMode) {
							try {
								$cv = Get-ItemProperty -Path $regpath -Name $regval -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regval
							}
							catch {
								Write-FudgePopLog -Category "Info" -Message "$regval not found"
								$cv = ""
							}
							Write-FudgePopLog -Category "Info" -Message "current value of $regval is $cv"
							if ($cv -ne $regdata) {
								Write-FudgePopLog -Category "Info" -Message "updating value assignment to $regdata"
								New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
							}
						}
						else {
							Write-FudgePopLog -Category "Info" -Message "TEST MODE"
						}
					}
					break
				}
				'delete' {
					if (Test-Path $regPath) {
						if (-not $TestMode) {
							try {
								Remove-Item -Path $regPath -Recurse -Force | Out-Null
								Write-FudgePopLog -Category "Info" -Message "registry key deleted"
							}
							catch {
								Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
							}
						}
						else {
							Write-FudgePopLog -Category "Info" -Message "TEST MODE"
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "registry key not found: $regPath"
					}
					break
				}
			} # switch
		} # foreach
	}
	else {
		Write-FudgePopLog -Category "Info" -Message "NO registry changes have been assigned to this computer"
	}
}

<#
.SYNOPSIS
	Execute SERVICES directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPServices {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- services assignments ---------"
	foreach ($service in $DataSet) {
		$svcName    = $service.name
		$svcStart   = $service.startup
		$svcAction  = $service.action
		$deviceName = $service.device
		Write-FudgePopLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePopLog -Category "Info" -Message "service name: $svcName"
		Write-FudgePopLog -Category "Info" -Message "startup should be: $svcStart"
		Write-FudgePopLog -Category "Info" -Message "requested action: $svcAction"
		try {
			$scfg = Get-Service -Name $svcName
			$sst  = $scfg.StartType
			if ($svcStart -ne "" -and $scfg.StartType -ne $svcStart) {
				Write-FudgePopLog -Category "Info" -Message "current startup type is: $sst"
				Write-FudgePopLog -Category "Info" -Message "setting service startup to: $svcStart"
				if (-not $TestMode) {
					Set-Service -Name $svcName -StartupType $svcStart | Out-Null
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "TEST MODE"
				}
			}
			switch ($svcAction) {
				'start' {
					if ($scfg.Status -ne 'Running') {
						Write-FudgePopLog -Category "Info" -Message "starting service..."
						if (-not $TestMode) {
							Start-Service -Name $svcName | Out-Null
						}
						else {
							Write-FudgePopLog -Category "Info" -Message "TEST MODE"
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "service is already running"
					}
					break
				}
				'restart' {
					Write-FudgePopLog -Category "Info" -Message "restarting service..."
					if (-not $TestMode) {
						Restart-Service -Name $svcName -ErrorAction SilentlyContinue
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE"
					}
					break
				}
				'stop' {
					Write-FudgePopLog -Category "Info" -Message "stopping service..."
					if (-not $TestMode) {
						Stop-Service -Name $svcName -Force -NoWait -ErrorAction SilentlyContinue
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE"
					}
					break
				}
			} # switch
		}
		catch {
			Write-FudgePopLog -Category "Error" -Message "service not found: $svcName"
		}
	} # foreach
}

<#
.SYNOPSIS
	Execute FOLDERS directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPFolders {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- folder assignments ---------"
	foreach ($folder in $DataSet) {
		$folderPath  = $folder.path
		$deviceName  = $folder.device
		$action = $folder.action
		Write-FudgePopLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePopLog -Category "Info" -Message "folder action assigned: $action"
		switch ($action) {
			'create' {
				Write-FudgePopLog -Category "Info" -Message "folder path: $folderPath"
				if (-not(Test-Path $folderPath)) {
					Write-FudgePopLog -Category "Info" -Message "creating new folder"
					if (-not $TestMode) {
						mkdir -Path $folderPath -Force | Out-Null
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE"
					}
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "folder already exists"
				}
				break
			}
			'empty' {
				$filter = $folder.filter
				if ($filter -eq "") { $filter = "*.*" }
				Write-FudgePopLog -Category "Info" -Message "deleting $filter from $folderPath and subfolders"
				if (-not $TestMode) {
					Get-ChildItem -Path "$folderPath" -Filter "$filter" -Recurse |
						foreach { Remove-Item -Path $_.FullName -Confirm:$False -Recurse -ErrorAction SilentlyContinue }
					Write-FudgePopLog -Category "Info" -Message "some files may remain if they were in use"
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "TEST MODE"
				}
				break
			}
			'delete' {
				if (Test-Path $folderPath) {
					Write-FudgePopLog -Category "Info" -Message "deleting $folderPath and subfolders"
					if (-not $TestMode) {
						try {
							Remove-Item -Path $folderPath -Recurse -Force | Out-Null
							Write-FudgePopLog -Category "Info" -Message "folder may remain if files are still in use"
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "TEST MODE"
					}
				}
				else {
				}
				break
			}
		} # switch
	} # foreach
}

<#
.SYNOPSIS
	Execute FILES directives from XML control file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPFiles {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- file assignments ---------"
	foreach ($file in $DataSet) {
		$fileSource = $file.source
		$fileTarget = $file.target
		$action     = $file.action
		Write-FudgePopLog -Category "Info" -Message "file action assigned: $action"
		Write-FudgePopLog -Category "Info" -Message "source: $fileSource"
		Write-FudgePopLog -Category "Info" -Message "target: $fileTarget"
		if ($TestMode) {
			Write-FudgePopLog -Category "Info" -Message "TEST MODE"
		}
		else {
			switch ($action) {
				'download' {
					Write-FudgePopLog -Category "Info" -Message "downloading file"
					if ($fileSource.StartsWith('http') -or $fileSource.StartsWith('ftp')) {
						try {
							$WebClient = New-Object System.Net.WebClient
							$WebClient.DownloadFile($fileSource, $fileTarget) | Out-Null
							if (Test-Path $fileTarget) {
								Write-FudgePopLog -Category "Info" -Message "file downloaded successfully"
							}
							else {
								Write-FudgePopLog -Category "Error" -Message "failed to download file!"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						try {
							Copy-Item -Source $fileSource -Destination $fileTarget -Force | Out-Null
							if (Test-Path $fileTarget) {
								Write-FudgePopLog -Category "Info" -Message "file downloaded successfully"
							}
							else {
								Write-FudgePopLog -Category "Error" -Message "failed to download file!"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message "failed to download file!"
						}
					}
					break
				}
				'rename' {
					Write-FudgePopLog -Category "Info" -Message "renaming file"
					if (Test-Path $fileSource) {
						Rename-Item -Path $fileSource -NewName $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FudgePopLog -Category "Info" -Message "file renamed successfully"
						}
						else {
							Write-FudgePopLog -Category "Error" -Message "failed to rename file!"
						}
					}
					else {
						Write-FudgePopLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'move' {
					Write-FudgePopLog -Category "Info" -Message "moving file"
					if (Test-Path $fileSource) {
						Move-Item -Path $fileSource -Destination $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FudgePopLog -Category "Info" -Message "file moved successfully"
						}
						else {
							Write-FudgePopLog -Category "Error" -Message "failed to move file!"
						}
					}
					else {
						Write-FudgePopLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'delete' {
					Write-FudgePopLog -Category "Info" -Message "deleting file"
					if (Test-Path $fileSource) {
						try {
							Remove-Item -Path $fileSource -Force | Out-Null
							if (-not(Test-Path $fileSource)) {
								Write-FudgePopLog -Category "Info" -Message "file deleted successfully"
							}
							else {
								Write-FudgePopLog -Category "Error" -Message "failed to delete file!"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "source file not found: $fileSource"
					}
					break
				}
			} # switch
		}
	} # foreach
}

<#
.SYNOPSIS
	
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPShortcuts {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- shortcut assignments ---------"
	foreach ($sc in $DataSet) {
		$scDevice   = $sc.device
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
		try {
			if (-not (Test-Path $scPath)) {
				$scRealPath = [environment]::GetFolderPath($scPath)
			}
			else {
				$scRealPath = $scPath
			}
		}
		catch {
			$scRealPath = $null
		}
		if ($scRealPath) {
			Write-FudgePopLog -Category "Info" -Message "shortcut action: $scAction"
			switch ($scAction) {
				'create' {
					if ($scWindow.length -gt 0) {
						switch ($scWindow) {
							'normal' {$scWin = 1; break;}
							'max' {$scWin = 3; break;}
							'min' {$scWin = 7; break;}
						}
					}
					else {
						$scWin = 1
					}
					Write-FudgePopLog -Category "Info" -Message "shortcut name....: $scName"
					Write-FudgePopLog -Category "Info" -Message "shortcut path....: $scPath"
					Write-FudgePopLog -Category "Info" -Message "shortcut target..: $scTarget"
					Write-FudgePopLog -Category "Info" -Message "shortcut descrip.: $scDesc"
					Write-FudgePopLog -Category "Info" -Message "shortcut args....: $scArgs"
					Write-FudgePopLog -Category "Info" -Message "shortcut workpath: $scWorkPath"
					Write-FudgePopLog -Category "Info" -Message "shortcut window..: $scWindow"
					Write-FudgePopLog -Category "Info" -Message "device name......: $scDevice"
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FudgePopLog -Category "Info" -Message "full linkpath: $scFullName"
					if ($scForce -eq 'true' -or (-not(Test-Path $scFullName))) {
						Write-FudgePopLog -Category "Info" -Message "creating new shortcut"
						try {
							if (-not $TestMode) {
								$wShell = New-Object -ComObject WScript.Shell
								$shortcut = $wShell.CreateShortcut("$scFullName")
								$shortcut.TargetPath = $scTarget
								if ($scType -eq 'lnk') {
									if ($scArgs -ne "") { $shortcut.Arguments = "$scArgs" }
									#$shortcut.HotKey       = ""
									if ($scWorkPath -ne "") { $shortcut.WorkingDirectory = "$scWorkPath" }
									$shortcut.WindowStyle  = $scWin
									$shortcut.Description  = $scName
								}
								#$shortcut.IconLocation = $scFullName
								$shortcut.Save()
							}
							else {
								Write-FudgePopLog -Category "Info" -Message "TEST MODE: $scFullName"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message "failed to create shortcut: $($_.Exception.Message)"
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "shortcut already created - no updates"
					}
					break
				}
				'delete' {
					Write-FudgePopLog -Category "Info" -Message "shortcut name....: $scName"
					Write-FudgePopLog -Category "Info" -Message "shortcut path....: $scPath"
					Write-FudgePopLog -Category "Info" -Message "device name......: $scDevice"
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FudgePopLog -Category "Info" -Message "full linkpath: $scFullName"
					if (Test-Path $scFullName) {
						Write-FudgePopLog -Category "Info" -Message "creating new shortcut"
						try {
							if (-not $TestMode) {
								Remove-Item -Path $scFullName -Force | Out-Null
							}
							else {
								Write-FudgePopLog -Category "Info" -Message "TEST MODE: $scFullName"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "shortcut not found: $scFullName"
					}
					break
				}
			} # switch
		}
		else {
			Write-FudgePopLog -Category "Error" -Message "failed to convert path key"
		}
	} # foreach
}

<#
.SYNOPSIS
	
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPOPApps {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- on-prem app assignments ---------"
	foreach ($app in $DataSet) {
		$appName   = $app.name
		$action    = $app.action
		$appPlat   = $app.platforms
		$appRun    = $app.run
		$appParams = $app.params
		Write-FudgePopLog -Category "Info" -Message "appname: $appName"
		Write-FudgePopLog -Category "Info" -Message "app run: $appRun"
		Write-FudgePopLog -Category "Info" -Message "action: $action"
		switch ($action) {
			'install' {
				if (-not $TestMode) {
					if ($appRun.EndsWith('.msi')) {
						$proc = "msiexec.exe"
						$args = "/i `"$appRun`" /q"
						if ($appParams -ne "") {
							$args += " $appParams"
						}
					}
					elseif ($appRun.EndsWith('.exe')) {
						$proc = $appRun
						$args = $appParams
					}
					else {
						Write-FudgePopLog -Category "Error" -Message "invalid file type"
						break
					}
					Write-FudgePopLog -Category "Info" -Message "run-process: $proc"
					Write-FudgePopLog -Category "Info" -Message "run-params: $args"
					Write-FudgePopLog -Category "Info" -Message "contacting source to verify availability..."
					if (Test-Path $appRun) {
						try {
							$p = Start-Process -FilePath $proc -ArgumentList $args -NoNewWindow -Wait -PassThru
							if ((0,3010) -contains $p.ExitCode) {
								Write-FudgePopLog -Category "Info" -Message "installation successful!"
							}
							else {
								Write-FudgePopLog -Category "Error" -Message "installation failed with $($p.ExitCode)"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FudgePopLog -Category "Info" -Message "installer file is not accessible (skipping)"
					}
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "TEST MODE"
				}
				break
			}
			'uninstall' {
				$detect = $app.detect
				$rule = ($controldata.configuration.detectionrules.detectionrule | Where-Object {$_.name -eq $detect}).path
				Write-FudgePopLog -Category "Info" -Message "detection rule name: $detect"
				Write-FudgePopLog -Category "Info" -Message "detection rule: $rule"
				if (Test-Path $rule) {
					Write-FudgePopLog -Category "Info" -Message "ruletest = TRUE"
					if ($appRun.StartsWith('msiexec /x')) {
						$proc = "msiexec"
						$args = ($appRun -replace ("msiexec","")).trim()
						try {
							$p = Start-Process -FilePath $proc -ArgumentList $args -NoNewWindow -Wait -PassThru
							if ((0,3010,1605) -contains $p.ExitCode) {
								Write-FudgePopLog -Category "Info" -Message "uninstall was successful!"
							}
							else {
								Write-FudgePopLog -Category "Error" -Message "uninstall failed with $($p.ExitCode)"
							}
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
				}
				else {
					Write-FudgePopLog -Category "Info" -Message "ruletest = FALSE"
				}
				break
			}
		} # switch
	} # foreach
}

function Invoke-FPPermissions {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePopLog -Category "Info" -Message "--------- permissions assignments ---------"
	foreach ($priv in $DataSet) {
		$device     = $priv.device
		$privPath   = $priv.path
		$privPrinc  = $priv.principals
		$privRights = $priv.rights
		if ($privPath.StartsWith('HK')) {
			$privType = 'registry'
		}
		else {
			$privType = 'filesystem'
		}
		Write-FudgePopLog -Category "Info" -Message "device: $device"
		Write-FudgePopLog -Category "Info" -Message "priv path: $privPath"
		Write-FudgePopLog -Category "Info" -Message "priv principals: $privPrinc"
		Write-FudgePopLog -Category "Info" -Message "priv rights: $privRights"
		if (Test-Path $privPath) {
			switch ($privType) {
				'filesystem' {
					switch ($privRights) {
						'full' {
							$pset = '(OI)(CI)(F)'
							break
						}
						'modify' {
							$pset = '(OI)(CI)(M)'
							break
						}
						'read' {
							$pset = '(OI)(CI)(R)'
							break
						}
						'write' {
							$pset = '(OI)(CI)(W)'
							break 
						}
						'delete' {
							$pset = '(OI)(CI)(D)'
							break
						}
						'readexecute' {
							$pset = '(OI)(CI)(RX)'
							break
						}
					} # switch
					Write-FudgePopLog -Category "Info" -Message "permission set: $pset"
					if (-not $TestMode) {
						try {
							icacls "$privPath" /grant "$privPrinc`:$pset" /T /C /Q
						}
						catch {
							Write-FudgePopLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FudgePopLog -Category "TESTMODE" -Message "icacls `"$privPath`" /grant `"$privPrinc`:$pset`" /T /C /Q"
					}
					break
				}
				'registry' {
					break
				}
			} # switch
		}
		else {
			Write-FudgePopLog -Category "Error" -Message ""
		}
	} # switch
}

<#
.SYNOPSIS
	Actually initiates all the crap being shoved in its face from the XML file
.PARAMETER DataSet
	XML data set fed from the XML control file
#>

function Invoke-FPTasks {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	$mypc = $env:COMPUTERNAME
	if ($PayLoad -eq 'Configure') {
		if (Set-FPConfiguration) {
			Write-Host "configuration has been updated"
		}
	}
	else {
		$files    = $DataSet.configuration.files.file | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$installs = $DataSet.configuration.deployments.deployment | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$removals = $DataSet.configuration.removals.removal | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$regkeys  = $DataSet.configuration.registry.reg | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$services = $DataSet.configuration.services.service | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$folders  = $DataSet.configuration.folders.folder | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$shortcuts = $DataSet.configuration.shortcuts.shortcut |
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$opapps = $DataSet.configuration.opapps.opapp |
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$privs  = $DataSet.configuration.permissions.permission |
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		if ($folders)  { if ($Payload -eq 'All' -or $Payload -eq 'Folders')  { Invoke-FPFolders -DataSet $folders } }
		if ($installs) { if ($Payload -eq 'All' -or $Payload -eq 'Installs') { Invoke-FPChocoInstalls -DataSet $installs } }
		if ($removals) { if ($Payload -eq 'All' -or $Payload -eq 'Removals') { Invoke-FPChocoRemovals -DataSet $removals } }
		if ($regkeys)  { if ($Payload -eq 'All' -or $Payload -eq 'Registry') { Invoke-FPRegistry -DataSet $regkeys } }
		if ($services) { if ($Payload -eq 'All' -or $Payload -eq 'Services') { Invoke-FPServices -DataSet $services } }
		if ($files)    { if ($Payload -eq 'All' -or $Payload -eq 'Files')    { Invoke-FPFiles -DataSet $files } }
		if ($shortcuts){ if ($Payload -eq 'All' -or $Payload -eq 'Shortcuts'){ Invoke-FPShortcuts -DataSet $shortcuts } }
		if ($opapps)   { if ($Payload -eq 'All' -or $Payload -eq 'OPApps')   { Invoke-FPOPApps -DataSet $opapps } }
		if ($privs)    { if ($Payload -eq 'All' -or $Payload -eq 'Permissions') { Invoke-FPPermissions -DataSet $privs } }
	}
}

<#
.SYNOPSIS
	Create or Update Scheduled Task for FudgePop client script
.PARAMETER IntervalHours
	[int][optional] Hourly interval from 1 to 12
#>

function Set-FPConfiguration {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$False, HelpMessage="Recurrence Interval in hours")]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1,12)]
		[int] $IntervalHours = 1
	)
	Write-Host "Configuring FudgePop scheduled task"
	$taskname = "Run FudgePop"
	Write-FudgePopLog -Category "Info" -Message "updating FudgePop client configuration"
	#$filepath = "$PSSCriptRoot\Public\Invoke-FudgePop.ps1"
	$filepath = "$(Split-Path((Get-Module FudgePop).Path))\Public\Invoke-FudgePop.ps1"
	if (Test-Path $filepath) {
		$action = 'powershell.exe -ExecutionPolicy ByPass -NoProfile -File '+$filepath
		Write-Verbose "creating: SCHTASKS /Create /RU `"SYSTEM`" /SC hourly /MO $IntervalHours /TN `"$taskname`" /TR `"$action`""
		SCHTASKS /Create /RU "SYSTEM" /SC hourly /MO $IntervalHours /TN "$taskname" /TR "$action" /RL HIGHEST
		if (Get-ScheduledTask -TaskName $taskname -ErrorAction SilentlyContinue) {
			Write-FudgePopLog -Category "Info" -Message "task has been created successfully."
			Write-Output $True
		}
		else {
			Write-FudgePopLog -Category "Error" -Message "well, that sucked. no new scheduled task for you."
		}
	}
	else {
		Write-FudgePopLog -Category "Error" -Message "unable to locate file: $filepath"
	}
}
