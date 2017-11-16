#requires -version 3
#requires -RunAsAdministrator

function Get-FudgePopInventory {
    <#
.SYNOPSIS
	Create HTML inventory report of computer
.DESCRIPTION
	Create an HTML inventory report of hardware, software and operating system
	for the local computer, or a remote computer.
.PARAMETER ComputerName
	Name of one or more computers to query.  A separate
	report file is generated for each computer.  Default value is local computer.
.PARAMETER FilePath
	Path and filename for the inventory report.
    If not specified, the default is $env:TEMP\computername_inventory.htm
.PARAMETER StyleSheet
    Path and filename for CSS stylesheet template.
    Default uses an internal "default.css" within the module structure
.EXAMPLE
	Get-FudgePopInventory -Computer WS01,WS02 -FilePath "c:\users\dave\documents"
.NOTES
	1.0.10 - 11/15/2017 - David Stein
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $False, HelpMessage = "Name of computer or computers")]
        [string[]] $ComputerName = "",
        [parameter(Mandatory = $False, HelpMessage = "Path for storing report files")]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath = "$($env:USERPROFILE)\Documents",
        [parameter(Mandatory=$False, HelpMessage="Path for custom CSS stylesheet")]
        [string] $StyleSheet = ""
    )
    Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
    $classes = [ordered]@{
        ComputerSystem  = ('Name', 'Manufacturer', 'Model', 'Domain', 'Description', 'TotalPhysicalMemory')
        OperatingSystem = ('Caption', 'CSDVersion', 'InstallDate', 'OSArchitecture', 'Organization')
        SystemEnclosure = ('SerialNumber', 'SMBIOSAssetTag')
        BIOS            = ('BuildNumber', 'Manufacturer', 'Name', 'SystemBiosMajorVersion', 'SystemBiosMinorVersion')
        Processor       = ('Manufacturer', 'Name', 'NumberOfCores', 'MaxClockSpeed')
        PhysicalMemory  = ('BankLabel', 'Capacity', 'DataWidth', 'Description', 'DeviceLocator', 'FormFactor', 'Manufacturer', 'MemoryType')
        LogicalDisk     = ('Name', 'DeviceID', 'FileSystem', 'VolumeName', 'VolumeSerialNumber', 'MediaType', 'Size', 'FreeSpace')
		Product         = ('Vendor', 'Name', 'Version', 'PackageName', 'InstallDate2', 'InstallSource')
    }
    $totalnum = $classes.Count
	if ($StyleSheet -eq "") {
        $ModulePath = $((Get-Module FudgePop).Path -replace ('FudgePop.psm1',''))
        $StyleSheet = "$ModulePath\assets\default.css"
    }
    foreach ($computer in $ComputerName) {
        if ($computer -eq "" -or $computer -eq $env:COMPUTERNAME) {
            $cname = $env:COMPUTERNAME
            $isLocal = $True
        }
        else {
            $cname = $computer
            $isLocal = $False
        }
		
        $fullpath = $FilePath + "\$cname`_inventory.htm"
        $html = "<h1>$cname</h1>`n"
	
        Write-Host "computer: $cname" -ForegroundColor Cyan
        if (!$isLocal) {
            Write-Verbose "$cname is remote"
            if (!(Test-Connection $cname -Count 1 -ErrorAction SilentlyContinue)) {
                Write-Warning "$cname is offline or not accessible"
                break
            }
        }
        $current = 1
        foreach ($className in $classes.keys) {
            $proplist = $classes.Item($className)
            $query = "SELECT $($proplist -join ',') FROM Win32_$className"
            Write-Verbose "query: $query"
            Write-Progress -Activity "Gathering Inventory: $cname" -Status "Querying: $className" -PercentComplete ($current / $totalnum * 100)
            if (!$isLocal) {
                Write-Verbose "remote computer: $cname"
                try {
                    $inv += Get-WmiObject -Query $query -ComputerName $cname -ErrorAction Stop | Select $proplist | ConvertTo-Html -Fragment
                }
                catch {
                    if ($_.Exception.Message -match 'access denied') {
                        Write-Warning "$cname is not accessible"
                    }
                    else {
                        Write-Error $_.Exception.Message
                    }
                    $inv = ""
                    break
                }
                $section = '<h2>' + $className + '</h2>' + "`n" + $inv + "`n"
            }
            else {
                Write-Verbose "local computer: $cname"
                try {
                    $inv += Get-WmiObject -Query $query -ErrorAction Stop | Select $proplist | ConvertTo-Html -Fragment
                }
                catch {
                    if ($_.Exception.Message -match 'access is denied') {
                        Write-Warning "$cname is not accessible"
                    }
                    else {
                        Write-Error $_.Exception.Message
                    }
                    $inv = ""
                    break
                }
                $section = '<h2>' + $className + '</h2>' + "`n" + $inv + "`n"
            }
            $html += $section
            $inv = ""
            $section = ""
            $current++
        } # foreach
        $html += "`n<p class=`"footer`">Generated by FudgePop - https://github.com/skatterbrainz/FudgePop - $(Get-Date)</p>"
        $html | ConvertTo-Html -CssUri $StyleSheet -Body $html -Title $cname | Out-File $fullpath
        Write-Host "file: $fullpath" -ForegroundColor Cyan
    }
}
Export-ModuleMember -Function Get-FudgePopInventory