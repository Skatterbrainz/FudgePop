#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Run Chocolatey package assignments and general device config ops using XML config file

.PARAMETER ControlFile
	[optional][string] Path or URI to appcontrol.xml file
	default: https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/FudgePop/control.xml
	
.PARAMETER LogFile
	[optional][string] Path to output log file
	default: $env:TEMP\fudgepop.log unless the [control] section of the XML file overrides it (it does)
	
.PARAMETER TestMode
	[optional][switch] WhatIf mode - no installs or removals executed

.PARAMETER Payload
	[optional] [string] One of 'All', 'Files', 'Folders', 'Registry', 'Installs', 'Removals','Services','Shortcuts','OpApps','Permissions'
	default is 'All'
	
.NOTES
	1.0.0 - 10/30/2017 - David Stein
	
.EXAMPLE
	Invoke-FudgePop -Verbose

.EXAMPLE
	Invoke-FudgePop -ControlFile "\\server\share\control.xml"

.EXAMPLE	
	Invoke-FudgePop -TestMode -Payload 'Registry' -Verbose

.EXAMPLE
	Invoke-FudgePop -Configure
#>
function Invoke-FudgePop {
	param (
		[parameter(Mandatory=$False, HelpMessage="Path or URI to XML control file")]
			[ValidateNotNullOrEmpty()]
			[string] $ControlFile = 'https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/FudgePop/control.xml',
		[parameter(Mandatory=$False, HelpMessage="Path to output log file")]
			[ValidateNotNullOrEmpty()]
			[string] $LogFile = "$($env:TEMP)\fudgepop.log",
		[parameter(Mandatory=$False, HelpMessage="Run in testing mode")]
			[switch] $TestMode,
		[parameter(Mandatory=$False, HelpMessage="Specify configuration task group to invoke from XML control file")]
			[ValidateSet('All','Installs','Removals','Folders','Files','Registry','Services','Shortcuts','OpApps','Permissions')]
			[string] $Payload = 'All',
		[parameter(Mandatory=$False, HelpMessage="Configure options")]
			[switch] $Configure
	)
	Start-Transcript -OutputDirectory $env:TEMP
	Write-Verbose "script version: 1.0.0"
	$error.Clear()
	if ($Configure) {
		Set-FPConfiguration
	}
	else {
		Assert-Chocolatey
		$controlData = Get-FPControlData -FilePath $ControlFile
		if ($controldata) { 
			$controlversion = $controldata.configuration.control.version
			Write-FudgePopLog -Category "Info" -Message "control file version: $controlversion"
			if ($controldata.configuration.control.enabled -ne 'true') {
				Write-FudgePopLog -Category "Info" -Message "control file is currently DISABLED"
			}
			elseif (($controldata.configuration.control.exclude -split ',') -contains $env:COMPUTERNAME) {
				Write-FudgePopLog -Category "Info" -Message "control file is currently DISABLED for this computer"
			}
			else {
				Invoke-FPTasks -DataSet $controlData 
			}
		}
		else {
			Write-FudgePopLog -Category "Error" -Message "no data was returned from xml request"
		}
	}
	Write-FudgePopLog -Category "Info" -Message "---- processing cycle finished ----"
	try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
	if ($error.Count -eq 0) { Write-Output 0 } else { Write-Output -1 }
}
Export-ModuleMember -Function Invoke-FudgePop
