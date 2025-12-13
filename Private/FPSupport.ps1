<#
.SYNOPSIS
	FudgePop Support Functions
.DESCRIPTION
	Support functions for FudgePop operations
.NOTES
	Looking at this might make your eyeballs hurt.
#>
function Write-FPLog {
	<#
	.SYNOPSIS
		Output Writing Handler
	.DESCRIPTION
		Yet another stupid Write-Log function like everyone else has
	.PARAMETER Category
		Describes type of information as 'Info','Warning','Error' (default is 'Info')
	.PARAMETER Message
		Information to display or write to log file
	.EXAMPLE
		Write-FPLog -Category 'Info' -Message 'This is a message'
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Message,
		[parameter(Mandatory = $False)][ValidateSet('Info', 'Warning', 'Error')][string] $Category = 'Info'
	)
	Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
	"$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | Out-File $Script:FPLogFile -Encoding Default -Append
}

function Write-CenteredText {
	<#
	.SYNOPSIS
	Print Text with Center Justification sort of
	
	.DESCRIPTION
	Kind of sort of in a way make it look centered
	
	.PARAMETER Caption
	Text to print
	
	.PARAMETER Filler
	Characters to print before and after as a divider
	
	.PARAMETER MaxLen
	Total number of characters to show on the line
	
	.EXAMPLE
	An example
	
	.NOTES
	General notes
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Caption,
		[parameter(Mandatory = $False)][string] $Filler = "*",
		[parameter(Mandatory = $False)][int] $MaxLen = 73
	)
	$caplen  = $Caption.Length + 2
	$remlen  = $MaxLen - $caplen
	$halflen = [math]::Round($remlen / 2, 0)
	$text    = "$($Filler*$halflen) $Caption $($Filler*$halflen)"
	if ($text.Length -lt $MaxLen) {
		$remx = $MaxLen - $text.Length
		$text += "$($Filler*$remx)"
	}
	Write-Output $text
}

function Test-FPDetectionRule {
	<#
	.SYNOPSIS
		Return TRUE if detection rule is valid
	.PARAMETER DataSet
		XML data from control file import
	.PARAMETER RuleName
		Name of rule in control XML file
	#>
	param (
		[parameter(Mandatory = $True)]$DataSet,
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $RuleName
	)
	Write-FPLog "detection rule: $RuleName"
	try {
		$detectionRule = $DataSet.configuration.detectionrules.detectionrule | Where-Object { $_.name -eq $RuleName }
		$rulePath = $detectionRule.path
		Write-FPLog "detection test: $rulePath"
		Write-Output (Test-Path $rulePath)
	} catch {}
}

function Test-FPControlSource {
	<#
	.SYNOPSIS
		Validate File or URI is accessible
	.DESCRIPTION
		Verifies Control XML file is accessible
	.PARAMETER Path
		Full Path or URI to file
	.INPUTS
		Path to file
	.OUTPUTS
		$True or $null
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Path
	)
	if ($Path.StartsWith('http')) {
		Write-FPLog "verifying URI resource: $Path"
		try {
			$test = Invoke-WebRequest -UseBasicParsing -Uri $Path -Method Get -ErrorAction SilentlyContinue
			if ($test) {
				Write-Output ($test.StatusCode -eq 200)
			}
		} catch {}
	} else {
		Write-FPLog "verifying file system resource: $Path"
		Write-Output (Test-Path $Path)
	}
}

