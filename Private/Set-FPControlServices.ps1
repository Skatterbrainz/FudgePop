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
    Write-FPLog "--------- services assignments: begin ---------"
    foreach ($service in $DataSet) {
        $deviceName = $service.device
        $collection = $service.collection
        $svcName    = $service.name
        $svcConfig  = $service.config
        $svcAction  = $service.action
        Write-FPLog "device name........... $deviceName"
        Write-FPLog "collection............ $collection"
        Write-FPLog "service name.......... $svcName"
        Write-FPLog "action................ $svcAction"
        Write-FPLog "config type........... $svcConfig"
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
                                    Write-FPLog "current startup type is: $sst"
                                    Write-FPLog "setting service startup to: $cfgData"
                                    if (-not $TestMode) {
                                        Set-Service -Name $svcName -StartupType $cfgData | Out-Null
                                    }
                                    else {
                                        Write-FPLog "TEST MODE: $cfgName -> $cfgData"
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
                            Write-FPLog "TEST MODE"
                        }
                    }
                    else {
                        Write-FPLog "service is already running"
                    }
                    break
                }
                'restart' {
                    Write-FPLog "restarting service..."
                    if (-not $TestMode) {
                        Restart-Service -Name $svcName -ErrorAction SilentlyContinue
                    }
                    else {
                        Write-FPLog "TEST MODE"
                    }
                    break
                }
                'stop' {
                    Write-FPLog "stopping service..."
                    if (-not $TestMode) {
                        Stop-Service -Name $svcName -Force -NoWait -ErrorAction SilentlyContinue
                    }
                    else {
                        Write-FPLog "TEST MODE"
                    }
                    break
                }
            } # switch
        }
        catch {
            Write-FPLog -Category "Error" -Message "service not found: $svcName"
        }
    } # foreach
    Write-FPLog "--------- services assignments: finish ---------"
}
