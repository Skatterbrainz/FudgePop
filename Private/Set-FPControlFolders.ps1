function Set-FPControlFolders {
	<#
	.SYNOPSIS
		Create Folders
	.DESCRIPTION
		Process Configuration Control: Folders
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlFolders -DataSet $xmldata
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $True)]
		$DataSet
	)
	Write-FPLog "--------- folder assignments: begin ---------"
	foreach ($folder in $DataSet) {
		$deviceName = $folder.device
		$collection = $folder.collection
		$action     = $folder.action
		$enabled    = $folder.enabled
		$folderPath = $folder.path
		Write-FPLog "device name........... $deviceName"
		Write-FPLog "collection............ $collection"
		Write-FPLog "folder action......... $action"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		switch ($action) {
			'create' {
				Write-FPLog "folder path........... $folderPath"
				if (-not(Test-Path $folderPath)) {
					Write-FPLog "creating new folder"
					if (-not $TestMode) {
						mkdir -Path $folderPath -Force | Out-Null
					} else {
						Write-FPLog "TEST MODE: no changes are being applied"
					}
				} else {
					Write-FPLog "folder already exists"
				}
				break
			}
			'empty' {
				$filter = $folder.filter
				if ($filter -eq "") { $filter = "*.*" }
				Write-FPLog "deleting $filter from $folderPath and subfolders"
				if (-not $TestMode) {
					Get-ChildItem -Path "$folderPath" -Filter "$filter" -Recurse |
						ForEach-Object { Remove-Item -Path $_.FullName -Confirm:$False -Recurse -ErrorAction SilentlyContinue }
					Write-FPLog "some files may remain if they were in use"
				} else {
					Write-FPLog "TEST MODE: no changes are being applied"
				}
				break
			}
			'delete' {
				if (Test-Path $folderPath) {
					Write-FPLog "deleting $folderPath and subfolders"
					if (-not $TestMode) {
						try {
							Remove-Item -Path $folderPath -Recurse -Force | Out-Null
							Write-FPLog "folder may remain if files are still in use"
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "TEST MODE: no changes are being applied"
					}
				} else {
					Write-FPLog "$folderPath was not found"
				}
				break
			}
		} # switch
	} # foreach
	Write-FPLog "--------- folder assignments: finish ---------"
}