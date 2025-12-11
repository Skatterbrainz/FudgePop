function Set-FPControlFiles {
	<#
	.SYNOPSIS
		Create and Manipulate Files
	.DESCRIPTION
		Process Configuration Control: Files
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlFiles -DataSet $xmldata
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $True)]
		$DataSet
	)
	Write-FPLog "--------- file assignments: begin ---------"
	foreach ($file in $DataSet) {
		$fileDevice = $file.device
		$collection = $file.collection
		$fileSource = $file.source
		$fileTarget = $file.target
		$action     = $file.action
		$enabled    = $file.enabled
		Write-FPLog "device................ $fileDevice"
		Write-FPLog "collection............ $collection"
		Write-FPLog "action................ $action"
		Write-FPLog "source................ $fileSource"
		Write-FPLog "target................ $fileTarget"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		if ($TestMode) {
			Write-FPLog  "TEST MODE: no changes will be applied"
		} else {
			switch ($action) {
				'download' {
					Write-FPLog "downloading file"
					if ($fileSource.StartsWith('http') -or $fileSource.StartsWith('ftp')) {
						try {
							Import-Module BitsTransfer
							Start-BitsTransfer -Source $fileSource -Destination $fileTarget
							if (Test-Path $fileTarget) {
								Write-FPLog "file downloaded successfully"
							} else {
								Write-FPLog -Category "Error" -Message "failed to download file!"
							}
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						try {
							Copy-Item -Source $fileSource -Destination $fileTarget -Force | Out-Null
							if (Test-Path $fileTarget) {
								Write-FPLog "file downloaded successfully"
							} else {
								Write-FPLog -Category "Error" -Message "failed to download file!"
							}
						} catch {
							Write-FPLog -Category "Error" -Message "failed to download file!"
						}
					}
					break
				}
				'rename' {
					Write-FPLog "renaming file"
					if (Test-Path $fileSource) {
						Rename-Item -Path $fileSource -NewName $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FPLog "file renamed successfully"
						} else {
							Write-FPLog -Category "Error" -Message "failed to rename file!"
						}
					} else {
						Write-FPLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'copy' {
					Write-FPLog "copying file"
					if (Test-Path $fileSource) {
						Copy-Item -Path $fileSource -Destination $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FPLog "file copied successfully"
						} else {
							Write-FPLog -Category "Error" -Message "failed to copy file!"
						}
					} else {
						Write-FPLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'move' {
					Write-FPLog "moving file"
					if (Test-Path $fileSource) {
						Move-Item -Path $fileSource -Destination $fileTarget -Force | Out-Null
						if (Test-Path $fileTarget) {
							Write-FPLog  "file moved successfully"
						} else {
							Write-FPLog -Category "Error" -Message "failed to move file!"
						}
					} else {
						Write-FPLog -Category "Warning" -Message "source file not found: $fileSource"
					}
					break
				}
				'delete' {
					Write-FPLog "deleting file"
					if (Test-Path $fileSource) {
						try {
							Remove-Item -Path $fileSource -Force | Out-Null
							if (-not(Test-Path $fileSource)) {
								Write-FPLog  "file deleted successfully"
							} else {
								Write-FPLog -Category "Error" -Message "failed to delete file!"
							}
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "source file not found: $fileSource"
					}
					break
				}
			} # switch
		}
	} # foreach
	Write-FPLog "--------- file assignments: finish ---------"
}
