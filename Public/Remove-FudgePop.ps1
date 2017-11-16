#requires -RunAsAdministrator
#requires -version 3

function Remove-FudgePop {
    <#
.SYNOPSIS
	Removes FudgePop Configuration
.DESCRIPTION
	Removes FudgePop configuration items from the local computer,
	and the Scheduled Task as well.  Does not remove the module itself.
.EXAMPLE
    Remove-FudgePop
.EXAMPLE
    Remove-FudgePop -Complete
.NOTES
	1.0.10 - 11/15/2017 - David Stein
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory=$False, HelpMessage="Force complete removal of FudgePop")]
        [switch] $Complete
    )
    Write-Host "FudgePop $FPVersion - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
    try {
        Get-ScheduledTask -TaskName "$FPRunJob" -ErrorAction SilentlyContinue |	
            Unregister-ScheduledTask -Confirm:$False -ErrorAction Stop
    }
    catch {
        Write-FPLog -Category 'Error' -Message $_.Exception.Message
        Write-Host 'FudgePop scheduled task could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
        break
    }
    if (Test-Path $FPRegRoot) {
        try {
            Remove-Item -Path $FPRegRoot -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-FPLog -Category 'Error' -Message $_.Exception.Message
            Write-Host 'FudgePop registry items could not be removed from this computer.  Refer to log file for details.' -ForegroundColor Red
            break
        }
    }
    Write-FPLog 'FudgePop has been disabled on this computer'
    Write-Host 'FudgePop has been disabled on this computer' -ForegroundColor Green
    if ($Complete) {
        Uninstall-Module FudgePop -AllVersions -Force
    }
}

Export-ModuleMember -Function Remove-FudgePop