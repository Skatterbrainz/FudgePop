<#
.SYNOPSIS
	Private functions for running FudgePop
.NOTES
	1.0.5 - 11/03/2017 - David Stein
#>


<#
.SYNOPSIS
	Yet another stupid Write-Log function like everyone else has
.PARAMETER Category
	[optional] Describes type of information as 'Info','Warning','Error' (default is 'Info')
.PARAMETER Message
	[required] string: information to display or write to log file
#>

function Write-FPLog {
	param (
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Message,
		[parameter(Mandatory=$False)]
			[ValidateSet('Info','Warning','Error')]
			[string] $Category = 'Info'
	)
	Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
	"$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | Out-File $Script:FPLogFile -Encoding Default
}

<#
.SYNOPSIS
	Fetch data from Registry or return Default if none found
.PARAMETER RegPath
	[optional] Registry Path (default is HKLM:\SOFTWARE\FudgePop)
.PARAMETER Name
	[required] string: Registry Value name
.PARAMETER Default
	[optional] data to return if no value found in registry
#>

function Get-FPConfiguration {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$False)]
			[ValidateNotNullOrEmpty()]
			[string] $RegPath = $FPRegRoot,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Name,
		[parameter(Mandatory=$False)]
			[string] $Default = ""
	)
	if (Test-Path $RegPath) {
		Write-Verbose "registry path confirmed: $RegPath ($Name)"
		try {
			$result = Get-ItemProperty -Path $RegPath -ErrorAction Stop |
				Select-Object -ExpandProperty $Name -ErrorAction Stop
			if ($result -eq $null -or $result -eq "") {
				Write-Verbose "no data returned from query. using default: $Default"
				$result = $Default
			}
		}
		catch {
			Write-Verbose "error: returning $Default"
			$result = $Default
		}
	}
	else {
		Write-Verbose "registry path does not yet exist: $RegPath"
		$result = $Default
	}
	Write-Output $result
}

<#
.SYNOPSIS
	Write data to Registry
.PARAMETER RegPath
	[optional] Registry Path (default is HKLM:\SOFTWARE\FudgePop)
.PARAMETER Name
	[required] string: Registry Value name
.PARAMETER Data
	[required] data to store in registry value
#>

function Set-FPConfiguration {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$False)]
			[ValidateNotNullOrEmpty()]
			[string] $RegPath = $FPRegRoot,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Name,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Data
	)
	if (!(Test-Path $RegPath)) {
		try {
			Write-Verbose "creating new registry key root"
			New-Item -Path $RegPath -Force -ErrorAction Stop | Out-Null
			$created = $True
		}
		catch {
			Write-FPLog -Category 'Error' -Message $_.Exception.Message
			break
		}
	}
	if ($created) {
		Set-ItemProperty -Path $RegPath -Name "ModuleVersion" -Value $FPVersion -ErrorAction Stop
		Set-ItemProperty -Path $RegPath -Name "InitialSetup" -Value (Get-Date) -ErrorAction Stop
	}
	try {
		Set-ItemProperty -Path $RegPath -Name $Name -Value $Data -ErrorAction Stop
	}
	catch {
		Write-FPLog -Category 'Error' -Message $_.Exception.Message
		break
	}
	Write-Output 0
}

<#
.SYNOPSIS
	Validate File or URI is accessible
.PARAMETER Path
	[required] string: path or URI to file
#>

function Test-FPControlSource {
	param (
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	)
	if ($Path.StartsWith('http')) {
		Write-FPLog "verifying URI resource: $Path"
		try {
			$test = Invoke-WebRequest -UseBasicParsing -Uri $Path -Method Get -ErrorAction SilentlyContinue
			if ($test) {
				Write-Output ($test.StatusCode -eq 200)
			}
		}
		catch {}
	}
	else {
		Write-FPLog "verifying file system resource: $Path"
		Write-Output (Test-Path $Path)
	}
}

<#
.SYNOPSIS
	Import XML data from Control File
.PARAMETER FilePath
	[required] string: path or URI to XML file
#>

