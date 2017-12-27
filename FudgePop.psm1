$Script:FPRegRoot   = 'HKLM:\SOFTWARE\FudgePop'
$Script:FPRunJob    = 'FudgePop Agent'
$Script:FPCFDefault = 'https://raw.githubusercontent.com/Skatterbrainz/FudgePop/master/assets/control1.xml'
$Script:FPLogFile   = "c:\windows\temp\fudgepop.log"

Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private'),(Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
