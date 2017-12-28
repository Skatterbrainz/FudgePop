function Get-FPFilteredSet {
    <#
    .SYNOPSIS
    Return Targeted XML data set
    .DESCRIPTION
    Return Targeted XML data set for this device or associated collection
    .PARAMETER XmlData
    XML data set for specific control group (e.g. files, folders, etc.)
    .PARAMETER Collections
    Array of collection names
    .EXAMPLE
    $dataset = Get-FPFilteredSet -XmlData $ControlData.configuration.files.file -Collections (Get-FPDeviceCollections -XmlData $ControlData)
    .NOTES
    #>
    param (
        [parameter(Mandatory = $True)]
        $XmlData,
        [parameter(Mandatory = $False)]
        $Collections
    )
    $thisDevice  = $env:COMPUTERNAME
    if ($Collections -ne $null) {
        $result = $XmlData |
            Where-Object {$_.enabled -eq 'true' -and ($Collections.Contains($_.collection)) }
    }
    else {
        $result = $XmlData | 
            Where-Object {$_.enabled -eq 'true' -and ($_.device -eq 'all' -or $_.device -eq $thisDevice)}
    }
    Write-Output $result
}