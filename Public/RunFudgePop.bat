@echo off
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
