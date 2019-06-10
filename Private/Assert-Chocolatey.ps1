function Assert-Chocolatey {
    [CmdletBinding(SupportsShouldProcess)]
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
