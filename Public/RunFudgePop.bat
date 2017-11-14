@echo off
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module C:\users\David\Documents\FudgePop\FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
