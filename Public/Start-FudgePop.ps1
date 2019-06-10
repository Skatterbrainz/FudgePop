#requires -version 3
#requires -RunAsAdministrator

function Start-FudgePop {
    <#
    .SYNOPSIS
        Run a FudgePop Process
    .DESCRIPTION
        Runs a FudgePop client process. If Install-FudgePop has not yet been
        executed, you will be prompted to do that first, in order to configure the
        options required to support FudgePop.  Otherwise, it will import the control
        XML file and process the instructions it provides.
    .PARAMETER TestMode
        Force WhatIf and Verbose output
    .EXAMPLE
        Start-FudgePop
    .EXAMPLE
        Start-FudgePop -TestMode
    .EXAMPLE
        Start-FudgePop -Verbose
    .NOTES
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [parameter(Mandatory = $False, HelpMessage = "Run in Test Mode only")]
        [switch] $TestMode
    )
    $ModuleData = Get-Module FudgePop
    $ModuleVer = $ModuleData.Version -join '.'

    Write-Host "FudgePop $ModuleVer - https://github.com/Skatterbrainz/FudgePop" -ForegroundColor Cyan
    Write-FPLog 'Checking for newer module version'
    try {
        Update-Module -Name FudgePop -Confirm:$False
    }
    catch {
        Write-Warning "Unable to update FudgePop PowerShell module. May require manual update."
        Write-Error $_.Exception.Message
        break
    }
    $ControlFile = Get-FPConfiguration -Name "ControlFile" -Default ""
    if ($ControlFile -eq "") {
        Write-FPLog -Category 'Warning' -Message 'FudgePop has not been configured yet. Run Install-FudgePop to set default options.'
        Write-Warning 'FudgePop has not been configured yet. Run Install-FudgePop to set default options.'
        break
    }
    else {
        $ControlData = Get-FPControlData -FilePath $ControlFile
        if (Get-FPServiceAvailable -DataSet $ControlData) {
            Write-Verbose "FudgePop is active."
            Set-FPConfiguration -Name "LastStartTime" -Data (Get-Date) | Out-Null
            if ($TestMode) {
                Set-FPConfiguration -Name "LastRunMode" -Data 'TestMode' | Out-Null
            }
            else {
                Set-FPConfiguration -Name "LastRunMode" -Data 'Live' | Out-Null
            }
            Invoke-FPControls -DataSet $ControlData
            Set-FPConfiguration -Name "LastFinishTime" -Data (Get-Date) | Out-Null
            Set-FPConfiguration -Name "LastRunUser" -Data $env:USERNAME | Out-Null
        }
        else {
            Write-FPLog "FudgePop is not currently active."
        }
    }
}

Export-ModuleMember -Function Start-FudgePop