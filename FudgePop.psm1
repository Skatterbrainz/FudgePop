$Script:FPRegRoot   = 'HKLM:\SOFTWARE\FudgePop'
$Script:FPRunJob    = 'FudgePop Agent'
$Script:FPCFDefault = 'https://raw.githubusercontent.com/Skatterbrainz/FudgePop/master/assets/control1.xml'
$Script:FPLogFile   = "c:\windows\temp\fudgepop.log"

# if (-not(Test-Path "c:\windows")) {
# 	Write-Warning "This module is only supported on Windows"
# } else {
	('Private','Public') | Foreach-Object {
		Get-ChildItem -Path $(Join-Path -Path $PSScriptRoot -ChildPath $_) -Filter "*.ps1" | Foreach-Object { . $_.FullName }
	}
#}