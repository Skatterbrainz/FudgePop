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
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        catch {
            Write-FPLog -Category Error -Message $_.Exception.Message
        }
    }
    else {
        Write-FPLog -Category Info -Message "chocolatey is already installed"
    }
}