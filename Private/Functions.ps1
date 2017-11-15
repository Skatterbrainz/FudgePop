<#
.SYNOPSIS
	Private functions for running FudgePop
.DESCRIPTION
	Private functions for FudgePop module
.NOTES
	1.0.10 - 11/15/2017 - David Stein
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
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [parameter(Mandatory = $False)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string] $Category = 'Info'
    )
    Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
    "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | Out-File $Script:FPLogFile -Encoding Default -Append
}

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
    param ()
    Write-FPLog -Category Info -Message "verifying chocolatey is installed"
    if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
        Write-FPLog -Category Info -Message "installing chocolatey..."
        try {
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        catch {
            Write-FPLog -Category Error -Message $_.Exception.Message
        }
    }
    else {
        Write-FPLog -Category Info -Message "chocolatey is already installed"
    }
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
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string] $RegPath = $FPRegRoot,
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,
        [parameter(Mandatory = $False)]
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
        [parameter(Mandatory = $True)]
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

function Get-FPControlData {
    <#
.SYNOPSIS
	Import XML data from Control File
.DESCRIPTION
	Import XML data from Control File
.PARAMETER FilePath
	Full path or URI to XML file
#>
    param (
        [parameter(Mandatory = $True, HelpMessage = "Path or URI to XML control file")]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath
    )
    Write-FPLog "preparing to import control file: $FilePath"
    if ($FilePath.StartsWith("http")) {
        try {
            #[xml]$result = Invoke-RestMethod -Uri "$FilePath" -UseBasicParsing
            [xml]$result = ((New-Object System.Net.WebClient).DownloadString($FilePath))
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

function Get-FPFilteredSet {
    <#
.SYNOPSIS
	Return Filtered Control Data
.DESCRIPTION
	Return child nodes where device=(_this-computer_) or device="all"
.PARAMETER XmlData
	XML data from control file import
.EXAMPLE
	Node: /configuration/files/file
		<file device="all" enabled="true" source="" target=""...>
	Would return this node since device='all'
.INPUTS
	XML data object
.OUTPUTS
	XML data
#>
    param (
        [parameter(Mandatory = $True)]
        $XmlData
    )
    $collections = ($XmlData.configuration.collections.collection | Where-Object {$_.members -match $env:COMPUTERNAME}).name
    $result = $XmlData | 
        Where-Object { $_.enabled -eq 'true' -and (($_.device -eq $env:COMPUTERNAME -or $_.device -eq 'all') -or ($collections.Contains($_.collection))) }
    Write-Output $result
}

function Get-FPServiceAvailable {
    <#
.SYNOPSIS
	Verify FudgePop Control Item is Enabled
.DESCRIPTION
	Return TRUE if enabled="true" in control section of XML
.PARAMETER DataSet
	XML data from control file import
.INPUTS
	XML data
.OUTPUTS
	$True or $null
#>
    param (
        [parameter(Mandatory = $True)]
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
        [parameter(Mandatory = $True)]
        $DataSet,
        [parameter(Mandatory = $True)]
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
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $RunTime,
        [parameter(Mandatory = $False)]
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

function Assert-Chocolatey {
    <#
.SYNOPSIS
	Install Chocolatey
.DESCRIPTION
	Process Configuration Control: Install or Upgrade Chocolatey
.EXAMPLE
	Assert-Chocolatey
#>
    param ()
    Write-FPLog "verifying chocolatey installation"
    if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
        try {
            Write-FPLog "installing chocolatey"
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
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

function Set-FPControlFiles {
    <#
.SYNOPSIS
	Create and Manipulate Files
.DESCRIPTION
	Process Configuration Control: Files
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlFiles -DataSet $xmldata
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
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
                            <#
                            $WebClient = New-Object System.Net.WebClient
                            $WebClient.DownloadFile($fileSource, $fileTarget) | Out-Null
                            #>
                            Import-Module BitsTransfer
                            Start-BitsTransfer -Source $fileSource -Destination $fileTarget
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


function Set-FPControlFolders {
    <#
.SYNOPSIS
	Create Folders
.DESCRIPTION
	Process Configuration Control: Folders
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlFolders -DataSet $xmldata
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- folder assignments: begin ---------"
    foreach ($folder in $DataSet) {
        $folderPath = $folder.path
        $deviceName = $folder.device
        $action     = $folder.action
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

function Set-FPControlServices {
    <#
.SYNOPSIS
	Process Control Changes on Services
.DESCRIPTION
	Process Configuration Control: Windows Services
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlServices -DataSet $xmldata
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
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
                    $sst = $scfg.StartType
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

function Set-FPControlShortcuts {
    <#
.SYNOPSIS
	Process Shortcut Controls
.DESCRIPTION
	Process Configuration Control: File and URL Shortcuts
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlShortcuts -DataSet $xmldata
#>
    param (
        [parameter(Mandatory = $True)]
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
                            'normal' {$scWin = 1; break; }
                            'max' {$scWin = 3; break; }
                            'min' {$scWin = 7; break; }
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
                                    $shortcut.WindowStyle = $scWin
                                    $shortcut.Description = $scName
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

function Set-FPControlPermissions {
    <#
.SYNOPSIS
	Apply Folder and File Permissions Controls
.DESCRIPTION
	Process Configuration Control: ACL Permissions on Files, Folders
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlPermissions -DataSet $xmldata
#>
    param (
        [parameter(Mandatory = $True)]
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
                        'full' {$pset = '(OI)(CI)(F)'; break}
                        'modify' {$pset = '(OI)(CI)(M)'; break}
                        'read' {$pset = '(OI)(CI)(R)'; break}
                        'write' {$pset = '(OI)(CI)(W)'; break}
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

function Set-FPControlPackages {
    <#
.SYNOPSIS
	Install Chocolatey Packages
.DESCRIPTION
	Process Configuration Control: Chocolatey Package Installs and Upgrades
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlPackages -DataSet $xmldata
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
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
        Write-FPLog -Category "Info" -Message "device......: $deviceName"
        Write-FPLog -Category "Info" -Message "user........: $username"
        Write-FPLog -Category "Info" -Message "runtime.....: $runtime"
        Write-FPLog -Category "Info" -Message "autoupdate..: $autoupdate"
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
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- upgrade assignments: begin ---------"
    foreach ($upgrade in $DataSet) {
        # later / maybe
    }
    Write-FPLog -Category "Info" -Message "--------- upgrade assignments: finish ---------"
}

function Set-FPControlAppxRemovals {
    <#
.SYNOPSIS
	Remove Appx Packages
.DESCRIPTION
	Process Configuration Control: Chocolatey Package Removals
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlAppxRemovals -DataSet $xmldata
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- appx removal assignments: begin ---------"
    foreach ($appx in $DataSet) {
        $deviceName = $appx.device
        $runtime    = $appx.when
        $username   = $appx.user
        $appxcomm   = $appx.comment 
        Write-FPLog -Category "Info" -Message "device...: $deviceName"
        Write-FPLog -Category "Info" -Message "user.....: $username"
        Write-FPLog -Category "Info" -Message "runtime..: $runtime"
        Write-FPLog -Category "Info" -Message "comment..: $appxcomm"
        if (Test-FPControlRuntime -RunTime $runtime) {
            Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
            $pkglist = $appx.InnerText -split ','
            foreach ($pkg in $pkglist) {
                Write-FPLog "package...: $pkg"
                if (-not $TestMode) {
                    try {
                        Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object {$_.Name -match $pkg} | Remove-AppxPackage -AllUsers -Confirm:$False
                        Write-FPLog -Category "Info" -Message "successfully uninstalled: $pkg"
                    }
                    catch {
                        Write-FPLog -Category 'Error' -Message $_.Exception.Message
                        break
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
    Write-FPLog -Category "Info" -Message "--------- appx removal assignments: finish ---------"
}

function Set-FPControlRemovals {
    <#
.SYNOPSIS
	Uninstall Chocolatey Packages
.DESCRIPTION
	Uninstall Chocolatey Packages applicable to this computer
.PARAMETER DataSet
	XML data
.EXAMPLE
	Set-FPControlRemovals -DataSet $xmldata
.NOTES
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- removal assignments: begin ---------"
    foreach ($package in $DataSet) {
        $deviceName = $package.device
        $runtime    = $package.when
        $autoupdate = $package.autoupdate
        $username   = $package.user
        $extparams  = $package.params
        Write-FPLog -Category "Info" -Message "device......: $deviceName"
        Write-FPLog -Category "Info" -Message "user........: $username"
        Write-FPLog -Category "Info" -Message "autoupdate..: $autoupdate"
        Write-FPLog -Category "Info" -Message "runtime.....: $runtime"
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

function Set-FPControlRegistry {
    <#
.SYNOPSIS
	Process Configuration Control: Registry Settings
.DESCRIPTION
	Process Configuration Control: Registry Settings
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlRegistry -DataSet $xmldata
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $True)]
        $DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- registry assignments: begin ---------"
    foreach ($reg in $DataSet) {
        $regpath = $reg.path
        $regval  = $reg.value
        $regdata = $reg.data
        $regtype = $reg.type
        $deviceName = $reg.device
        $regAction = $reg.action
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
        [parameter(Mandatory = $True)]
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
		Write-FPLog -Category "Info" -Message "platform..: $appPlat"
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
                            if ((0, 3010) -contains $p.ExitCode) {
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
                        $args = ($appRun -replace ("msiexec", "")).trim()
                        Write-FPLog "proc......: $proc"
                        Write-FPLog "args......: $args"
                        if (-not $TestMode) {
                            try {
                                $p = Start-Process -FilePath $proc -ArgumentList $args -NoNewWindow -Wait -PassThru
                                if ((0, 3010, 1605) -contains $p.ExitCode) {
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

function Set-FPControlWindowsUpdate {
	<#
.SYNOPSIS
	Run Windows Update Scan and Install Cycle
.DESCRIPTION
	Process Configuration Control: Windows Updates
.PARAMETER DataSet
	XML data from control file import
.EXAMPLE
	Set-FPControlWindowsUpdate -DataSet $xmldata
#>
param (
        [parameter(Mandatory = $True)]
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
                    $Criteria     = "IsInstalled=0 and Type='Software'"
                    $Searcher     = New-Object -ComObject Microsoft.Update.Searcher
                    $SearchResult = $Searcher.Search($Criteria).Updates
                    $Session    = New-Object -ComObject Microsoft.Update.Session
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

function Set-FPControlModules {
    <#
    .SYNOPSIS
    Install PowerShell Modules
    
    .DESCRIPTION
    Install Specified PowerShell Modules
    
    .PARAMETER DataSet
    XML data
    
    .EXAMPLE
    Set-FPControlModules -DataSet $xmldata
    
    .NOTES
    
    #>
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [parameter(Mandatory = $True, HelpMessage="XML data")] 
		[ValidateNotNullOrEmpty()] 
		$DataSet
    )
    Write-FPLog -Category "Info" -Message "--------- module assignments: begin ---------"
    foreach ($module in $DataSet) {
        $device  = $module.device
        $modname = $module.name
        $modver  = $module.version
        $runtime = $module.when
        $comment = $module.comment
        Write-FPLog -Category "Info" -Message "device....: $device"
        Write-FPLog -Category "Info" -Message "module....: $modname"
        Write-FPLog -Category "Info" -Message "version...: $modver"
        Write-FPLog -Category "Info" -Message "runtime...: $runtime"
        Write-FPLog -Category "Info" -Message "comment...: $comment"
        if (Test-FPControlRuntime -RunTime $runtime) {
            Write-FPLog -Category 'Info' -Message "Runtime is now or overdue"
            if (Import-Module $modname -ErrorAction SilentlyContinue) {
                $lv = (Get-Module $modname).Version -join '.'
                Write-FPLog -Category 'Info' -Message "Module version $lv is already installed"
                if ($modver -eq 'latest') {
                    Write-FPLog -Category 'Info' -Message 'Latest version is requested via control policy.'
                    try {
                        $rv = (Find-Module $modname).Version -join '.'
                        if ($lv -lt $rv) {
                            Write-FPLog -Category 'Info' -Message "Latest version available is $rv / updating module"
                            if (!($TestMode)) {
                                Update-Module -Name $modname -Force
                            }
                            else {
                                Write-FPLog "TESTMODE: Would have been updated"
                            }
                        }
                        else {
                            Write-FPLog -Category 'Info' -Message "Local version is the latest. No update required."
                        }
                    }
                    catch {
                        Write-FPLog -Category 'Error' -Message $_.Exception.Message
                        break
                    }
                }
            }
            else {
                Write-FPLog -Category 'Info' -Message "Module is not installed. Install it now."
                try {
                    if (!($TestMode)) {
                        Install-Module -Name $modname -Force -ErrorAction Stop
                        Write-FPLog -Category 'Info' -Message "Module has been installed successfully."
                    }
                    else {
                        Write-FPLog "TESTMODE: Would have been installed"
                    }
                }
                catch {
                    Write-FPLog -Category 'Error' -Message "Installation failed: "+$_.Exception.Message
                }
            }
        }
        else {
            Write-FPLog -Category 'Info' -Message 'skip: not yet time to run this assignment'
        }
    } # foreach
    Write-FPLog -Category 'Info' -Message '--------- module assignments: finish ---------'
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
		$DataSet
    )
    Write-FPLog -Category "Info" -Message "********************* control processing: begin *********************"
    Write-FPLog "module version: $($Script:FPVersion)"
    $MyPC = $env:COMPUTERNAME
    $collections = ($DataSet.configuration.collections.collection | Where-Object {$_.members -match $MyPC}).name
    $priority    = $DataSet.configuration.priority.order
    $installs    = Get-FPFilteredSet -XmlData $DataSet.configuration.deployments.deployment
    $removals    = Get-FPFilteredSet -XmlData $DataSet.configuration.removals.removal
    $folders     = Get-FPFilteredSet -XmlData $DataSet.configuration.folders.folder
    $files       = Get-FPFilteredSet -XmlData $DataSet.configuration.files.file
    $registry    = Get-FPFilteredSet -XmlData $DataSet.configuration.registry.reg
    $services    = Get-FPFilteredSet -XmlData $DataSet.configuration.services.service
    $shortcuts   = Get-FPFilteredSet -XmlData $DataSet.configuration.shortcuts.shortcut
    $opapps      = Get-FPFilteredSet -XmlData $DataSet.configuration.opapps.opapp
    $updates     = Get-FPFilteredSet -XmlData $DataSet.configuration.updates.update
    $appx        = Get-FPFilteredSet -XmlData $DataSet.configuration.appxremovals.appxremoval
    $modules     = Get-FPFilteredSet -XmlData $DataSet.configuration.modules.module
    $permissions = Get-FPFilteredSet -XmlData $DataSet.configuration.permissions.permission
	
    Write-FPLog "template version...: $($DataSet.configuration.version)"
    Write-FPLog "template comment...: $($DataSet.configuration.comment)"
    Write-FPLog "control version....: $($DataSet.configuration.control.version) ***"
    Write-FPLog "control enabled....: $($DataSet.configuration.control.enabled)"
    Write-FPLog "control comment....: $($DataSet.configuration.control.comment)"
    Write-FPLog "device name........: $MyPC"
    Write-FPLog "collections........: $($collections -join ',')"
    
    Set-FPConfiguration -Name "TemplateVersion" -Data $DataSet.configuration.version | Out-Null
    Set-FPConfiguration -Name "ControlVersion" -Data $DataSet.configuration.control.version | Out-Null

    if (!(Get-FPServiceAvailable -DataSet $DataSet)) { Write-FPLog 'FudgePop is not enabled'; break }
	
    Write-FPLog "priority list: $($priority -replace(',',' '))"
	
    foreach ($key in $priority -split ',') {
        Write-FPLog "****************** $key **********************"
        switch ($key) {
            'folders'      { if ($folders)   {Set-FPControlFolders -DataSet $folders}; break }
            'files'        { if ($files)     {Set-FPControlFiles -DataSet $files}; break }
            'registry'     { if ($registry)  {Set-FPControlRegistry -DataSet $registry}; break }
            'deployments'  { if ($installs)  {Set-FPControlPackages -DataSet $installs}; break }
            'removals'     { if ($removals)  {Set-FPControlRemovals -DataSet $removals}; break }
            'appxremovals' { if ($appx)      {Set-FPControlAppxRemovals -DataSet $appx}; break }
            'services'     { if ($services)  {Set-FPControlServices -DataSet $services}; break }
            'shortcuts'    { if ($shortcuts) {Set-FPControlShortcuts -DataSet $shortcuts}; break }
            'opapps'       { if ($opapps)    {Set-FPControlWin32Apps -DataSet $opapps}; break }
            'permissions'  { if ($permissions) {Set-FPControlPermissions -DataSet $permissions}; break }
            'updates'      { if ($updates)   {Set-FPControlWindowsUpdate -DataSet $updates}; break }
            'modules'      { if ($modules)   {Set-FPControlModules -DataSet $modules}; break }
            default { Write-FPLog -Category 'Error' -Message "invalid priority key: $key"; break }
        } # switch
    } # foreach
    Write-FPLog -Category "Info" -Message "--------- control processing: finish ---------"
}