function Test-FPControlRuntime {
	<#
	.SYNOPSIS
		Confirm Task Execution Time
	.DESCRIPTION
		Return TRUE if a task runtime is active
	.PARAMETER RunTime
		Date Value, or 'now' or 'daily'
	.PARAMETER Key
		Label to map to Registry for get/set operations
	.EXAMPLE
		Test-FPControlRuntime -RunTime "now"
	.EXAMPLE
		Test-FPControlRuntime -RunTime "11/12/2017 10:05:00 PM"
	.EXAMPLE
		Test-FPControlRuntime -RunTime "daily" -Key "TestValue"
	#>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $RunTime,
		[parameter(Mandatory = $False)][string] $Key = ""
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
			} else {
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

function Set-FPConfiguration {
	<#
	.SYNOPSIS
		Write data to Registry
	.DESCRIPTION
		Write Data to FudgePop Registry location
	.PARAMETER RegPath
		Registry Path (default is HKLM:\SOFTWARE\FudgePop)
	.PARAMETER Name
		Registry Value name
	.PARAMETER Data
		Data to store in registry value
	.INPUTS
		Registry Key (or default), Value Name, Data
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $False)]
		[ValidateNotNullOrEmpty()]
		[string] $RegPath = $FPRegRoot,
		[parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,
		[parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[string] $Data
	)
	if (!(Test-Path $RegPath)) {
		try {
			Write-Verbose "creating new registry key root"
			New-Item -Path $RegPath -Force -ErrorAction Stop | Out-Null
			$created = $True
		} catch {
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
	} catch {
		Write-FPLog -Category 'Error' -Message $_.Exception.Message
		break
	}
	Write-Output 0
}

function Get-FPFilteredSet {
	<#
	.SYNOPSIS
		Return Targeted Control data set
	.DESCRIPTION
		Return Targeted Control data set for this device or associated collection
	.PARAMETER ControlData
		Control data set for specific control group (e.g. files, folders, etc.)
	.PARAMETER Collections
		Array of collection names
	.EXAMPLE
		$dataset = Get-FPFilteredSet -ControlData $ControlData.configuration.files.file -Collections (Get-FPDeviceCollections -ControlData $ControlData)
	#>
	param (
		[parameter(Mandatory = $True)]
		$ControlData,
		[parameter(Mandatory = $False)]
		$Collections
	)
	$thisDevice = $env:COMPUTERNAME
	if ($null -ne $Collections) {
		$result = $ControlData |
		Where-Object { $_.enabled -eq 'true' -and ($Collections.Contains($_.collection)) }
	} else {
		$result = $ControlData |
		Where-Object { $_.enabled -eq 'true' -and ($_.device -eq 'all' -or $_.device -eq $thisDevice) }
	}
	Write-Output $result
}

function Get-FPControlJSON {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True, HelpMessage = "Path or URI to JSON control file")]
		[ValidateNotNullOrEmpty()]
		[string] $FilePath
	)
	Write-FPLog "preparing to import control file: $FilePath"
	if ($FilePath.StartsWith("http")) {
		try {
			Write-FPLog "Downloading control file from: $FilePath"
			$result = Invoke-WebRequest -Uri $FilePath -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json
		} catch {
			Write-FPLog -Category 'Error' -Message "failed to import data from Uri: $FilePath"
			Write-Output -3
			break;
		}
		Write-FPLog 'control data loaded successfully'
	} else {
		if (Test-Path $FilePath) {
			try {
				$result = (Get-Content -Path $FilePath | ConvertFrom-Json)
			} catch {
				Write-FPLog -Category 'Error' -Message "unable to import control file: $FilePath"
				Write-Output -4
				break;
			}
		} else {
			Write-FPLog -Category 'Error' -Message "unable to locate control file: $FilePath"
			Write-Output -5
			break;
		}
	}
	Write-Output $result
}

function Get-FPConfiguration {
	<#
	.SYNOPSIS
		Import Control Data from Registry
	.DESCRIPTION
		Fetch data from Registry or return Default if none found
	.PARAMETER RegPath
		Registry Path (default is HKLM:\SOFTWARE\FudgePop)
	.PARAMETER Name
		Registry Value name
	.PARAMETER Default
		Data to return if no value found in registry
	.INPUTS
		Registry Key, Value Name, Default Value (if not found in registry)
	.OUTPUTS
		Information returned from registry (or default value)
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $False)][ValidateNotNullOrEmpty()][string] $RegPath = $FPRegRoot,
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Name,
		[parameter(Mandatory = $False)][string] $Default = ""
	)
	if (Test-Path $RegPath) {
		Write-Verbose "registry path confirmed: $RegPath ($Name)"
		try {
			$result = Get-ItemProperty -Path $RegPath -ErrorAction Stop |
			Select-Object -ExpandProperty $Name -ErrorAction Stop
			if ($null -eq $result -or $result -eq "") {
				Write-Verbose "no data returned from query. using default: $Default"
				$result = $Default
			}
		} catch {
			Write-Verbose "error: returning $Default"
			$result = $Default
		}
	} else {
		Write-Verbose "registry path does not yet exist: $RegPath"
		$result = $Default
	}
	Write-Output $result
}