function Get-FPControlData {
	param (
		[parameter(Mandatory=$True, HelpMessage="Path or URI to XML control file")]
		[ValidateNotNullOrEmpty()]
		[string] $FilePath
	)
	Write-FPLog "preparing to import control file: $FilePath"
	if ($FilePath.StartsWith("http")) {
		try {
			[xml]$result = Invoke-RestMethod -Uri "$FilePath" -UseBasicParsing
		}
		catch {
			Write-FPLog -Category 'Error' -Message "failed to import data from Uri: $FilePath"
			Write-Output -3
			break;
		}
		Write-FPLog 'control data loaded successfully'
	}
	else {
		if (Test-Path $FilePath) {
			try {
				[xml]$result = Get-Content -Path $FilePath
			}
			catch {
				Write-FPLog -Category 'Error' -Message "unable to import control file: $FilePath"
				Write-Output -4
				break;
			}
		}
		else {
			Write-FPLog -Category 'Error' -Message "unable to locate control file: $FilePath"
			Write-Output -5
			break;
		}
	}
	Write-Output $result
}

<#
.SYNOPSIS
	Return child nodes where device=(_this-computer_) or device="all"
.PARAMETER XmlData
	[required] XML node data from control file import
.EXAMPLE
	Node: /configuration/files/file
		<file device="all" enabled="true" source="" target=""...>
	Would return this node since device='all'
#>

function Get-FPFilteredSet {
	param (
		[parameter(Mandatory=$True)]
		$XmlData
	)
	$XmlData | Where-Object {$_.enabled -eq 'true' -and ($_.device -eq $env:COMPUTERNAME -or $_.device -eq 'all')}
}

<#
.SYNOPSIS
	Return TRUE if enabled="true" in control section of XML
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Get-FPServiceAvailable {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	if ($DataSet.configuration.control.enabled -eq 'true') {
		if (($DataSet.configuration.control.exclude -split ',') -contains $MyPC) {
			Write-FPLog 'FudgePop services are enabled, but this device is excluded'
			break
		}
		else {
			Write-FPLog 'FudgePop services are enabled for all devices'
			Write-Output $True
		}
	}
	else {
		Write-FPLog 'FudgePop services are currently disabled for all devices'
	}
}

<#
.SYNOPSIS
	Return TRUE if detection rule is valid
.PARAMETER DataSet
	[required] XML data from control file import
.PARAMETER RuleName
	[required] string: name of rule in control XML file
#>

function Test-FPDetectionRule {
	param (
		[parameter(Mandatory=$True)]
			$DataSet,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $RuleName
	)
	Write-FPLog "detection rule: $RuleName"
	try {
		$detectionRule = $DataSet.configuration.detectionrules.detectionrule | Where-Object {$_.name -eq $RuleName}
		$rulePath = $detectionRule.path
		Write-FPLog "detection test: $rulePath"
		Write-Output (Test-Path $rulePath)
	}
	catch {}
}

<#
.SYNOPSIS
	Return TRUE if runtime is active
.PARAMETER RunTime
	[required] Date Value, or 'now' or 'daily'
.PARAMETER Key
	[optional] string: Label to map to Registry for get/set operations
#>

function Test-FPControlRuntime {
	param (
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $RunTime,
		[parameter(Mandatory=$False)]
			[string] $Key = ""
	)
	switch ($RunTime) {
		'now' { Write-Output $True; break }
		'daily' {
			$lastrun = Get-FPConfiguration -Name "$Key" -Default ""
			if ($lastrun -ne "") {
				$prevDate = $(Get-Date($lastrun)).ToShortDateString()
				Write-FPLog "previous run: $prevDate"
				if ($prevDate -ne (Get-Date).ToShortDateString()) {
					Write-FPLog "$prevDate is not today: $((Get-Date).ToShortDateString())"
					Write-Output $True
				}
			}
			else {
				Write-FPLog "no previous run"
				Write-Output $True
			}
			break
		}
		default {
			Write-FPLog "checking explicit runtime"
			if ((Get-Date).ToLocalTime() -ge $RunTime) {
				Write-Output $True
			}
		}
	} # switch
}

<#
.SYNOPSIS
	Process Configuration Control: Install or Upgrade Chocolatey
.PARAMETER none

#>

