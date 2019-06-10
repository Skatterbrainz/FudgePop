@echo off
rem RunFudgePop.bat
rem Version 1.0.17 - 06/03/2019
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