function Get-FPDeviceCollections {
	<#
	.SYNOPSIS
		Get Device Collection Memberships
	.DESCRIPTION
		Get List of Collections this Device is a Member of
	.PARAMETER ControlData
		Control Data
	.EXAMPLE
		$colls = Get-FPDeviceCollections -ControlData $ControlData
	.NOTES
	#>
	param (
		[parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		$ControlData
	)
	try {
		$( $ControlData.configuration.collections.collection | Where-Object { $_.members -match $env:COMPUTERNAME }).name
	} catch {
		Write-Output ""
	}
}

function Get-FPServiceAvailable {
	<#
	.SYNOPSIS
		Verify FudgePop Control Item is Enabled
	.DESCRIPTION
		Return TRUE if enabled="true" in control section of Control data
	.PARAMETER DataSet
		Control data from control file import
	.INPUTS
		Control data
	.OUTPUTS
		$True or $null
	#>
	param (
		[parameter(Mandatory = $True)]
		$DataSet
	)
	if ($DataSet.configuration.control.enabled) {
		if (($DataSet.configuration.control.exclude -split ',') -contains $MyPC) {
			Write-FPLog 'FudgePop services are enabled, but this device is excluded'
			break
		} else {
			Write-FPLog 'FudgePop services are enabled for all devices'
			Write-Output $True
		}
	} else {
		Write-FPLog 'FudgePop services are currently disabled for all devices'
	}
}

function Set-FPControlUpgrades {
	<#
	.SYNOPSIS
		Upgrade Chocolatey Packages
	.DESCRIPTION
		Process Configuration Control: Chocolatey Package Upgrades
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlUpgrades -DataSet $xmldata
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- upgrade assignments: begin ---------"
	foreach ($upgrade in $DataSet) {
		# later / maybe
	}
	Write-FPLog "--------- upgrade assignments: finish ---------"
}

function Invoke-FPControls {
	<#
	.SYNOPSIS
		Main process invocation
	.DESCRIPTION
		Main process for executing FudgePop services
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Invoke-FPControls -DataSet $xmldata
	#>
	param (
		[parameter(Mandatory = $True)] 
		[ValidateNotNullOrEmpty()] 
		$DataSet,
		[parameter(Mandatory = $false)]
		[string]$ControlName
	)
	$ModuleData = Get-Module FudgePop
	$ModuleVer  = $ModuleData.Version -join '.'

	Write-FPLog -Category "Info" -Message $(Write-CenteredText -Caption "control processing: begin")
	$MyPC = $env:COMPUTERNAME
	Write-FPLog "module version.....: $ModuleVer"
	Write-FPLog "device name........: $MyPC"
	$collections = Get-FPDeviceCollections -ControlData $DataSet
	if ($collections -ne "") {
		Write-FPLog -Category 'Info' -Message "collections........: $($collections -join ',')"
	}
	$priority       = $DataSet.configuration.priority.order
	$wingetinstalls = Get-FPFilteredSet -ControlData $DataSet.configuration.winget_installs.deployment -Collections $collections
	$chocoinstalls  = Get-FPFilteredSet -ControlData $DataSet.configuration.choco_installs.deployment -Collections $collections
	$wingetremovals = Get-FPFilteredSet -ControlData $DataSet.configuration.winget_removals.removal -Collections $collections
	$chocoremovals  = Get-FPFilteredSet -ControlData $DataSet.configuration.choco_removals.removal -Collections $collections
	$folders        = Get-FPFilteredSet -ControlData $DataSet.configuration.folders.folder -Collections $collections
	$files          = Get-FPFilteredSet -ControlData $DataSet.configuration.files.file -Collections $collections
	$registry       = Get-FPFilteredSet -ControlData $DataSet.configuration.registry.reg -Collections $collections
	$services       = Get-FPFilteredSet -ControlData $DataSet.configuration.services.service -Collections $collections
	$shortcuts      = Get-FPFilteredSet -ControlData $DataSet.configuration.shortcuts.shortcut -Collections $collections
	$opapps         = Get-FPFilteredSet -ControlData $DataSet.configuration.opapps.opapp -Collections $collections
	$updates        = Get-FPFilteredSet -ControlData $DataSet.configuration.updates.update -Collections $collections
	$appx           = Get-FPFilteredSet -ControlData $DataSet.configuration.appxremovals.appxremoval -Collections $collections
	$modules        = Get-FPFilteredSet -ControlData $DataSet.configuration.modules.module -Collections $collections
	$pythonpackages = Get-FPFilteredSet -ControlData $DataSet.configuration.pythonpackages.pythonpackage -Collections $collections
	$permissions    = Get-FPFilteredSet -ControlData $DataSet.configuration.permissions.permission -Collections $collections
	
	Write-FPLog "template version...: $($DataSet.configuration.version)"
	Write-FPLog "template comment...: $($DataSet.configuration.comment)"
	Write-FPLog "control version....: $($DataSet.configuration.control.version) ***"
	Write-FPLog "control enabled....: $($DataSet.configuration.control.enabled)"
	Write-FPLog "control comment....: $($DataSet.configuration.control.comment)"

	Set-FPConfiguration -Name "TemplateVersion" -Data $DataSet.configuration.version | Out-Null
	Set-FPConfiguration -Name "ControlVersion" -Data $DataSet.configuration.control.version | Out-Null

	if (!(Get-FPServiceAvailable -DataSet $DataSet)) { Write-FPLog 'FudgePop is not enabled'; break }
	
	Write-FPLog "priority list: $($priority -replace(',',' '))"
	
	$keys = $priority -split ','
	if (![string]::IsNullOrEmpty($ControlName)) {
		$keys = $keys | Where-Object { $_ -eq $ControlName }
	}
	foreach ($key in $keys) {
		switch ($key) {
			'folders' { 
				if ($folders) {
					Deploy-FPFolderControls -DataSet $folders
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Folders"
				}
				break
			}
			'files' { 
				if ($files) {
					Deploy-FPFileControls -DataSet $files
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Files"
				}
				break
			}
			'registry' {
				if ($registry) {
					Deploy-FPRegistryControls -DataSet $registry
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Registry"
				}
				break
			}
			'winget_installs' {
				if ($wingetinstalls) {
					Install-FPWingetPackages -DataSet $wingetinstalls
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Package Installs"
				}
				break
			}
			'choco_installs' {
				if ($chocoinstalls) {
					Install-FPChocolateyPackages -DataSet $chocoinstalls
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Package Installs"
				}
				break
			}
			'winget_removals' { 
				if ($wingetremovals) {
					Remove-FPWingetPackages -DataSet $wingetremovals
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Package Removals"
				}
				break
			}
			'choco_removals' { 
				if ($chocoremovals) {
					Remove-FPChocolateyPackages -DataSet $chocoremovals
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Package Removals"
				}
				break
			}
			'appxremovals' { 
				if ($appx) {
					Set-FPControlAppxRemovals -DataSet $appx
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: AppxRemovals"
				}
				break
			}
			'services' { 
				if ($services) {
					Set-FPControlServices -DataSet $services
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Services"
				}
				break
			}
			'shortcuts' { 
				if ($shortcuts) {
					Set-FPControlShortcuts -DataSet $shortcuts
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Shortcuts"
				}
				break
			}
			'opapps' { 
				if ($opapps) {
					Set-FPControlWin32Apps -DataSet $opapps
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Win32 Apps"
				}
				break
			}
			'permissions' { 
				if ($permissions) {
					Deploy-FPAccessControls -DataSet $permissions
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Permissions"
				}
				break
			}
			'updates' { 
				if ($updates) {
					Set-FPControlWindowsUpdate -DataSet $updates
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: WindowsUpdate"
				}
				break
			}
			'modules' { 
				if ($modules) {
					Set-FPControlModules -DataSet $modules
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: PowerShell Modules"
				}
				break
			}
			'python_packages' { 
				if ($pythonpackages) {
					Install-FPPythonPackages -DataSet $pythonpackages
				} else {
					Write-FPLog -Category 'Info' -Message "no assignments for group: Python Packages"
				}
				break
			}
			'upgrades' { 
				break
				# later / maybe
			}
			default { 
				Write-FPLog -Category 'Error' -Message "invalid priority key: $key"; break }
		} # switch
	} # foreach
	Write-FPLog -Category "Info" -Message $(Write-CenteredText -Caption "control processing: finish")
}