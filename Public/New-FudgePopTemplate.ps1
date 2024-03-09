#requires -version 3
function New-FudgePopTemplate {
	<#
	.SYNOPSIS
		Clone an XML template for custom needs
	.DESCRIPTION
		Clones the default XML template for use in creating a custom control file.
	.PARAMETER Source
		Path to source cmbuild xml template.
	.PARAMETER OutputFile
		Path to save the cloned template file.
	.PARAMETER NoScrub
		Copy templates without clearing settings
	.EXAMPLE
		Clone-FudgePopTemplate -OutputFile 'c:\templates\custom.xml'
	.EXAMPLE
		Clone-FudgePopTemplate -OutputFile 'c:\templates\custom.xml' -Overwrite
	#>
	param (
		[parameter(Mandatory=$True, HelpMessage="Path and Name for new template control file")]
			[ValidateNotNullOrEmpty()]
			[string] $OutputFile,
		[parameter(Mandatory=$False, HelpMessage="Overwrite existing destination file if it exists")]
			[switch] $Overwrite
	)
	if (!($OutputFile.EndsWith('.xml'))) {
		Write-Warning "$OutputFile requires an .xml extension"
		break
	}
	if (Test-Path -Path $OutputFile) {
		if (!$Overwrite) {
			Write-Warning "$OutputFile exists!  Use -Overwrite to replace or provide a new destination path or name."
			break
		}
	}
	$ModuleData = Get-Module FudgePop
	$ModuleVer  = $ModuleData.Version -join '.'
	$ModulePath = $ModuleData.Path -replace 'FudgePop.psm1', ''
	$SourceFile = "$ModulePath\assets\control1.xml"
	Write-FPLog "module version... $ModuleVer"
	Write-FPLog "sourcefile....... $SourceFile"
	Write-FPLog "outputfile....... $OutputFile"
	try {
		$null = Copy-Item -Path $SourceFile -Destination $OutputFile -Force
		if (Test-Path $OutputFile) {
			Write-Host "$OutputFile created successfully" -ForegroundColor Green
		} else {
			Write-Host "Failed to copy $OutputFile / Verify folder permissions" -ForegroundColor Red
		}
	} catch {
		Write-FPLog -Category "Error" -Message "Failed to copy file.  Verify folder permissions"
		Write-Error $_.Exception.Message
	}
}
