$Script:FPVersion   = '1.0.10'
$Script:FPRegRoot   = 'HKLM:\SOFTWARE\FudgePop'
$Script:FPRunJob    = 'FudgePop Agent'
$Script:FPCFDefault = 'https://github.com/Skatterbrainz/FudgePop/blob/master/assets/control1.xml'
$Script:FPLogFile   = "c:\windows\temp\fudgepop.log"
$(Get-ChildItem "$PSScriptRoot" -Recurse -Include "*.ps1").foreach{. $_.FullName}