function Assert-Chocolatey {
	param ()
	Write-FPLog "verifying chocolatey installation"
	if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
		try {
			Write-FPLog "installing chocolatey"
			iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		}
		catch {
			Write-FPLog -Category "Error" -Message $_.Exception.Message
			break
		}
	}
	else {
		Write-FPLog "checking for newer version of chocolatey"
		choco upgrade chocolatey -y
	}
}

<#
.SYNOPSIS
	Process Configuration Control: Files
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlFiles {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog "--------- file assignments: begin ---------"
	foreach ($file in $DataSet) {
		$fileDevice = $file.device
		$fileSource = $file.source
		$fileTarget = $file.target
		$action     = $file.action
		Write-FPLog  "device name.......: $fileDevice"
		Write-FPLog  "action............: $action"
		Write-FPLog  "source............: $fileSource"
		Write-FPLog  "target............: $fileTarget"
		if ($TestMode) {
			Write-FPLog  "TEST MODE: no changes will be applied"
		}
		else {
			switch ($action) {
				'download' {
					Write-FPLog "downloading file"
					if ($fileSource.StartsWith('http') -or $fileSource.StartsWith('ftp')) {
						try {
							$WebClient = New-Object System.Net.WebClient
							$WebClient.DownloadFile($fileSource, $fileTarget) | Out-Null
							if (Test-Path $fileTarget) {
								Write-FPLog "file downloaded successfully"
							}
							else {
								Write-FPLog -Category "Error" -Message "failed to download file!"
							}
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						try {
							Copy-Item -Source $fileSource -Destination $fileTarget -Force | Out-Null
							if (Test-Path $fileTarget) {
								Write-FPLog "file downloaded successfully"
							}
							else {
								Write-FPLog -Category "Error" -Message "failed to download file!"
							}
						}
						catch {
							Write-FPLog -Category "Error" -Message "failed to download file!"
						}
					}
					break
				}
				'rename' {
					Write-FPLog "renaming file"
					if (Test-Path $fileSource) {
						Rename-Item -Path $fileSource -NewName $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FPLog "file renamed successfully"
						}
						else {
							Write-FPLog -Category "Error" -Message "failed to rename file!"
						}
					}
					else {
						Write-FPLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'move' {
					Write-FPLog "moving file"
					if (Test-Path $fileSource) {
						Move-Item -Path $fileSource -Destination $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FPLog  "file moved successfully"
						}
						else {
							Write-FPLog -Category "Error" -Message "failed to move file!"
						}
					}
					else {
						Write-FPLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'delete' {
					Write-FPLog "deleting file"
					if (Test-Path $fileSource) {
						try {
							Remove-Item -Path $fileSource -Force | Out-Null
							if (-not(Test-Path $fileSource)) {
								Write-FPLog  "file deleted successfully"
							}
							else {
								Write-FPLog -Category "Error" -Message "failed to delete file!"
							}
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog "source file not found: $fileSource"
					}
					break
				}
			} # switch
		}
	} # foreach
	Write-FPLog "--------- file assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Folders
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlFolders {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- folder assignments: begin ---------"
	foreach ($folder in $DataSet) {
		$folderPath  = $folder.path
		$deviceName  = $folder.device
		$action = $folder.action
		Write-FPLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FPLog -Category "Info" -Message "folder action assigned: $action"
		switch ($action) {
			'create' {
				Write-FPLog -Category "Info" -Message "folder path: $folderPath"
				if (-not(Test-Path $folderPath)) {
					Write-FPLog -Category "Info" -Message "creating new folder"
					if (-not $TestMode) {
						mkdir -Path $folderPath -Force | Out-Null
					}
					else {
						Write-FPLog -Category "Info" -Message "TEST MODE: no changes are being applied"
					}
				}
				else {
					Write-FPLog -Category "Info" -Message "folder already exists"
				}
				break
			}
			'empty' {
				$filter = $folder.filter
				if ($filter -eq "") { $filter = "*.*" }
				Write-FPLog -Category "Info" -Message "deleting $filter from $folderPath and subfolders"
				if (-not $TestMode) {
					Get-ChildItem -Path "$folderPath" -Filter "$filter" -Recurse |
						foreach { Remove-Item -Path $_.FullName -Confirm:$False -Recurse -ErrorAction SilentlyContinue }
					Write-FPLog -Category "Info" -Message "some files may remain if they were in use"
				}
				else {
					Write-FPLog -Category "Info" -Message "TEST MODE: no changes are being applied"
				}
				break
			}
			'delete' {
				if (Test-Path $folderPath) {
					Write-FPLog -Category "Info" -Message "deleting $folderPath and subfolders"
					if (-not $TestMode) {
						try {
							Remove-Item -Path $folderPath -Recurse -Force | Out-Null
							Write-FPLog -Category "Info" -Message "folder may remain if files are still in use"
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog -Category "Info" -Message "TEST MODE: no changes are being applied"
					}
				}
				else {
				}
				break
			}
		} # switch
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- folder assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Windows Services
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlServices {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- services assignments: begin ---------"
	foreach ($service in $DataSet) {
		$svcName    = $service.name
		$svcConfig  = $service.config
		$svcAction  = $service.action
		$deviceName = $service.device
		Write-FPLog -Category "Info" -Message "device name.....: $deviceName"
		Write-FPLog -Category "Info" -Message "service name....: $svcName"
		Write-FPLog -Category "Info" -Message "action..........: $svcAction"
		Write-FPLog -Category "Info" -Message "config type.....: $svcConfig"
		try {
			$scfg = Get-Service -Name $svcName
			switch ($svcAction) {
				'modify' {
					$sst  = $scfg.StartType
					if ($svcConfig -ne "") {
						$cfgList = $svcConfig -split ('=')
						$cfgName = $cfgList[0]
						$cfgData = $cfgList[1]
						switch ($cfgName) {
							'startup' {
								if ($cfgData -ne "" -and $scfg.StartType -ne $cfgData) {
									Write-FPLog -Category "Info" -Message "current startup type is: $sst"
									Write-FPLog -Category "Info" -Message "setting service startup to: $cfgData"
									if (-not $TestMode) {
										Set-Service -Name $svcName -StartupType $cfgData | Out-Null
									}
									else {
										Write-FPLog -Category "Info" -Message "TEST MODE: $cfgName -> $cfgData"
									}
								}
								break
							}
						} # switch
					}
					else {
						Write-FPLog -Category 'Error' -Message 'configuration properties have not been specified'
					}
					break
				}
				'start' {
					if ($scfg.Status -ne 'Running') {
						Write-FPLog -Category "Info" -Message "starting service..."
						if (-not $TestMode) {
							Start-Service -Name $svcName | Out-Null
						}
						else {
							Write-FPLog -Category "Info" -Message "TEST MODE"
						}
					}
					else {
						Write-FPLog -Category "Info" -Message "service is already running"
					}
					break
				}
				'restart' {
					Write-FPLog -Category "Info" -Message "restarting service..."
					if (-not $TestMode) {
						Restart-Service -Name $svcName -ErrorAction SilentlyContinue
					}
					else {
						Write-FPLog -Category "Info" -Message "TEST MODE"
					}
					break
				}
				'stop' {
					Write-FPLog -Category "Info" -Message "stopping service..."
					if (-not $TestMode) {
						Stop-Service -Name $svcName -Force -NoWait -ErrorAction SilentlyContinue
					}
					else {
						Write-FPLog -Category "Info" -Message "TEST MODE"
					}
					break
				}
			} # switch
		}
		catch {
			Write-FPLog -Category "Error" -Message "service not found: $svcName"
		}
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- services assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: File and URL Shortcuts
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlShortcuts {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog "--------- shortcut assignments: begin ---------"
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
			Write-FPLog "shortcut action: $scAction"
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
					Write-FPLog "shortcut name....: $scName"
					Write-FPLog "shortcut path....: $scPath"
					Write-FPLog "shortcut target..: $scTarget"
					Write-FPLog "shortcut descrip.: $scDesc"
					Write-FPLog "shortcut args....: $scArgs"
					Write-FPLog "shortcut workpath: $scWorkPath"
					Write-FPLog "shortcut window..: $scWindow"
					Write-FPLog "device name......: $scDevice"
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FPLog "full linkpath: $scFullName"
					if ($scForce -eq 'true' -or (-not(Test-Path $scFullName))) {
						Write-FPLog "creating new shortcut"
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
								Write-FPLog "TEST MODE: $scFullName"
							}
						}
						catch {
							Write-FPLog -Category "Error" -Message "failed to create shortcut: $($_.Exception.Message)"
						}
					}
					else {
						Write-FPLog "shortcut already created - no updates"
					}
					break
				}
				'delete' {
					$scFullName = "$scRealPath\$scName.$scType"
					Write-FPLog "shortcut name....: $scName"
					Write-FPLog "shortcut path....: $scPath"
					Write-FPLog "device name......: $scDevice"
					Write-FPLog "full linkpath....: $scFullName"
					if (Test-Path $scFullName) {
						Write-FPLog "deleting shortcut"
						try {
							if (-not $TestMode) {
								Remove-Item -Path $scFullName -Force | Out-Null
							}
							else {
								Write-FPLog "TEST MODE: $scFullName"
							}
						}
						catch {
							Write-FPLog -Category 'Error' -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog "shortcut not found: $scFullName"
					}
					break
				}
			} # switch
		}
		else {
			Write-FPLog -Category "Error" -Message "failed to convert path key"
		}
	} # foreach
	Write-FPLog "--------- shortcut assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: ACL Permissions on Files, Folders
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlPermissions {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog "--------- permissions assignments: begin ---------"
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
		Write-FPLog "device: $device"
		Write-FPLog "priv path: $privPath"
		Write-FPLog "priv principals: $privPrinc"
		Write-FPLog "priv rights: $privRights"
		if (Test-Path $privPath) {
			switch ($privType) {
				'filesystem' {
					switch ($privRights) {
						'full'   {$pset = '(OI)(CI)(F)'; break}
						'modify' {$pset = '(OI)(CI)(M)'; break}
						'read'   {$pset = '(OI)(CI)(R)'; break}
						'write'  {$pset = '(OI)(CI)(W)'; break}
						'delete' {$pset = '(OI)(CI)(D)'; break}
						'readexecute' {$pset = '(OI)(CI)(RX)'; break}
					} # switch
					Write-FPLog "permission set: $pset"
					if (-not $TestMode) {
						Write-FPlog "command: icacls `"$privPath`" /grant `"$privPrinc`:$pset`" /T /C /Q"
						try {
							icacls "$privPath" /grant "$privPrinc`:$pset" /T /C /Q
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog "TESTMODE: icacls `"$privPath`" /grant `"$privPrinc`:$pset`" /T /C /Q"
					}
					break
				}
				'registry' {
					Write-FPLog "registry permissions feature is not yet fully baked"
					break
				}
			} # switch
		}
		else {
			Write-FPLog -Category "Error" -Message ""
		}
	} # switch
	Write-FPLog "--------- permissions assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Chocolatey Package Installs and Upgrades
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlPackages {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- installation assignments: begin ---------"
	foreach ($package in $DataSet) {
		$deviceName = $package.device
		$runtime    = $package.when
		$autoupdate = $package.autoupdate
		$username   = $package.user
		$extparams  = $package.params
		$update     = $package.update
		Write-FPLog -Category "Info" -Message "device...: $deviceName"
		Write-FPLog -Category "Info" -Message "runtime..: $runtime"
		if (Test-FPControlRuntime -RunTime $runtime) {
			Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $package.InnerText -split ','
			if ($extparams.length -gt 0) { $params = $extparam } else { $params = ' -y -r' }
			foreach ($pkg in $pkglist) {
				Write-FPLog "package...: $pkg"
				if (Test-Path "$($env:PROGRAMDATA)\chocolatey\lib\$pkg") {
					if ($update -eq 'true') {
						Write-FPLog "package is already installed (upgrade)"
						$params = "upgrade $pkg $params"
					}
					else {
						Write-FPLog "package is already installed (no upgrade.. skip)"
						break
					}
				}
				else {
					Write-FPLog "package is not installed (install)"
					$params = "install $pkg $params"
				}
				Write-FPLog "command......: choco $params"
				if (-not $TestMode) {
					$p = Start-Process -FilePath "choco.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru
					if ($p.ExitCode -eq 0) {
						Write-FPLog "package was successful"
					}
					else {
						Write-FPLog -Category 'Error' -Message "package exit code: $($p.ExitCode)"
					}
				}
				else {
					Write-FPLog "TESTMODE: Would have been applied"
				}
			} # foreach
		}
		else {
			Write-FPLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- installation assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Chocolatey Package Upgrades
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlUpgrades {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- upgrade assignments: begin ---------"
	foreach ($upgrade in $DataSet) {
		# later / maybe
	}
	Write-FPLog -Category "Info" -Message "--------- upgrade assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Chocolatey Package Removals
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlRemovals {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- removal assignments: begin ---------"
	foreach ($package in $DataSet) {
		$deviceName = $package.device
		$runtime    = $package.when
		$autoupdate = $package.autoupdate
		$username   = $package.user
		$extparams  = $package.params
		Write-FPLog -Category "Info" -Message "device...: $deviceName"
		Write-FPLog -Category "Info" -Message "runtime..: $runtime"
		if (Test-FPControlRuntime -RunTime $runtime) {
			Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $package.InnerText -split ','
			if ($extparams.length -gt 0) { $params = $extparam } else { $params = ' -y -r' }
			foreach ($pkg in $pkglist) {
				Write-FPLog "package...: $pkg"
				if (Test-Path "$($env:PROGRAMDATA)\chocolatey\lib\$pkg") {
					Write-FPLog "package is installed"
					$params = "uninstall $pkg $params"
				}
				else {
					Write-FPLog "package is not installed (skip)"
					break
				}
				Write-FPLog "command......: choco $params"
				if (-not $TestMode) {
					$p = Start-Process -FilePath "choco.exe" -NoNewWindow -ArgumentList "$params" -Wait -PassThru
					if ($p.ExitCode -eq 0) {
						Write-FPLog "removal was successful"
					}
					else {
						Write-FPLog -Category 'Error' -Message "removal exit code: $($p.ExitCode)"
					}
				}
				else {
					Write-FPLog "TESTMODE: Would have been applied"
				}
			} # foreach
		}
		else {
			Write-FPLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- removal assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Registry Settings
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlRegistry {
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- registry assignments: begin ---------"
	foreach ($reg in $DataSet) {
		$regpath    = $reg.path
		$regval     = $reg.value
		$regdata    = $reg.data
		$regtype    = $reg.type
		$deviceName = $reg.device
		$regAction  = $reg.action
		Write-FPLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FPLog -Category "Info" -Message "keypath: $regpath"
		Write-FPLog -Category "Info" -Message "action: $regAction"
		switch ($regAction) {
			'create' {
				if ($regdata -eq '$controlversion') { $regdata = $controlversion }
				if ($regdata -eq '$(Get-Date)') { $regdata = Get-Date }
				Write-FPLog -Category "Info" -Message "value: $regval"
				Write-FPLog -Category "Info" -Message "data: $regdata"
				Write-FPLog -Category "Info" -Message "type: $regtype"
				if (-not(Test-Path $regpath)) {
					Write-FPLog -Category "Info" -Message "key not found, creating registry key"
					if (-not $TestMode) {
						New-Item -Path $regpath -Force | Out-Null
						Write-FPLog -Category "Info" -Message "updating value assignment to $regdata"
						New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
					}
					else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				}
				else {
					Write-FPLog -Category "Info" -Message "key already exists"
					if (-not $TestMode) {
						try {
							$cv = Get-ItemProperty -Path $regpath -Name $regval -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regval
						}
						catch {
							Write-FPLog -Category "Info" -Message "$regval not found"
							$cv = ""
						}
						Write-FPLog -Category "Info" -Message "current value of $regval is $cv"
						if ($cv -ne $regdata) {
							Write-FPLog -Category "Info" -Message "updating value assignment to $regdata"
							New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
						}
					}
					else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				}
				break
			}
			'delete' {
				if (Test-Path $regPath) {
					if (-not $TestMode) {
						try {
							Remove-Item -Path $regPath -Recurse -Force | Out-Null
							Write-FPLog -Category "Info" -Message "registry key deleted"
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				}
				else {
					Write-FPLog -Category "Info" -Message "registry key not found: $regPath"
				}
				break
			}
		} # switch
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- registry assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Windows Application Installs and Uninstalls
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlWin32Apps {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- win32 app assignments: begin ---------"
	foreach ($app in $DataSet) {
		$appName   = $app.name
		$action    = $app.action
		$appPlat   = $app.platforms
		$appRun    = $app.run
		$appParams = $app.params
		$runtime   = $app.when
		Write-FPLog -Category "Info" -Message "appname...: $appName"
		Write-FPLog -Category "Info" -Message "app run...: $appRun"
		Write-FPLog -Category "Info" -Message "action....: $action"
		Write-FPLog -Category "Info" -Message "runtime...: $runtime"
		switch ($action) {
			'install' {
				
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
					Write-FPLog -Category "Error" -Message "invalid file type"
					break
				}
				Write-FPLog -Category "Info" -Message "proc...: $proc"
				Write-FPLog -Category "Info" -Message "args...: $args"
				Write-FPLog -Category "Info" -Message "contacting source to verify availability..."
				if (Test-Path $appRun) {
					if (-not $TestMode) {
						try {
							$p = Start-Process -FilePath $proc -ArgumentList $args -NoNewWindow -Wait -PassThru
							if ((0,3010) -contains $p.ExitCode) {
								Write-FPLog -Category "Info" -Message "installation successful!"
							}
							else {
								Write-FPLog -Category "Error" -Message "installation failed with $($p.ExitCode)"
							}
						}
						catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					}
					else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				}
				else {
					Write-FPLog -Category "Info" -Message "installer file is not accessible (skipping)"
				}
				break
			}
			'uninstall' {
				$detect = $app.detect
				if (Test-FPDetectionRule -DataSet $DataSet -RuleName $detect) {
					Write-FPLog -Category "Info" -Message "ruletest = TRUE"
					if ($appRun.StartsWith('msiexec /x')) {
						$proc = "msiexec"
						$args = ($appRun -replace ("msiexec","")).trim()
						Write-FPLog "proc......: $proc"
						Write-FPLog "args......: $args"
						if (-not $TestMode) {
							try {
								$p = Start-Process -FilePath $proc -ArgumentList $args -NoNewWindow -Wait -PassThru
								if ((0,3010,1605) -contains $p.ExitCode) {
									Write-FPLog -Category "Info" -Message "uninstall was successful!"
								}
								else {
									Write-FPLog -Category "Error" -Message "uninstall failed with $($p.ExitCode)"
								}
							}
							catch {
								Write-FPLog -Category "Error" -Message $_.Exception.Message
							}
						}
						else {
							Write-FPLog "TESTMODE: Would have been applied"
						}
					}
				}
				else {
					Write-FPLog -Category "Info" -Message "ruletest = FALSE"
				}
				break
			}
		} # switch
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- win32 app assignments: finish ---------"
}

<#
.SYNOPSIS
	Process Configuration Control: Windows Updates
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Set-FPControlWindowsUpdate {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- updates assignments: begin ---------"
	foreach ($dvc in $DataSet) {
		$device  = $dvc.device
		$runtime = $dvc.when
		Write-FPLog -Category "Info" -Message "device....: $device"
		Write-FPLog -Category "Info" -Message "runtime...: $runtime"
		if (Test-FPControlRuntime -RunTime $runtime -Key "LastRunUpdates") {
			if (-not $TestMode) {
				Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
				try {
					$Criteria = "IsInstalled=0 and Type='Software'"
					$Searcher = New-Object -ComObject Microsoft.Update.Searcher
					$SearchResult = $Searcher.Search($Criteria).Updates
					$Session = New-Object -ComObject Microsoft.Update.Session
					$Downloader = $Session.CreateUpdateDownloader()
					$Downloader.Updates = $SearchResult
					$Downloader.Download()
					$Installer = New-Object -ComObject Microsoft.Update.Installer
					$Installer.Updates = $SearchResult
					$Result = $Installer.Install()
					Set-FPConfiguration -Name "LastRunUpdates" -Data (Get-Date)
					If ($Result.rebootRequired) { Restart-Computer }
				}
				catch {
					if ($_.Exception.Message -like "*0x80240024*") {
						Write-FPLog -Category 'Info' -Message "No updates are available for download"
						Set-FPConfiguration -Name "LastRunUpdates" -Data (Get-Date) | Out-Null
					}
					else {
						Write-FPLog -Category 'Error' -Message $_.Exception.Message
					}
				}
			}
			else {
				Write-FPLog "TESTMODE: Would have been applied"
			}
		}
		else {
			Write-FPLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- updates assignments: finish ---------"
}

<#
.SYNOPSIS
	Main process invocation
.PARAMETER DataSet
	[required] XML data from control file import
#>

function Invoke-FPControls {
	param (
		[parameter(Mandatory=$True)] 
		[ValidateNotNullOrEmpty()] $DataSet
	)
	Write-FPLog -Category "Info" -Message "--------- control processing: begin ---------"
	Write-FPLog "module version: $($Script:FPVersion)"
	$MyPC        = $env:COMPUTERNAME
	$priority    = $DataSet.configuration.priority.order
	$installs    = Get-FPFilteredSet -XmlData $DataSet.configuration.deployments.deployment
	$removals    = Get-FPFilteredSet -XmlData $DataSet.configuration.removals.removal
	$folders     = Get-FPFilteredSet -XmlData $DataSet.configuration.folders.folder
	$files       = Get-FPFilteredSet -XmlData $DataSet.configuration.files.file
	$registry    = Get-FPFilteredSet -XmlData $DataSet.configuration.registry.reg
	$services    = Get-FPFilteredSet -XmlData $DataSet.configuration.services.service
	$shortcuts   = Get-FPFilteredSet -XmlData $DataSet.configuration.shortcuts.shortcut
	$opapps      = Get-FPFilteredSet -XmlData $DataSet.configuration.opapps.opapp
	$permissions = Get-FPFilteredSet -XmlData $DataSet.configuration.permissions.permission
	$updates     = Get-FPFilteredSet -XmlData $DataSet.configuration.updates.update

	Write-FPLog "template version...: $($DataSet.configuration.version)"
	Write-FPLog "template comment...: $($DataSet.configuration.comment)"
	Write-FPLog "control version....: $($DataSet.configuration.control.version) ***"
	Write-FPLog "control enabled....: $($DataSet.configuration.control.enabled)"
	Write-FPLog "control comment....: $($DataSet.configuration.control.comment)"
	
	if (!(Get-FPServiceAvailable -DataSet $DataSet)) { Write-FPLog 'FudgePop is not enabled'; break }
	
	Write-FPLog "priority list: $($priority -replace(',',' '))"
	
	foreach ($key in $priority -split ',') {
		Write-FPLog "****************** $key **********************"
		switch ($key) {
			'folders'     { if ($folders)     {Set-FPControlFolders -DataSet $folders}; break }
			'files'       { if ($files)       {Set-FPControlFiles -DataSet $files}; break }
			'registry'    { if ($registry)    {Set-FPControlRegistry -DataSet $registry}; break }
			'deployments' { if ($installs)    {Set-FPControlPackages -DataSet $installs}; break }
			'removals'    { if ($removals)    {Set-FPControlRemovals -DataSet $removals}; break }
			'services'    { if ($services)    {Set-FPControlServices -DataSet $services}; break }
			'shortcuts'   { if ($shortcuts)   {Set-FPControlShortcuts -DataSet $shortcuts}; break }
			'opapps'      { if ($opapps)      {Set-FPControlWin32Apps -DataSet $opapps}; break }
			'permissions' { if ($permissions) {Set-FPControlPermissions -DataSet $permissions}; break }
			'updates'     { if ($updates)     {Set-FPControlWindowsUpdate -DataSet $updates}; break }
			default { Write-FPLog -Category 'Error' -Message "invalid priority key: $key"; break }
		} # switch
	} # foreach
	Write-FPLog -Category "Info" -Message "--------- control processing: finish ---------"
}
