$Script:FPVersion   = '1.0.7'
$Script:FPRegRoot   = 'HKLM:\SOFTWARE\FudgePop'
$Script:FPRunJob    = 'FudgePop Agent'
$Script:FPCFDefault = 'https://raw.githubusercontent.com/Skatterbrainz/FudgePop/master/control.xml'
$Script:FPLogFile   = "c:\windows\temp\fudgepop.log"

$(Get-ChildItem "$PSScriptRoot" -Recurse -Include "*.ps1").foreach{. $_.FullName}
