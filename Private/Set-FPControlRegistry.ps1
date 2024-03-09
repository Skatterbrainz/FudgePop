function Set-FPControlRegistry {
	<#
	.SYNOPSIS
		Process Configuration Control: Registry Settings
	.DESCRIPTION
		Process Configuration Control: Registry Settings
	.PARAMETER DataSet
		XML data from control file import
	.EXAMPLE
		Set-FPControlRegistry -DataSet $xmldata
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $True)]$DataSet
	)
	Write-FPLog "--------- registry assignments: begin ---------"
	foreach ($reg in $DataSet) {
		$deviceName = $reg.device
		$collection = $reg.collection
		$regAction  = $reg.action
		$regpath    = $reg.path
		$regval     = $reg.value
		$regdata    = $reg.data
		$regtype    = $reg.type
		Write-FPLog "device name........... $deviceName"
		Write-FPLog "collection............ $collection"
		Write-FPLog "keypath............... $regpath"
		Write-FPLog "action................ $regAction"
		switch ($regAction) {
			'create' {
				if ($regdata -eq '$controlversion') { $regdata = $controlversion }
				if ($regdata -eq '$(Get-Date)') { $regdata = Get-Date }
				Write-FPLog "device................ $scDevice"
				Write-FPLog "value................. $regval"
				Write-FPLog "data.................. $regdata"
				Write-FPLog "type.................. $regtype"
				if (-not(Test-Path $regpath)) {
					Write-FPLog "key not found, creating registry key"
					if (-not $TestMode) {
						New-Item -Path $regpath -Force | Out-Null
						Write-FPLog "updating value assignment to $regdata"
						New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
					} else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				} else {
					Write-FPLog "key already exists"
					if (-not $TestMode) {
						try {
							$cv = Get-ItemProperty -Path $regpath -Name $regval -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regval
						} catch {
							Write-FPLog "$regval not found"
							$cv = ""
						}
						Write-FPLog "current value of $regval is $cv"
						if ($cv -ne $regdata) {
							Write-FPLog "updating value assignment to $regdata"
							New-ItemProperty -Path $regpath -Name $regval -Value "$regdata" -PropertyType $regtype -Force | Out-Null
						}
					} else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				}
				break
			}
			'delete' {
				if (Test-Path $regPath) {
					if (-not $TestMode) {
						try {
							Remove-Item -Path $regPath -Recurse -Force | Out-Null
							Write-FPLog "registry key deleted"
						} catch {
							Write-FPLog -Category "Error" -Message $_.Exception.Message
						}
					} else {
						Write-FPLog "TESTMODE: Would have been applied"
					}
				} else {
					Write-FPLog "registry key not found: $regPath"
				}
				break
			}
		} # switch
	} # foreach
	Write-FPLog "--------- registry assignments: finish ---------"
}