function Set-FPControlPermissions {
	<#
	.SYNOPSIS
		Apply Folder and File Permissions Controls
	.DESCRIPTION
		Process Configuration Control: ACL Permissions on Files, Folders
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlPermissions -DataSet $xmldata
	#>
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- permissions assignments: begin ---------"
	foreach ($priv in $DataSet) {
		$device     = $priv.device
		$collection = $priv.collection
		$privPath   = $priv.path
		$privPrinc  = $priv.principals
		$privRights = $priv.rights
		$enabled    = $priv.enabled
		if ($privPath.StartsWith('HK')) {
			$privType = 'registry'
		} else {
			$privType = 'filesystem'
		}
		Write-FPLog "device................ $device"
		Write-FPLog "collection............ $collection"
		Write-FPLog "priv path............. $privPath"
		Write-FPLog "priv principals....... $privPrinc"
		Write-FPLog "priv rights........... $privRights"
		if (-not $enabled) {
			Write-FPLog "skip: assignment is disabled"
			continue
		}
		if (Test-Path $privPath) {
			switch ($privType) {
				'filesystem' {
					switch ($privRights) {
						'full'   { $pset = '(OI)(CI)(F)'; break }
						'modify' { $pset = '(OI)(CI)(M)'; break }
						'read'   { $pset = '(OI)(CI)(R)'; break }
						'write'  { $pset = '(OI)(CI)(W)'; break }
						'delete' { $pset = '(OI)(CI)(D)'; break }
						'readexecute' { $pset = '(OI)(CI)(RX)'; break }
					} # switch
					Write-FPLog "permission set........ $pset"
					if (-not $TestMode) {
						Write-FPlog "command: icacls `"$privPath`" /grant `"$privPrinc`:$pset`" /T /C /Q"
						try {
							icacls "$privPath" /grant "$privPrinc`:$pset" /T /C /Q
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "TESTMODE: icacls `"$privPath`" /grant `"$privPrinc`:$pset`" /T /C /Q"
					}
					break
				}
				'registry' {
					Write-FPLog "registry permissions feature is not yet fully baked"
					break
				}
			} # switch
		} else {
			Write-FPLog -Category "Error" -Message ""
		}
	} # switch
	Write-FPLog "--------- permissions assignments: finish ---------"
}