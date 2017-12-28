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
