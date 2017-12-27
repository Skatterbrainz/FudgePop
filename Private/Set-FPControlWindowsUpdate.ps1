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
        $device     = $dvc.device
        $collection = $dvc.collection
        $runtime    = $dvc.when
        Write-FPLog -Category "Info" -Message "device......: $device"
        Write-FPLog -Category "Info" -Message "collection..: $collection"
        Write-FPLog -Category "Info" -Message "runtime.....: $runtime"
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